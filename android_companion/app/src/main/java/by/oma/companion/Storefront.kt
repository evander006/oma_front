package by.oma.companion

import android.app.Activity
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.widget.*
import android.database.sqlite.SQLiteDatabase
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.net.URL
import java.text.NumberFormat
import java.util.Locale
import java.util.concurrent.Executors
import java.util.zip.ZipInputStream

/**
 * Demo storefront based on the supplied OMA screenshots and catalog export.
 * No access to official OMA user accounts, checkout or live inventory.
 * Works with built-in sample products; importing the user-supplied output.zip
 * activates the full 3,491-row offline SQLite catalog and local product images.
 */
class Storefront(
    private val activity: Activity,
    private val navigate: (String) -> Unit,
    private val changeTab: (String) -> Unit,
    private val refresh: () -> Unit
) {
    companion object {
        const val PICK_CATALOG = 7241
        private val blue = Color.rgb(0, 99, 174)
        private val ink = Color.rgb(46, 63, 78)
        private val orange = Color.rgb(246, 154, 37)
        private val soft = Color.rgb(249, 249, 249)
        private val line = Color.rgb(229, 231, 232)
        private val pool = Executors.newFixedThreadPool(4)
        private val ui = Handler(Looper.getMainLooper())
        private val imageCache = object : android.util.LruCache<String, Bitmap>(24 * 1024) {
            override fun sizeOf(key: String, value: Bitmap) = value.byteCount / 1024
        }
    }

    private val prefs: SharedPreferences =
        activity.getSharedPreferences("oma_store_offline", Activity.MODE_PRIVATE)
    private var products: List<Item> = demoProducts()
    private var selectedCategory = "Инструмент"
    private var selectedSubcategory = ""
    private var currentProduct = ""
    private var searchQuery = ""
    private var sorting = "Популярные"
    private var pageSize = 20
    private var showParameters = false
    private val rootCategories = listOf(
        "Акции", "Интерьер и отделка", "Благоустройство", "Стройматериалы",
        "Инструмент", "Мебель", "Бытовая техника", "Товары для дома",
        "Сантехника", "Электрика", "Инженерные системы", "Спорт и отдых",
        "Новый год", "Крепёж", "Автотовары", "Электроника",
        "Товары для детей", "Красота и здоровье"
    )

    data class Item(
        val id: String, val title: String, val category: String, val subcategory: String,
        val price: Double?, val oldPrice: Double?, val unit: String,
        val image: String, val brand: String = ""
    )
    private fun dp(n: Int) = Style.dp(activity, n)
    private fun text(s: String, size: Float = 15f, bold: Boolean = false, color: Int = ink): TextView =
        TextView(activity).apply {
            this.text = s
            textSize = size
            setTextColor(color)
            gravity = Gravity.CENTER_VERTICAL
            if (bold) setTypeface(null, Typeface.BOLD)
        }
    private fun vertical() = LinearLayout(activity).apply { orientation = LinearLayout.VERTICAL }
    private fun horizontal() = LinearLayout(activity).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
    }
    private fun space(parent: LinearLayout, n: Int) {
        parent.addView(View(activity), LinearLayout.LayoutParams(1, dp(n)))
    }
    private fun rounded(color: Int = Color.WHITE, radius: Int = 9, stroke: Int = line) =
        GradientDrawable().apply {
            setColor(color)
            cornerRadius = dp(radius).toFloat()
            setStroke(dp(1), stroke)
        }
    private fun sectionTitle(body: LinearLayout, title: String) {
        body.addView(text(title, 21f, true, ink).apply {
            setPadding(dp(16), dp(22), dp(12), dp(15))
        })
    }
    private fun button(title: String, onClick: () -> Unit, fill: Int = blue): TextView =
        text(title, 14f, true, Color.WHITE).apply {
            gravity = Gravity.CENTER
            background = rounded(fill, 5, fill)
            setOnClickListener { onClick() }
            minHeight = dp(42)
            isClickable = true
        }
    private fun outlineButton(title: String, onClick: () -> Unit): TextView =
        text(title, 13f, false, blue).apply {
            gravity = Gravity.CENTER
            background = rounded(Color.WHITE, 5)
            setOnClickListener { onClick() }
            minHeight = dp(38)
        }
    private fun price(p: Double?) = if (p == null) "Цена не указана"
        else NumberFormat.getNumberInstance(Locale("ru", "RU")).apply {
            minimumFractionDigits = 2;maximumFractionDigits = 2
        }.format(p) + " р."
    private fun product(id: String): Item? = products.firstOrNull { it.id == id }

    private fun cart(): MutableMap<String, Int> {
        val map = linkedMapOf<String, Int>()
        val json = JSONObject(prefs.getString("cart", "{}") ?: "{}")
        val it = json.keys()
        while (it.hasNext()) {
            val key = it.next()
            val amount = json.optInt(key)
            if (amount > 0) map[key] = amount
        }
        return map
    }
    private fun putCart(map: Map<String, Int>) {
        val json = JSONObject()
        map.forEach { (id, count) -> if (count > 0) json.put(id, count) }
        prefs.edit().putString("cart", json.toString()).apply()
        refresh()
    }
    fun cartCount() = cart().values.sum()
    fun total() = cart().entries.sumOf { (id, n) -> (product(id)?.price ?: 0.0) * n }
    private fun addCart(id: String, delta: Int) {
        val map = cart()
        val count = (map[id] ?: 0) + delta
        if (count <= 0) map.remove(id) else map[id] = count.coerceAtMost(99)
        putCart(map)
    }
    private fun favorites(): MutableSet<String> =
        prefs.getStringSet("favorites", emptySet())?.toMutableSet() ?: mutableSetOf()
    private fun favorite(id: String) = favorites().contains(id)
    private fun toggleFavorite(id: String) {
        val set = favorites()
        if (!set.add(id)) set.remove(id)
        prefs.edit().putStringSet("favorites", set).apply()
        refresh()
    }
    private fun remember(id: String) {
        val history = (prefs.getString("history", "") ?: "").split(",")
            .filter { it.isNotBlank() && it != id }.take(12)
        prefs.edit().putString("history", (listOf(id) + history).joinToString(",")).apply()
    }
    private fun recent(): List<Item> = (prefs.getString("history", "") ?: "").split(",")
        .mapNotNull { product(it) }

    fun heading(screen: String): String = when (screen) {
        "shop:category" -> selectedCategory
        "shop:listing" -> if (selectedSubcategory.isNotBlank()) selectedSubcategory else selectedCategory
        "shop:product" -> product(currentProduct)?.title ?: "Товар"
        "shop:search" -> "Поиск"
        "shop:checkout" -> "Оформление заказа"
        else -> "ОМА"
    }
    fun back(screen: String): String = when (screen) {
        "shop:product" -> if (selectedSubcategory.isNotBlank()) "shop:listing" else "shop:category"
        "shop:listing" -> "shop:category"
        else -> ""
    }
    fun checkoutFooter(): View {
        val column = vertical().apply {
            setPadding(dp(16), dp(12), dp(16), dp(13))
            setBackgroundColor(ink)
        }
        val info = horizontal()
        info.addView(text("Итого:", 17f, true, Color.WHITE), LinearLayout.LayoutParams(0, dp(36), 1f))
        info.addView(text(price(total()), 18f, true, Color.WHITE))
        column.addView(info)
        space(column, 7)
        column.addView(button("Перейти к оформлению", { navigate("shop:checkout") }),
            LinearLayout.LayoutParams(-1, dp(49)))
        return column
    }
    fun render(screen: String, body: LinearLayout) {
        when (screen) {
            "shop:category" -> categoryScreen(body)
            "shop:listing" -> listing(body)
            "shop:product" -> detail(body)
            "shop:search" -> searchScreen(body)
            "shop:checkout" -> checkout(body)
        }
    }
    private fun openCategory(cat: String) {
        selectedCategory = cat
        selectedSubcategory = ""
        pageSize = 20
        navigate("shop:category")
    }
    private fun openListing(sub: String) {
        selectedSubcategory = sub
        pageSize = 20
        navigate("shop:listing")
    }
    private fun openProduct(id: String) {
        currentProduct = id
        showParameters = false
        remember(id)
        navigate("shop:product")
    }

    private fun bindImage(view: ImageView, item: Item?) {
        val image = item?.image.orEmpty()
        view.setBackgroundColor(Color.WHITE)
        view.scaleType = ImageView.ScaleType.FIT_CENTER
        view.setImageResource(android.R.drawable.ic_menu_gallery)
        view.tag = image
        if (image.isBlank()) return
        val cached = synchronized(imageCache) { imageCache.get(image) }
        if (cached != null) { view.setImageBitmap(cached);return }
        pool.execute {
            val bitmap = runCatching {
                val opts = BitmapFactory.Options().apply { inSampleSize = 2 }
                if (image.startsWith("/")) BitmapFactory.decodeFile(image, opts)
                else {
                    val c = URL(image).openConnection().apply {
                        connectTimeout = 6000;readTimeout = 9000
                    }
                    c.getInputStream().use { BitmapFactory.decodeStream(it, null, opts) }
                }
            }.getOrNull()
            if (bitmap != null) {
                synchronized(imageCache) { imageCache.put(image, bitmap) }
                ui.post { if (view.tag == image) view.setImageBitmap(bitmap) }
            }
        }
    }
    private fun photo(item: Item?, height: Int): ImageView = ImageView(activity).apply {
        bindImage(this, item)
        layoutParams = LinearLayout.LayoutParams(-1, dp(height))
    }
    private fun searchBar(body: LinearLayout, hint: String = "Поиск по названию или категории") {
        val container = horizontal().apply {
            background = rounded()
            setPadding(dp(11), dp(3), dp(10), dp(3))
        }
        container.addView(text("⌕", 28f, false, Color.LTGRAY))
        val input = EditText(activity).apply {
            this.hint = hint
            setSingleLine(true)
            textSize = 14f
            setTextColor(ink)
            setHintTextColor(Color.LTGRAY)
            background = null
            imeOptions = EditorInfo.IME_ACTION_SEARCH
            setPadding(dp(12), 0, 0, 0)
            setText(searchQuery.takeIf { it.isNotEmpty() } ?: "")
        }
        container.addView(input, LinearLayout.LayoutParams(0, dp(45), 1f))
        container.addView(text("▥", 21f), LinearLayout.LayoutParams(dp(25), dp(40)))
        input.setOnEditorActionListener { _, _, _ ->
            searchQuery = input.text.toString().trim()
            pageSize = 20
            navigate("shop:search")
            true
        }
        container.setOnClickListener {
            input.requestFocus()
            (activity.getSystemService(Activity.INPUT_METHOD_SERVICE) as android.view.inputmethod.InputMethodManager)
                .showSoftInput(input, android.view.inputmethod.InputMethodManager.SHOW_IMPLICIT)
        }
        body.addView(container, LinearLayout.LayoutParams(-1, dp(58)).apply {
            leftMargin = dp(16);rightMargin = dp(16);topMargin = dp(15);bottomMargin = dp(14)
        })
    }
    fun home(body: LinearLayout) {
        val top = vertical().apply { setBackgroundColor(Color.WHITE) }
        val brandRow = horizontal().apply {setPadding(dp(16), dp(13), dp(16), dp(8))}
        brandRow.addView(text("ОМА", 26f, true, blue), LinearLayout.LayoutParams(0, dp(50), 1f))
        brandRow.addView(text("➤  Минск  ❯", 15f, false, Color.BLACK).apply {
            setOnClickListener { Toast.makeText(activity, "Демонстрационный город: Минск", Toast.LENGTH_SHORT).show() }
        })
        top.addView(brandRow)
        searchBar(top)
        body.addView(top)
        space(body, 28)

        val chips = HorizontalScrollView(activity).apply { isHorizontalScrollBarEnabled = false }
        val chipRow = horizontal().apply {setPadding(dp(11), 0, dp(11), 0)}
        listOf("Шуруповерты","Смесители","Стройматериалы","Освещение","Краски","Садовая техника").forEach { s ->
            val v = text(s, 14f, true, Color.DKGRAY).apply {
                background = rounded(Color.WHITE, 7)
                gravity = Gravity.CENTER
                setPadding(dp(14), dp(12), dp(14), dp(12))
                setOnClickListener {
                    searchQuery = if (s == "Шуруповерты") "дрель" else s
                    navigate("shop:search")
                }
            }
            chipRow.addView(v, LinearLayout.LayoutParams(-2, dp(46)).apply {rightMargin = dp(10)})
        }
        chips.addView(chipRow)
        body.addView(chips)
        space(body, 15)

        val promos = HorizontalScrollView(activity).apply { isHorizontalScrollBarEnabled = false }
        val promoRow = horizontal().apply {setPadding(dp(12), 0, dp(12), 0)}
        listOf("ДОСТАВКА ПО ВСЕЙ БЕЛАРУСИ","БОЛЕЕ 70 000 ТОВАРОВ","БОНУСНАЯ КАРТА ОМА").forEachIndexed { index, s ->
            val colors = listOf(blue, Color.rgb(55, 45, 142), Color.rgb(18, 104, 159))
            val card = vertical().apply {
                background = rounded(colors[index], 10, colors[index])
                setPadding(dp(10), dp(25), dp(10), dp(10))
            }
            card.addView(text(s, 14f, true, Color.WHITE).apply {gravity = Gravity.CENTER})
            space(card, 18)
            card.addView(text(if (index == 0) "ВСЁ ДЛЯ ДОМА" else "ОМА", 19f, true, Color.WHITE)
                .apply {gravity = Gravity.CENTER})
            promoRow.addView(card, LinearLayout.LayoutParams(dp(130), dp(140)).apply {
                rightMargin = dp(9)
            })
        }
        promos.addView(promoRow)
        body.addView(promos)
        space(body, 15)

        promoBanner(body, "ХАЛВА", "НА ВСЕ · 12 МЕСЯЦЕВ", Color.rgb(0, 148, 143))
        promoBanner(body, "ПОРА В ОМА", "АКЦИИ НА ТОВАРЫ ДЛЯ ДОМА", Color.rgb(222, 27, 107))
        promoBanner(body, "ЭЛЕКТРОИНСТРУМЕНТ", "ДЕМОКАТАЛОГ ОМА", Color.rgb(22, 105, 176))
        sectionTitle(body, "Популярные товары")
        productGrid(body, products.filter { it.price != null }.take(12))
    }
    private fun promoBanner(body: LinearLayout, heading: String, subtitle: String, color: Int) {
        val box = vertical().apply {
            background = rounded(color, 12, color)
            setPadding(dp(18), dp(18), dp(18), dp(18))
            setOnClickListener { changeTab("Каталог") }
        }
        box.addView(text(heading, 23f, true, Color.WHITE))
        space(box, 12)
        box.addView(text(subtitle, 19f, true, Color.WHITE))
        body.addView(box, LinearLayout.LayoutParams(-1, dp(140)).apply {
            leftMargin = dp(16);rightMargin = dp(16);topMargin = dp(8);bottomMargin = dp(10)
        })
    }
    fun catalog(body: LinearLayout) {
        searchBar(body)
        val selected = products.size
        body.addView(text("В каталоге: " + selected.toString() + " товаров", 13f, false, Color.GRAY).apply {
            setPadding(dp(18), 0, dp(15), dp(8))
        })
        body.addView(outlineButton("Загрузить каталог из output.zip", {
            activity.startActivityForResult(
                Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "application/zip"
                }, PICK_CATALOG)
        }), LinearLayout.LayoutParams(-1, dp(42)).apply {
            leftMargin = dp(16);rightMargin = dp(16);bottomMargin = dp(14)
        })
        tileGrid(body, rootCategories) { openCategory(it) }
    }
    private fun tileGrid(body: LinearLayout, list: List<String>, click: (String) -> Unit) {
        list.chunked(2).forEach { pair ->
            val row = horizontal()
            pair.forEach { name ->
                val item = vertical().apply {
                    background = rounded(Color.WHITE, 7)
                    setPadding(dp(12), dp(10), dp(9), dp(8))
                    setOnClickListener { click(name) }
                }
                val label = text(name, 17f, true, Color.BLACK).apply {maxLines = 3}
                item.addView(label)
                val cover = products.firstOrNull {
                    it.category == name || it.subcategory == name ||
                    (name == "Стройматериалы" && it.category == "Интерьер и отделка")
                }
                val preview = photo(cover, 95).apply { setPadding(dp(48), dp(2), 0, 0) }
                item.addView(preview)
                row.addView(item, LinearLayout.LayoutParams(0, dp(167), 1f).apply {
                    leftMargin = dp(14);rightMargin = dp(6);bottomMargin = dp(14)
                })
            }
            if (pair.size < 2) row.addView(View(activity),LinearLayout.LayoutParams(0, 1, 1f))
            body.addView(row)
        }
    }
    private fun categoryScreen(body: LinearLayout) {
        searchBar(body)
        val subcats = products.filter { it.category == selectedCategory }
            .map { it.subcategory }.filter { it.isNotBlank() }.distinct()
        if (subcats.isNotEmpty()) {
            tileGrid(body, subcats) { openListing(it) }
            sectionTitle(body, "Товары категории")
            productGrid(body, products.filter { it.category == selectedCategory }.take(8))
        } else {
            sectionTitle(body, selectedCategory)
            val items = products.filter { it.category == selectedCategory }
            if (items.isEmpty()) {
                empty(body, "Товары этой категории отсутствуют в загруженном фрагменте каталога") {
                    changeTab("Каталог")
                }
            } else productGrid(body, items)
        }
    }
    private fun filtered(): List<Item> {
        var selected = products.asSequence().filter {
            it.category == selectedCategory &&
            (selectedSubcategory.isBlank() || it.subcategory == selectedSubcategory)
        }.toList()
        selected = when (sorting) {
            "Цена ↑" -> selected.sortedBy { it.price ?: Double.POSITIVE_INFINITY }
            "Цена ↓" -> selected.sortedByDescending { it.price ?: -1.0 }
            else -> selected
        }
        return selected
    }
    private fun listing(body: LinearLayout) {
        val menu = horizontal()
        val sortOptions = listOf("Популярные","Цена ↑","Цена ↓")
        menu.addView(outlineButton("⚑ Фильтры", {
            Toast.makeText(activity, "Отображаются товары выбранной категории", Toast.LENGTH_SHORT).show()
        }),LinearLayout.LayoutParams(0, dp(47), 1f))
        menu.addView(outlineButton("⇅ " + sorting, {
            sorting = sortOptions[(sortOptions.indexOf(sorting) + 1) % sortOptions.size]
            navigate("shop:listing")
        }),LinearLayout.LayoutParams(0, dp(47), 1f))
        body.addView(menu)
        val items = filtered()
        if (items.isEmpty()) empty(body, "В загруженном каталоге пока нет товаров") {changeTab("Каталог")}
        else {
            productGrid(body, items.take(pageSize))
            if (items.size > pageSize) {
                body.addView(outlineButton("Показать ещё (" + (items.size - pageSize) + ")", {
                    pageSize += 20
                    navigate("shop:listing")
                }))
            }
        }
    }
    private fun card(item: Item): LinearLayout {
        val outer = vertical().apply {
            setBackgroundColor(Color.WHITE)
            setOnClickListener { openProduct(item.id) }
        }
        outer.addView(photo(item, 156))
        val row = horizontal()
        row.addView(text(item.title, 14f, false, Color.DKGRAY).apply {
            maxLines = 3
            ellipsize = android.text.TextUtils.TruncateAt.END
        },LinearLayout.LayoutParams(0,dp(72),1f))
        row.addView(text(if (favorite(item.id)) "♥" else "♡", 28f, false, ink).apply {
            gravity = Gravity.TOP
            setOnClickListener { toggleFavorite(item.id) }
        },LinearLayout.LayoutParams(dp(29),dp(65)))
        outer.addView(row)
        outer.addView(text(price(item.price) + " / " + item.unit, 15f, true, ink),
            LinearLayout.LayoutParams(-1,dp(33)))
        if (item.oldPrice != null) {
            outer.addView(text(price(item.oldPrice), 12f, false,Color.GRAY).apply {
                paintFlags = paintFlags or android.graphics.Paint.STRIKE_THRU_TEXT_FLAG
            })
        }
        space(outer, 6)
        outer.addView(button(if (cart().containsKey(item.id)) "В корзине" else "В корзину", {
            addCart(item.id, 1)
        }), LinearLayout.LayoutParams(-1,dp(40)))
        space(outer, 6)
        return outer
    }
    private fun productGrid(body: LinearLayout, list: List<Item>) {
        list.chunked(2).forEach { pair ->
            val r = horizontal().apply { gravity = Gravity.TOP }
            pair.forEach { item ->
                r.addView(card(item),LinearLayout.LayoutParams(0,-2,1f).apply {
                    leftMargin = dp(14);rightMargin = dp(7);topMargin=dp(10);bottomMargin=dp(12)
                })
            }
            if (pair.size<2)r.addView(View(activity),LinearLayout.LayoutParams(0,1,1f))
            body.addView(r)
        }
    }
    private fun detail(body: LinearLayout) {
        val p = product(currentProduct) ?: return
        body.addView(photo(p, 350))
        body.addView(text(p.id, 12f, false, Color.GRAY).apply {
            setPadding(dp(16), dp(17), 0, 0)
        })
        body.addView(text(p.title, 20f, false, Color.DKGRAY).apply {
            setPadding(dp(16), dp(20), dp(16), dp(10))
        })
        body.addView(text(price(p.price) + " / " + p.unit, 23f, true, Color.BLACK).apply {
            setPadding(dp(16), dp(12), 0, dp(12))
        })
        val actions=horizontal().apply {setPadding(dp(16),0,dp(16),0)}
        actions.addView(button(if (favorite(p.id)) "♥ В избранном" else "♡ В избранное", {
            toggleFavorite(p.id)
        },orange),LinearLayout.LayoutParams(0, dp(49),1f).apply {rightMargin=dp(8)})
        actions.addView(button(if (cart().containsKey(p.id)) "В корзине" else "В корзину",{
            addCart(p.id,1)
        }),LinearLayout.LayoutParams(0,dp(49),1f))
        body.addView(actions)
        val sections=horizontal().apply {setPadding(dp(16),dp(13),dp(16),dp(13))}
        sections.addView(outlineButton("Описание",{showParameters=false;navigate("shop:product")}),
            LinearLayout.LayoutParams(0,dp(48),1f))
        sections.addView(outlineButton("Параметры",{showParameters=true;navigate("shop:product")}),
            LinearLayout.LayoutParams(0,dp(48),1f))
        body.addView(sections)
        if (showParameters) {
            parameter(body,"Артикул",p.id)
            parameter(body,"Категория",p.category)
            parameter(body,"Раздел",p.subcategory)
            parameter(body,"Единица измерения",p.unit)
            if(p.brand.isNotBlank()) parameter(body,"Бренд",p.brand)
        } else {
            body.addView(text("Информация о товаре",18f,true).apply{
                setPadding(dp(16),dp(10),dp(16),dp(10))
            })
            body.addView(text(p.title,15f).apply {setPadding(dp(16),0,dp(16),dp(18))})
            body.addView(text("Данные из сохранённого каталога ОМА. Цены и наличие требуют проверки.",12f,
                false,Color.GRAY).apply {setPadding(dp(16),dp(5),dp(16),dp(25))})
        }
    }
    private fun parameter(body:LinearLayout,name:String,value:String){
        val r=horizontal().apply {setPadding(dp(16),dp(13),dp(16),dp(13))}
        r.addView(text(name,14f),LinearLayout.LayoutParams(0,-2,1f))
        r.addView(text(value,14f,true,Color.BLACK).apply {gravity=Gravity.END;maxLines=3},
            LinearLayout.LayoutParams(0,-2,1f))
        body.addView(r)
        body.addView(View(activity).apply{setBackgroundColor(line)},LinearLayout.LayoutParams(-1,dp(1)))
    }
    private fun empty(body:LinearLayout,title:String,action:()->Unit) {
        space(body, 110)
        body.addView(text(title,20f,true).apply {
            gravity=Gravity.CENTER
            setPadding(dp(18),0,dp(18),dp(10))
        })
        body.addView(text("Начните с просмотра каталога товаров",15f,false,Color.DKGRAY)
            .apply {gravity=Gravity.CENTER})
        space(body,25)
        body.addView(button("Вернуться к покупкам",action),
            LinearLayout.LayoutParams(-1,dp(48)).apply {
                leftMargin=dp(64);rightMargin=dp(64)
            })
        space(body,60)
    }
    fun cartScreen(body:LinearLayout) {
        val items=cart().entries.mapNotNull { (id,n)->product(id)?.let { it to n } }
        if(items.isEmpty()) {
            empty(body,"В вашей корзине пусто") {changeTab("Каталог")}
            if(recent().isNotEmpty()){
                sectionTitle(body,"Ранее вы смотрели")
                productGrid(body,recent().take(4))
            }
            return
        }
        val promo=horizontal().apply {setPadding(dp(15),dp(15),dp(15),dp(10))}
        promo.addView(text("Промокод",15f,false,Color.GRAY).apply {
            background=rounded(Color.rgb(234,235,237),5)
            setPadding(dp(18),0,0,0)
        },LinearLayout.LayoutParams(0,dp(48),1f))
        promo.addView(button("Применить", {
            Toast.makeText(activity,"Промокоды официальной ОМА в демоверсии недоступны",Toast.LENGTH_SHORT).show()
        }),LinearLayout.LayoutParams(dp(116),dp(48)))
        body.addView(promo)
        items.forEach { (p,qty) -> swipeItem(body,p,qty) }
        space(body,40)
    }
    private fun swipeItem(body:LinearLayout,p:Item,qty:Int) {
        val view=HorizontalScrollView(activity).apply {
            isHorizontalScrollBarEnabled=false
            overScrollMode=View.OVER_SCROLL_NEVER
        }
        val line=horizontal()
        val details=horizontal().apply {
            background=rounded()
            setPadding(dp(10),dp(8),dp(8),dp(8))
            setOnClickListener {openProduct(p.id)}
        }
        val photo=ImageView(activity).apply {scaleType=ImageView.ScaleType.FIT_CENTER;bindImage(this,p)}
        details.addView(photo,LinearLayout.LayoutParams(dp(104),dp(134)))
        val right=vertical().apply {setPadding(dp(8),0,0,0)}
        right.addView(text(p.title,14f,false,Color.DKGRAY).apply {maxLines=3},
            LinearLayout.LayoutParams(-1,dp(65)))
        right.addView(text(price((p.price ?: 0.0)*qty),17f,true),LinearLayout.LayoutParams(-1,dp(35)))
        val count=horizontal()
        count.addView(button("−",{addCart(p.id,-1)},Color.rgb(45,132,186)),
            LinearLayout.LayoutParams(dp(35),dp(36)))
        count.addView(text(qty.toString(),15f).apply {gravity=Gravity.CENTER},
            LinearLayout.LayoutParams(dp(48),dp(36)))
        count.addView(button("+",{addCart(p.id,1)},Color.rgb(45,132,186)),
            LinearLayout.LayoutParams(dp(35),dp(36)))
        right.addView(count)
        details.addView(right,LinearLayout.LayoutParams(0,-2,1f))
        line.addView(details,LinearLayout.LayoutParams(
            activity.resources.displayMetrics.widthPixels - dp(24),dp(166)))
        line.addView(button("♡",{
            val set=favorites();set.add(p.id)
            prefs.edit().putStringSet("favorites",set).apply()
            addCart(p.id,-qty)
        }),LinearLayout.LayoutParams(dp(78),dp(160)))
        line.addView(button("▤", {addCart(p.id,-qty)},Color.rgb(204,51,18)),
            LinearLayout.LayoutParams(dp(78),dp(160)))
        view.addView(line)
        body.addView(view,LinearLayout.LayoutParams(-1,dp(167)).apply {
            leftMargin=dp(12);rightMargin=dp(12);topMargin=dp(9);bottomMargin=dp(9)
        })
    }
    fun favoritesScreen(body:LinearLayout){
        val items=favorites().mapNotNull {product(it)}
        if (items.isEmpty()) {
            empty(body,"У вас нет избранных товаров") {changeTab("Каталог")}
        } else productGrid(body,items)
    }
    private fun searchScreen(body:LinearLayout){
        searchBar(body)
        val q=searchQuery.lowercase(Locale.ROOT).trim()
        val matches=if(q.isBlank())emptyList() else products.filter {
            it.title.lowercase(Locale.ROOT).contains(q) ||
            it.subcategory.lowercase(Locale.ROOT).contains(q) ||
            it.category.lowercase(Locale.ROOT).contains(q)
        }
        sectionTitle(body, if(q.isBlank()) "Введите название товара" else "Товары: "+matches.size)
        if(matches.isEmpty()) {
            body.addView(text("Ничего не найдено. Попробуйте другое название.",15f)
                .apply{setPadding(dp(16),0,dp(12),dp(20))})
        }else {
            productGrid(body,matches.take(pageSize))
            if(matches.size>pageSize)body.addView(outlineButton("Показать ещё", {
                pageSize+=20;navigate("shop:search")
            }))
        }
    }
    private fun checkout(body:LinearLayout){
        if(cart().isEmpty()){empty(body,"Корзина пуста"){changeTab("Каталог")};return}
        sectionTitle(body,"Оформление демо-заказа")
        body.addView(text("Подтверждение носит демонстрационный характер. Заказ в официальную ОМА не отправляется.",
            13f,false,Color.GRAY).apply{setPadding(dp(16),0,dp(16),dp(18))})
        parameter(body,"Способ получения","Самовывоз (демо)")
        parameter(body,"Оплата","Не требуется")
        parameter(body,"Сумма",price(total()))
        body.addView(button("Подтвердить демо-заказ", {
            val record=JSONArray(prefs.getString("demo_orders","[]"))
            record.put(JSONObject().put("sum",total()).put("date",System.currentTimeMillis()))
            prefs.edit().putString("demo_orders",record.toString()).putString("cart","{}").apply()
            Toast.makeText(activity,"Демо-заказ оформлен",Toast.LENGTH_LONG).show()
            changeTab("Профиль")
        }),LinearLayout.LayoutParams(-1,dp(50)).apply{
            leftMargin=dp(16);rightMargin=dp(16);topMargin=dp(25)
        })
    }
    fun localOrders(body:LinearLayout) {
        val json=JSONArray(prefs.getString("demo_orders","[]"))
        for(i in json.length()-1 downTo 0) {
            val row=json.optJSONObject(i)?:continue
            parameter(body,"Демо-заказ №"+(i+1),price(row.optDouble("sum")))
        }
    }

    /** Import the user's own ZIP only after explicit Android picker selection. */
    fun importCatalog(uri: Uri) {
        Toast.makeText(activity,"Загружаем каталог, дождитесь завершения",Toast.LENGTH_LONG).show()
        pool.execute {
            val temporary=File(activity.filesDir,"oma_catalog_tmp")
            val target=File(activity.filesDir,"oma_catalog")
            val outcome=runCatching {
                temporary.deleteRecursively()
                temporary.mkdirs()
                var count=0
                var totalBytes=0L
                var seenDb=false
                activity.contentResolver.openInputStream(uri).use { input ->
                    requireNotNull(input) {"Невозможно открыть ZIP"}
                    ZipInputStream(input.buffered()).use { zip ->
                        while(true) {
                            val entry=zip.nextEntry?:break
                            count++
                            require(count<=15000) {"Слишком много файлов в архиве"}
                            val name=entry.name.replace('\\','/')
                            val path=when {
                                name=="output/catalog.db" -> "catalog.db"
                                name.startsWith("output/images/") && !entry.isDirectory ->
                                    name.removePrefix("output/")
                                else -> null
                            }
                            if(path!=null) {
                                val out=File(temporary,path)
                                require(out.canonicalPath.startsWith(temporary.canonicalPath+
                                    File.separator)) {"Некорректный путь в ZIP"}
                                out.parentFile?.mkdirs()
                                FileOutputStream(out).use { os ->
                                    val buffer=ByteArray(32768)
                                    while(true) {
                                        val n=zip.read(buffer)
                                        if(n<0)break
                                        totalBytes+=n
                                        require(totalBytes<=150L*1024*1024) {"Архив слишком большой"}
                                        os.write(buffer,0,n)
                                    }
                                }
                                if(path=="catalog.db")seenDb=true
                            }
                            zip.closeEntry()
                        }
                    }
                }
                require(seenDb) {"В архиве нет output/catalog.db"}
                val parsed=loadDatabase(temporary)
                require(parsed.isNotEmpty()) {"Каталог пуст"}
                target.deleteRecursively()
                require(temporary.renameTo(target)) {"Не удалось сохранить каталог"}
                val local=loadDatabase(target)
                local
            }
            ui.post {
                outcome.fold({ records ->
                    products=records
                    Toast.makeText(activity,"Загружено товаров: "+records.size,Toast.LENGTH_LONG).show()
                    changeTab("Каталог")
                },{ex ->
                    temporary.deleteRecursively()
                    Toast.makeText(activity,"Ошибка импорта: "+(ex.message?:"Неверный архив"),Toast.LENGTH_LONG).show()
                })
            }
        }
    }
    private fun loadDatabase(dir:File):List<Item> {
        val file=File(dir,"catalog.db")
        if(!file.exists())return emptyList()
        val db=SQLiteDatabase.openDatabase(file.path,null,SQLiteDatabase.OPEN_READONLY)
        return try {
            val list=ArrayList<Item>()
            db.rawQuery(
                "SELECT sku,name,category_path,price,old_price,unit,image_files,image_urls,brand "+
                "FROM products WHERE sku IS NOT NULL AND name IS NOT NULL",null
            ).use { cursor ->
                while(cursor.moveToNext()) {
                    val id=cursor.getString(0)?:continue
                    val name=cursor.getString(1)?:continue
                    val cats=(cursor.getString(2)?:"").split(" / ")
                    val images=JSONArray(cursor.getString(6)?:"[]")
                    val remote=JSONArray(cursor.getString(7)?:"[]")
                    val local=images.optString(0,"")
                    val actual=if(local.isNotBlank())File(dir,local) else null
                    val image=if(actual!=null && actual.isFile && actual.canonicalPath.startsWith(
                        dir.canonicalPath+File.separator)) actual.path else remote.optString(0,"")
                    val p=cursor.getString(3)?.toDoubleOrNull()
                    val old=cursor.getString(4)?.toDoubleOrNull()
                    list.add(Item(id,name,cats.firstOrNull().orEmpty(),
                        cats.getOrElse(1){""},p,old,cursor.getString(5)?:"шт",image,
                        cursor.getString(8)?:""))
                }
            }
            list
        } finally {db.close()}
    }
    fun loadExistingCatalog() {
        val saved=runCatching { loadDatabase(File(activity.filesDir,"oma_catalog")) }.getOrNull()
        if(!saved.isNullOrEmpty())products=saved
    }
    private fun demoProducts():List<Item> = listOf(
        Item("2.255933","Ламинат Sunfloor Сосна Тахо 52 33 кл.","Интерьер и отделка","Напольные покрытия",8.40,null,"шт","https://www.oma.by/upload/images/resize/products/c6/bb/2410171/350x350_in.jpg"),
        Item("1.228079","Накладка под фиксатор НФ-А (хром) NORA-M","Интерьер и отделка","Двери",17.57,null,"шт","https://www.oma.by/upload/images/resize/products/af/96/1421206/350x350_in.jpg"),
        Item("1.397243","Подхваты для штор Art&Home Roll 48 см","Интерьер и отделка","Шторы",3.99,null,"шт","https://www.oma.by/upload/images/resize/products/92/e1/2331361/350x350_in.jpg"),
        Item("2.422350","Напольное покрытие ПВХ Apollo Platon 1","Интерьер и отделка","Напольные покрытия",19.56,null,"шт","https://www.oma.by/upload/images/resize/products/58/31/2119729/350x350_in.jpg"),
        Item("1.369353","Колышки садовые SATO Garden 10 шт.","Благоустройство","Уход за растениями",10.98,null,"шт","https://www.oma.by/upload/images/resize/products/57/67/2119527/350x350_in.jpg"),
        Item("1.258508","Скарификатор-аэратор Stiga SV 213 E","Благоустройство","Садовая техника",560.0,null,"шт","https://www.oma.by/upload/images/resize/products/23/4e/1450830/350x350_in.jpg"),
        Item("2.306803","Тент для качелей Люкс и Родео","Благоустройство","Садовая мебель",66.06,null,"шт","https://www.oma.by/upload/images/resize/products/26/01/2434561/350x350_in.jpg"),
        Item("1.413121","Губка абразивная WERKER P220","Инструмент","Расходные материалы",2.40,null,"шт","https://www.oma.by/upload/images/resize/products/2f/38/2436920/350x350_in.jpg"),
        Item("1.411047","Аккумулятор HYUNDAI 20V/4Ah E-FUEL","Инструмент","Электроинструмент",134.33,null,"шт","https://www.oma.by/upload/images/resize/products/89/7d/2263421/350x350_in.jpg"),
        Item("2.409452","Шланг сливной для стиральной машины RENE 2 м","Бытовая техника","Аксессуары",7.45,null,"шт","https://www.oma.by/upload/images/resize/products/7b/c1/2259905/350x350_in.jpg"),
        Item("2.474585","Аэрогриль ARESA AR-5803","Бытовая техника","Техника для кухни",397.01,null,"шт","https://www.oma.by/upload/images/resize/products/96/0b/2463243/350x350_in.jpg"),
        Item("1.416041","Салфетка сервировочная Art&Home Botany","Товары для дома","Сервировка стола",5.13,null,"шт","https://www.oma.by/upload/images/resize/products/56/a0/2381472/350x350_in.jpg"),
        Item("1.394485","Ролик для одежды HomeKO 60 листов","Товары для дома","Уход за одеждой",7.32,null,"шт","https://www.oma.by/upload/images/resize/products/1d/16/2301206/350x350_in.jpg"),
        Item("1.439757","Миска Haisen Pet керамика","Товары для дома","Товары для животных",22.32,null,"шт","https://www.oma.by/upload/images/resize/products/01/e6/2425318/350x350_in.jpg"),
        Item("1.439053","Пергамент Lomberta для аэрогриля 50 шт.","Товары для дома","Кухонные принадлежности",15.88,null,"шт","https://www.oma.by/upload/images/resize/products/32/1a/2437658/350x350_in.jpg"),
        Item("2.415415","Гофротруба 40х40/50 Aquant","Сантехника","Комплектующие",6.35,null,"шт","https://www.oma.by/upload/images/resize/products/e6/fa/2090746/350x350_in.jpg"),
        Item("1.396669","Фильтр солнечный Sky-Watcher для рефракторов","Спорт и отдых","Хобби",103.60,null,"шт","https://www.oma.by/upload/images/resize/products/6d/d7/2190807/350x350_in.jpg"),
        Item("2.462065","Ножницы рыболовные Namazu 110 мм","Спорт и отдых","Рыбалка",12.54,null,"шт","https://www.oma.by/upload/images/resize/products/6a/31/2386481/350x350_in.jpg"),
        Item("1.255702","Тент для бассейна Bestway 58032","Спорт и отдых","Активный отдых",22.90,null,"шт","https://www.oma.by/upload/images/resize/products/8e/8d/2068109/350x350_in.jpg"),
        Item("2.458272","Коврик для йоги Movix MUXBY1203","Спорт и отдых","Фитнес и йога",32.48,null,"шт","https://www.oma.by/upload/images/resize/products/d8/9e/2414750/350x350_in.jpg"),
        Item("2.426623","Балаклава HUNTSMAN чёрная","Спорт и отдых","Зимний спорт",12.85,null,"шт","https://www.oma.by/upload/images/resize/products/84/32/2130994/350x350_in.jpg"),
        Item("2.441193","Чехол на руль Pilot ПВХ 1071","Автотовары","Автоаксессуары",33.10,null,"шт","https://www.oma.by/upload/images/resize/products/5a/12/2251282/350x350_in.jpg"),
        Item("2.456266","Удлинитель вентиля 135° Vilparts","Автотовары","Шины и диски",9.76,null,"шт","https://www.oma.by/upload/images/resize/products/bf/b4/2342836/350x350_in.jpg"),
        Item("1.390567","Табурет для бани Банные штучки","Красота и здоровье","Банные принадлежности",74.75,null,"шт","https://www.oma.by/upload/images/resize/products/80/11/2392081/350x350_in.jpg")
    )
}
