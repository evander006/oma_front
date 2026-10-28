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
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.label.ImageLabeling
import com.google.mlkit.vision.label.defaults.ImageLabelerOptions
import java.io.ByteArrayOutputStream
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.net.URL
import java.text.NumberFormat
import java.util.Locale
import java.util.concurrent.Executors
import java.util.zip.ZipInputStream
import kotlin.math.abs
import kotlin.math.roundToInt
import kotlin.math.sqrt

/**
 * Demo storefront based on the supplied OMA screenshots and catalog export.
 * No access to official OMA user accounts, checkout or live inventory.
 * Works with built-in sample products and an optional large offline SQLite catalog.
 * Importing output.zip installs catalog.db; photo URLs are loaded lazily.
 */
class Storefront(
    private val activity: Activity,
    private val navigate: (String) -> Unit,
    private val changeTab: (String) -> Unit,
    private val refresh: () -> Unit,
    private val openHomeHub: () -> Unit,
    private val pickPhoto: () -> Unit,
    private val isPhotoSearchVisible: () -> Boolean,
    private val openStoryFeature: (String) -> Unit
) {
    companion object {
        const val PICK_CATALOG = 7241
        const val PICK_PHOTO = 7242
        private val blue = Color.rgb(0, 99, 174)
        private val ink = Color.rgb(46, 63, 78)
        private val orange = Color.rgb(246, 154, 37)
        private val soft = Color.rgb(249, 249, 249)
        private val line = Color.rgb(229, 231, 232)
        private val pool = Executors.newFixedThreadPool(4)
        private val catalogPool = Executors.newSingleThreadExecutor()
        private val ui = Handler(Looper.getMainLooper())
        private val imageCache = object : android.util.LruCache<String, Bitmap>(24 * 1024) {
            override fun sizeOf(key: String, value: Bitmap) = value.byteCount / 1024
        }
    }

    private val prefs: SharedPreferences =
        activity.getSharedPreferences("oma_store_offline", Activity.MODE_PRIVATE)
    private val api = Api(activity)
    // Only visible products are materialized. The complete imported catalog stays in SQLite.
    private var products: List<Item> = demoProducts()
    @Volatile private var catalogDb: OmaCatalogDatabase? = null
    private var catalogCount = 0
    private var catalogLoading = false
    private var catalogNotice = ""
    private var categoryMap: Map<String, List<String>> = emptyMap()
    private var catalogStatusView: TextView? = null
    private var pageOffset = 0
    private var pageKey = ""
    private var pageResult: OmaCatalogDatabase.Page? = null
    private var pageLoading = false
    private var pageError = ""
    private val productCache = LinkedHashMap<String, Item>()
    private val pendingSkuLoads = mutableSetOf<String>()
    private var selectedCategory = "Инструмент"
    private var selectedSubcategory = ""
    private var currentProduct = ""
    private var searchQuery = ""
    private var sorting = "Популярные"
    private var pageSize = 20
    private var showParameters = false
    private var photoUri: Uri? = null
    private var photoBusy = false
    private var photoError = ""
    private var photoMatches: List<Pair<Item, Int>> = emptyList()
    private var photoAnalysisNote = ""
    private var photoDetected = ""
    private var photoSearchToken = 0
    private var photoMatchLabel = "Релевантность"
    private val rootCategories = listOf(
        "Акции", "Интерьер и отделка", "Благоустройство", "Стройматериалы",
        "Инструмент", "Мебель", "Бытовая техника", "Товары для дома",
        "Сантехника", "Электрика", "Инженерные системы", "Спорт и отдых",
        "Новый год", "Крепеж", "Автотовары", "Электроника",
        "Товары для детей", "Красота и здоровье", "Прокат"
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
    /** Rounded (in dp) background with a darker pressed state. */
    private fun pressable(color: Int, radius: Int, stroke: Int = color) =
        android.graphics.drawable.StateListDrawable().apply {
            val dark = if (color == Color.WHITE) Style.PRESSED
                else Color.rgb(Color.red(color) * 4 / 5, Color.green(color) * 4 / 5, Color.blue(color) * 4 / 5)
            addState(intArrayOf(android.R.attr.state_pressed), rounded(dark, radius, if (stroke == color) dark else stroke))
            addState(intArrayOf(), rounded(color, radius, stroke))
        }
    private fun sectionTitle(body: LinearLayout, title: String, all: (() -> Unit)? = null) {
        val row = horizontal().apply { setPadding(dp(16), dp(24), dp(16), dp(16)) }
        row.addView(text(title, 25f, true, Color.rgb(20, 24, 28)), LinearLayout.LayoutParams(0, -2, 1f))
        if (all != null) {
            row.addView(text("Все", 18f, false, Color.rgb(20, 24, 28)).apply { setOnClickListener { all() } })
            row.addView(LineIcon(activity, "chevron", Color.rgb(20, 24, 28)), LinearLayout.LayoutParams(dp(20), dp(20)))
        }
        body.addView(row)
    }
    private val red = Color.rgb(200, 16, 30)
    private fun priceText(value: Double?, unit: String, size: Float, color: Int) = TextView(activity).apply {
        val main = price(value)
        val tail = if (value == null) "" else " / $unit"
        val s = android.text.SpannableString(main + tail)
        s.setSpan(android.text.style.StyleSpan(Typeface.BOLD), 0, main.length, 0)
        s.setSpan(android.text.style.RelativeSizeSpan(.78f), main.length, s.length, 0)
        s.setSpan(android.text.style.ForegroundColorSpan(Color.rgb(90, 96, 102)), main.length, s.length, 0)
        text = s;textSize = size;setTextColor(color)
    }
    private fun button(title: String, onClick: () -> Unit, fill: Int = blue): TextView =
        text(title, 15f, false, Color.WHITE).apply {
            gravity = Gravity.CENTER
            background = pressable(fill, 6)
            stateListAnimator = null
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
    private fun product(id: String): Item? =
        productCache[id] ?: products.firstOrNull { it.id == id }

    private fun rememberProducts(items: List<Item>) {
        for (item in items) productCache[item.id] = item
        while (productCache.size > 350) {
            productCache.remove(productCache.keys.first())
        }
    }

    private fun loadMissingIds(ids: Collection<String>) {
        val database = catalogDb ?: return
        val missing = ids.filter { product(it) == null && pendingSkuLoads.add(it) }
        if (missing.isEmpty()) return
        catalogPool.execute {
            val found = missing.mapNotNull { sku ->
                runCatching { database.bySku(sku) }.getOrNull()
            }
            ui.post {
                pendingSkuLoads.removeAll(missing.toSet())
                if (database === catalogDb) {
                    rememberProducts(found)
                    if (!activity.isFinishing && !activity.isDestroyed) refresh()
                }
            }
        }
    }

    private fun requestPage(
        key: String,
        category: String = "",
        subcategory: String = "",
        search: String = "",
        sort: String = "",
        limit: Int = 20,
        offset: Int = 0
    ): OmaCatalogDatabase.Page? {
        val db = catalogDb ?: return null
        if (pageKey != key) {
            pageKey = key
            pageResult = null
            pageLoading = true
            pageError = ""
            catalogPool.execute {
                val result = runCatching {
                    db.page(category, subcategory, search, sort, limit, offset)
                }
                ui.post {
                    if (pageKey != key || db !== catalogDb) return@post
                    pageLoading = false
                    result.fold(
                        { page ->
                            pageResult = page
                            rememberProducts(page.records)
                        },
                        { error -> pageError = error.message ?: "Ошибка чтения каталога" }
                    )
                    if (!activity.isFinishing && !activity.isDestroyed) refresh()
                }
            }
        }
        return pageResult
    }

    private fun renderPageState(body: LinearLayout) {
        body.addView(text(
            if (pageLoading) "Загружаем 20 товаров из базы…" else
                pageError.ifBlank { "По вашему запросу ничего не найдено" },
            14f, false, Color.GRAY
        ).apply { setPadding(dp(16), dp(20), dp(16), dp(24)) })
        if (pageLoading) body.addView(ProgressBar(activity).apply { isIndeterminate = true })
    }

    private fun pageNavigation(body: LinearLayout, page: OmaCatalogDatabase.Page, redraw: String) {
        body.addView(text(
            "Показано ${if (page.total == 0) 0 else pageOffset + 1}–" +
                "${(pageOffset + page.records.size).coerceAtMost(page.total)} из ${page.total}",
            13f, false, Color.GRAY
        ).apply { setPadding(dp(18), dp(15), dp(16), dp(12)) })
        val row = horizontal()
        if (pageOffset > 0) {
            row.addView(outlineButton("← Назад") {
                pageOffset = (pageOffset - 20).coerceAtLeast(0)
                navigate(redraw)
            }, LinearLayout.LayoutParams(0, dp(46), 1f).apply { rightMargin = dp(8) })
        }
        if (pageOffset + page.records.size < page.total) {
            row.addView(button("Следующие 20 товаров →", {
                pageOffset += 20
                navigate(redraw)
            }), LinearLayout.LayoutParams(0, dp(46), 1f))
        }
        if (row.childCount > 0) body.addView(row, LinearLayout.LayoutParams(-1, -2).apply {
            leftMargin = dp(16);rightMargin = dp(16);bottomMargin = dp(24)
        })
    }

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
        val added = set.add(id)
        if (!added) set.remove(id)
        prefs.edit().putStringSet("favorites", set).apply()
        Toast.makeText(activity, if (added) "Товар добавлен в избранное" else "Товар удален из избранного", Toast.LENGTH_SHORT).show()
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
        "shop:photo" -> "Поиск по фото"
        "shop:checkout" -> "Оформление заказа"
        else -> "ОМА"
    }
    fun back(screen: String): String = when (screen) {
        "shop:product" -> if (selectedSubcategory.isNotBlank()) "shop:listing" else "shop:category"
        "shop:photo" -> ""
        "shop:listing" -> "shop:category"
        else -> ""
    }
    fun checkoutFooter(): View {
        val column = vertical().apply {
            setPadding(dp(24), dp(14), dp(24), dp(16))
            setBackgroundColor(Color.rgb(46, 62, 80))
        }
        val discount = horizontal()
        discount.addView(text("Скидка:", 17f, false, Color.WHITE), LinearLayout.LayoutParams(0, dp(30), 1f))
        discount.addView(text(price(0.0), 17f, false, Color.WHITE))
        column.addView(discount)
        val info = horizontal()
        info.addView(text("Итого:", 22f, true, Color.WHITE), LinearLayout.LayoutParams(0, dp(38), 1f))
        info.addView(text(price(total()), 22f, true, Color.WHITE))
        column.addView(info)
        space(column, 12)
        column.addView(button("Перейти к оформлению", { navigate("shop:checkout") }).apply { textSize = 18f },
            LinearLayout.LayoutParams(-1, dp(58)))
        return column
    }
    fun render(screen: String, body: LinearLayout) {
        when (screen) {
            "shop:category" -> categoryScreen(body)
            "shop:listing" -> listing(body)
            "shop:product" -> detail(body)
            "shop:search" -> searchScreen(body)
            "shop:photo" -> photoSearchScreen(body)
            "shop:checkout" -> checkout(body)
        }
    }
    private fun openCategory(cat: String) {
        selectedCategory = cat
        selectedSubcategory = ""
        pageSize = 20
        pageOffset = 0
        navigate("shop:category")
    }
    private fun openListing(sub: String) {
        selectedSubcategory = sub
        pageSize = 20
        pageOffset = 0
        navigate("shop:listing")
    }
    private fun openProduct(id: String) {
        currentProduct = id
        showParameters = false
        remember(id)
        if (catalogDb != null && product(id) == null) loadMissingIds(listOf(id))
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
            background = rounded(Color.WHITE, 12, Color.rgb(236, 237, 238))
            elevation = dp(2).toFloat()
            setPadding(dp(16), dp(3), dp(14), dp(3))
        }
        container.addView(LineIcon(activity, "magnifier", Color.rgb(160, 165, 170)),
            LinearLayout.LayoutParams(dp(24), dp(24)))
        val input = EditText(activity).apply {
            this.hint = hint
            setSingleLine(true)
            textSize = 16f
            setTextColor(ink)
            setHintTextColor(Color.rgb(170, 174, 178))
            background = null
            imeOptions = EditorInfo.IME_ACTION_SEARCH
            setPadding(dp(12), 0, 0, 0)
            setText(searchQuery.takeIf { it.isNotEmpty() } ?: "")
        }
        container.addView(input, LinearLayout.LayoutParams(0, dp(45), 1f))
        container.addView(LineIcon(activity, "camera", Color.rgb(90, 96, 102)).apply {
            contentDescription="Поиск по фото"
            setOnClickListener { pickPhoto() }
        }, LinearLayout.LayoutParams(dp(30), dp(30)))
        input.setOnEditorActionListener { _, _, _ ->
            searchQuery = input.text.toString().trim()
            pageSize = 20
            pageOffset = 0
            navigate("shop:search")
            true
        }
        container.setOnClickListener {
            input.requestFocus()
            (activity.getSystemService(Activity.INPUT_METHOD_SERVICE) as android.view.inputmethod.InputMethodManager)
                .showSoftInput(input, android.view.inputmethod.InputMethodManager.SHOW_IMPLICIT)
        }
        body.addView(container, LinearLayout.LayoutParams(-1, dp(56)).apply {
            leftMargin = dp(16);rightMargin = dp(16);topMargin = dp(12);bottomMargin = dp(16)
        })
    }
    private fun roundedImage(res: Int, radius: Int) = ImageView(activity).apply {
        setImageResource(res)
        scaleType = ImageView.ScaleType.CENTER_CROP
        background = rounded(Color.WHITE, radius, Color.TRANSPARENT)
        clipToOutline = true
    }
    private val stories = listOf(R.drawable.oma_story_passport, R.drawable.oma_story_interior,
        R.drawable.oma_story_visual, R.drawable.oma_story_service, R.drawable.oma_story_bonus, R.drawable.oma_story_sale60,
        R.drawable.oma_story_credit, R.drawable.oma_story_delivery, R.drawable.oma_story_assortment)
    private val banners = listOf(R.drawable.oma_banner_halva, R.drawable.oma_banner_lamps,
        R.drawable.oma_banner_makita, R.drawable.oma_banner_appliances, R.drawable.oma_banner_bedding,
        R.drawable.oma_banner_foam, R.drawable.oma_banner_alpina, R.drawable.oma_banner_lastunit)
    private fun openStory(start: Int) {
        val dialog = android.app.Dialog(activity, android.R.style.Theme_Black_NoTitleBar_Fullscreen)
        val frame = FrameLayout(activity).apply { setBackgroundColor(Color.BLACK) }
        val image = ImageView(activity).apply { scaleType = ImageView.ScaleType.FIT_CENTER }
        frame.addView(image, FrameLayout.LayoutParams(-1, -1))
        val bars = horizontal().apply { setPadding(dp(8), dp(12), dp(8), 0) }
        val fills = stories.map {
            val track = FrameLayout(activity).apply { background = rounded(Color.argb(90, 255, 255, 255), 2, Color.TRANSPARENT) }
            val fill = View(activity).apply { background = rounded(Color.WHITE, 2, Color.TRANSPARENT);pivotX = 0f;scaleX = 0f }
            track.addView(fill, FrameLayout.LayoutParams(-1, -1))
            bars.addView(track, LinearLayout.LayoutParams(0, dp(3), 1f).apply { leftMargin = dp(2);rightMargin = dp(2) })
            fill
        }
        frame.addView(bars, FrameLayout.LayoutParams(-1, -2, Gravity.TOP))
        var index = start
        fun show(i: Int) {
            if (i !in stories.indices) { dialog.dismiss();return }
            index = i
            fills.forEachIndexed { n, v -> v.animate().cancel();v.scaleX = if (n < i) 1f else 0f }
            image.setImageResource(stories[i])
            image.alpha = 0f;image.animate().alpha(1f).setDuration(180).start()
            fills[i].animate().scaleX(1f).setDuration(5000).setInterpolator(android.view.animation.LinearInterpolator())
                .withEndAction { if (dialog.isShowing && index == i) show(i + 1) }.start()
        }
        frame.setOnClickListener {}
        frame.setOnTouchListener { v, e ->
            if (e.action == android.view.MotionEvent.ACTION_UP)
                show(if (e.x < v.width / 3f) (index - 1).coerceAtLeast(0) else index + 1)
            true
        }
        dialog.setContentView(frame)
        dialog.show()
        show(start)
    }
    fun home(body: LinearLayout) {
        body.setBackgroundColor(Color.WHITE)
        val top = vertical().apply { setBackgroundColor(Color.WHITE);elevation = dp(3).toFloat() }
        val brandRow = horizontal().apply {setPadding(dp(16), dp(14), dp(16), dp(6))}
        brandRow.addView(ImageView(activity).apply {
            setImageResource(R.drawable.oma_logo);scaleType = ImageView.ScaleType.FIT_START
            contentDescription = "ОМА"
        }, LinearLayout.LayoutParams(0, dp(32), 1f))
        brandRow.addView(LineIcon(activity,"home",ink).apply {
            contentDescription="Открыть цифровой дом"
            setOnClickListener { openHomeHub() }
        }, LinearLayout.LayoutParams(dp(28),dp(28)).apply {rightMargin=dp(16)})
        val city = horizontal().apply {
            setOnClickListener { Toast.makeText(activity, "Демонстрационный город: Минск", Toast.LENGTH_SHORT).show() }
        }
        city.addView(LineIcon(activity, "location", Color.BLACK), LinearLayout.LayoutParams(dp(18), dp(18)).apply { rightMargin = dp(8) })
        city.addView(text("Минск", 19f, false, Color.BLACK))
        city.addView(LineIcon(activity, "chevron", Color.BLACK), LinearLayout.LayoutParams(dp(18), dp(18)))
        brandRow.addView(city)
        top.addView(brandRow)
        searchBar(top)
        body.addView(top)
        space(body, 34)

        val chips = HorizontalScrollView(activity).apply { isHorizontalScrollBarEnabled = false;clipToPadding = false }
        val chipRow = horizontal().apply {setPadding(dp(14), dp(2), dp(14), dp(4))}
        listOf("Шуруповерты" to "drill","Смесители" to "faucet","Стройматериалы" to "bricks",
            "Освещение" to "bulb","Краски" to "roller").forEach { (s, glyph) ->
            val v = horizontal().apply {
                background = pressable(Color.WHITE, 6, Color.rgb(232, 233, 234))
                elevation = dp(1).toFloat()
                setPadding(dp(18), 0, dp(20), 0)
                setOnClickListener {
                    searchQuery = if (s == "Шуруповерты") "дрель" else s
                    navigate("shop:search")
                }
            }
            v.addView(LineIcon(activity, glyph, Color.BLACK), LinearLayout.LayoutParams(dp(24), dp(24)).apply { rightMargin = dp(14) })
            v.addView(text(s, 17f, true, Color.rgb(30, 30, 30)))
            chipRow.addView(v, LinearLayout.LayoutParams(-2, dp(52)).apply {rightMargin = dp(12)})
        }
        chips.addView(chipRow)
        body.addView(chips)
        space(body, 16)

        // Stories: the first one carries the orange "new" ring, as in the OMA app.
        val promos = HorizontalScrollView(activity).apply { isHorizontalScrollBarEnabled = false }
        val promoRow = horizontal().apply {setPadding(dp(12), 0, dp(12), 0)}
        stories.forEachIndexed { index, res ->
            val ring = FrameLayout(activity).apply {
                background = rounded(Color.WHITE, 12, if (index == 0) orange else Color.TRANSPARENT).apply {
                    setStroke(dp(3), if (index == 0) orange else Color.TRANSPARENT)
                }
                setPadding(dp(4), dp(4), dp(4), dp(4))
                contentDescription = when (index) {
                    0 -> "Паспорт дома"
                    1 -> "3D-модель дома"
                    2 -> "Поиск по фото"
                    3 -> "Знающий мастер"
                    else -> "История ${index + 1}"
                }
                setOnClickListener {
                    when (index) {
                        0 -> openStoryFeature("home:passport")
                        1 -> openStoryFeature("home:3d")
                        2 -> openStoryFeature("photo")
                        3 -> openStoryFeature("master:hub")
                        else -> openStory(index)
                    }
                }
            }
            ring.addView(roundedImage(res, 8), FrameLayout.LayoutParams(-1, -1))
            promoRow.addView(ring, LinearLayout.LayoutParams(dp(110), dp(136)).apply { rightMargin = dp(6) })
        }
        promos.addView(promoRow)
        body.addView(promos)
        space(body, 14)

        banners.forEach { res ->
            body.addView(roundedImage(res, 12).apply {
                scaleType = ImageView.ScaleType.FIT_XY
                adjustViewBounds = true
                elevation = dp(2).toFloat()
                setOnClickListener { changeTab("Каталог") }
            }, LinearLayout.LayoutParams(-1, -2).apply {
                leftMargin = dp(16);rightMargin = dp(16);topMargin = dp(8);bottomMargin = dp(16)
            })
        }
        sectionTitle(body, "Популярные товары")
        productGrid(body, products.filter { it.price != null }.take(12), buttons = false)
    }
    fun catalog(body: LinearLayout) {
        searchBar(body)
        tileGrid(body, rootCategories) { openCategory(it) }
        val catalogMessage = if (catalogLoading) "Загружаем сохранённый каталог…" else "В каталоге: ${products.size} товаров"
        body.addView(text(catalogMessage, 13f, false, Color.GRAY).apply {
            setPadding(dp(18), dp(8), dp(15), dp(8))
        })
        body.addView(outlineButton("Загрузить каталог из output.zip", {
            activity.startActivityForResult(
                Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "application/zip"
                }, PICK_CATALOG)
        }), LinearLayout.LayoutParams(-1, dp(42)).apply {
            leftMargin = dp(16);rightMargin = dp(16);bottomMargin = dp(24)
        })
    }
    private val categoryArt = mapOf("Акции" to R.drawable.cat_sale, "Интерьер и отделка" to R.drawable.cat_interior,
        "Благоустройство" to R.drawable.cat_garden, "Стройматериалы" to R.drawable.cat_building,
        "Инструмент" to R.drawable.cat_tools, "Мебель" to R.drawable.cat_furniture)
    private fun tileGrid(body: LinearLayout, list: List<String>, click: (String) -> Unit) {
        list.chunked(2).forEach { pair ->
            val row = horizontal()
            pair.forEach { name ->
                val item = vertical().apply {
                    background = pressable(Color.WHITE, 8)
                    elevation = dp(2).toFloat()
                    setPadding(dp(18), dp(18), dp(8), dp(8))
                    setOnClickListener { click(name) }
                }
                val label = text(name, 18f, true, Color.BLACK).apply {
                    maxLines = 2;gravity = Gravity.TOP
                    breakStrategy = android.text.Layout.BREAK_STRATEGY_SIMPLE
                    hyphenationFrequency = android.text.Layout.HYPHENATION_FREQUENCY_NONE
                    // Shrink until the longest word fits on one line, so words never split.
                    val room = activity.resources.displayMetrics.widthPixels / 2f - dp(52)
                    val longest = name.split(" ").maxByOrNull { it.length } ?: name
                    while (textSize > dp(13) && paint.measureText(longest) > room) setTextSize(android.util.TypedValue.COMPLEX_UNIT_PX, textSize - 1f)
                }
                item.addView(label, LinearLayout.LayoutParams(-1, dp(52)))
                val preview = (categoryArt[name]?.let { res ->
                    ImageView(activity).apply { setImageResource(res);scaleType = ImageView.ScaleType.FIT_CENTER }
                } ?: photo(products.firstOrNull { it.category == name || it.subcategory == name }, 110).apply {
                    scaleType = ImageView.ScaleType.FIT_CENTER;setBackgroundColor(Color.TRANSPARENT)
                })
                item.addView(preview, LinearLayout.LayoutParams(-1, 0, 1f).apply { rightMargin = dp(10);bottomMargin = dp(6) })
                row.addView(item, LinearLayout.LayoutParams(0, dp(212), 1f).apply {
                    leftMargin = dp(13);rightMargin = dp(13);bottomMargin = dp(26)
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
        val menu = horizontal().apply { setBackgroundColor(Color.WHITE) }
        val sortOptions = listOf("Популярные","Цена ↑","Цена ↓")
        fun half(glyph: String, title: String, click: () -> Unit) = horizontal().apply {
            gravity = Gravity.CENTER
            background = Style.interactiveBg(Color.WHITE, Style.PRESSED, 0f)
            setOnClickListener { click() }
            addView(LineIcon(activity, glyph, ink), LinearLayout.LayoutParams(dp(20), dp(20)).apply { rightMargin = dp(8) })
            addView(text(title, 18f, false, ink))
        }
        menu.addView(half("filter", "Фильтры") {
            Toast.makeText(activity, "Отображаются товары выбранной категории", Toast.LENGTH_SHORT).show()
        },LinearLayout.LayoutParams(0, dp(52), 1f))
        menu.addView(View(activity).apply { setBackgroundColor(line) }, LinearLayout.LayoutParams(dp(1), dp(52)))
        menu.addView(half("sort", sorting) {
            sorting = sortOptions[(sortOptions.indexOf(sorting) + 1) % sortOptions.size]
            navigate("shop:listing")
        },LinearLayout.LayoutParams(0, dp(52), 1f))
        body.addView(menu)
        body.addView(View(activity).apply { setBackgroundColor(line) }, LinearLayout.LayoutParams(-1, dp(1)))
        space(body, 14)
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
    private fun card(item: Item, withButton: Boolean): LinearLayout {
        // Every block has a fixed height so neighbouring cards line up: photo, 3 title lines,
        // price, old-price line (blank when absent) and the button sit on the same baselines.
        val outer = vertical().apply {
            setBackgroundColor(Color.WHITE)
            setPadding(0, 0, 0, dp(12))
            setOnClickListener { openProduct(item.id) }
        }
        outer.addView(photo(item, 184).apply { setPadding(dp(6), dp(6), dp(6), dp(6)) },
            LinearLayout.LayoutParams(-1, dp(184)))
        val info = vertical().apply { setPadding(dp(10), dp(10), dp(10), 0) }
        outer.addView(info)
        val row = horizontal().apply { gravity = Gravity.TOP }
        row.addView(text(item.title, 16f, false, Color.rgb(30, 34, 38)).apply {
            gravity = Gravity.TOP
            setLines(3)
            setLineSpacing(0f, 1.05f)
            ellipsize = android.text.TextUtils.TruncateAt.END
        },LinearLayout.LayoutParams(0,-2,1f))
        val fav = favorite(item.id)
        row.addView(LineIcon(activity, if (fav) "heart-fill" else "heart", ink).apply {
            contentDescription = if (fav) "Убрать из избранного" else "В избранное"
            setOnClickListener {
                animate().scaleX(1.25f).scaleY(1.25f).setDuration(110).withEndAction { toggleFavorite(item.id) }.start()
            }
        },LinearLayout.LayoutParams(dp(26),dp(26)).apply { leftMargin = dp(6) })
        info.addView(row)
        space(info, 8)
        val discount = item.oldPrice != null && item.price != null && item.oldPrice > item.price
        val priceRow = horizontal()
        priceRow.addView(priceText(item.price, item.unit, 17f, if (discount) red else ink))
        if (discount) {
            val pct = ((1 - item.price!! / item.oldPrice!!) * 100).roundToInt()
            priceRow.addView(text("-$pct%", 13f, false, red).apply {
                background = rounded(Color.WHITE, 4, red)
                setPadding(dp(5), 0, dp(5), 0)
            }, LinearLayout.LayoutParams(-2, dp(22)).apply { leftMargin = dp(8) })
        }
        info.addView(priceRow, LinearLayout.LayoutParams(-1, dp(26)))
        info.addView(text(item.oldPrice?.let { price(it) } ?: "", 14f, false, Color.rgb(150, 155, 160)).apply {
            paintFlags = paintFlags or android.graphics.Paint.STRIKE_THRU_TEXT_FLAG
        }, LinearLayout.LayoutParams(-1, dp(20)))
        if (withButton) {
            space(info, 10)
            info.addView(button(if (cart().containsKey(item.id)) "В корзине" else "В корзину", {
                addCart(item.id, 1)
            }), LinearLayout.LayoutParams(-1,dp(42)))
        }
        return outer
    }
    private fun productGrid(body: LinearLayout, list: List<Item>, buttons: Boolean = true) {
        list.chunked(2).forEach { pair ->
            val r = horizontal().apply { gravity = Gravity.TOP;setPadding(dp(10), 0, dp(10), 0) }
            pair.forEach { item ->
                r.addView(card(item, buttons),LinearLayout.LayoutParams(0,-2,1f).apply {
                    leftMargin = dp(6);rightMargin = dp(6);topMargin=dp(6);bottomMargin=dp(6)
                })
            }
            if (pair.size<2)r.addView(View(activity),LinearLayout.LayoutParams(0,1,1f))
            body.addView(r)
        }
    }
    private fun detail(body: LinearLayout) {
        val p = product(currentProduct) ?: return
        body.addView(photo(p, 350).apply { setPadding(0, dp(16), 0, dp(16)) })
        val info = vertical().apply { setBackgroundColor(Color.rgb(247, 247, 247));setPadding(0, dp(18), 0, 0) }
        body.addView(info)
        info.addView(text(p.id, 15f, false, Color.rgb(150, 155, 160)).apply {
            setPadding(dp(16), 0, 0, 0)
        })
        info.addView(text(p.title, 23f, false, Color.rgb(60, 66, 72)).apply {
            setPadding(dp(16), dp(12), dp(16), dp(8))
        })
        info.addView(priceText(p.price, p.unit, 27f, Color.BLACK).apply {
            setPadding(dp(16), dp(12), 0, dp(16))
        })
        val actions=horizontal().apply {setPadding(dp(16),0,dp(16),0)}
        fun iconButton(glyph: String, title: String, fill: Int, click: () -> Unit) = horizontal().apply {
            gravity = Gravity.CENTER
            background = pressable(fill, 8)
            isClickable = true
            setOnClickListener { click() }
            addView(LineIcon(activity, glyph, Color.WHITE), LinearLayout.LayoutParams(dp(24), dp(24)).apply { rightMargin = dp(10) })
            addView(text(title, 18f, false, Color.WHITE))
        }
        val fav = favorite(p.id)
        actions.addView(iconButton(if (fav) "heart-fill" else "heart", if (fav) "В избранном" else "В избранное", orange) {
            toggleFavorite(p.id)
        },LinearLayout.LayoutParams(0, dp(56),1f).apply {rightMargin=dp(14)})
        actions.addView(iconButton("bag", if (cart().containsKey(p.id)) "В корзине" else "В корзину", blue) {
            addCart(p.id,1)
        },LinearLayout.LayoutParams(0,dp(56),1f))
        info.addView(actions)
        // Segmented control: grey track, the active half is a raised white pill.
        val sections=horizontal().apply {
            background = rounded(Color.rgb(236, 237, 238), 10, Color.rgb(236, 237, 238))
            setPadding(dp(3), dp(3), dp(3), dp(3))
        }
        listOf("Описание" to false, "Параметры" to true).forEach { (title, params) ->
            val active = showParameters == params
            sections.addView(text(title, 18f, false, Color.rgb(30, 34, 38)).apply {
                gravity = Gravity.CENTER
                if (active) { background = rounded(Color.WHITE, 8, Color.WHITE);elevation = dp(2).toFloat() }
                setOnClickListener { if (!active) { showParameters = params;navigate("shop:product") } }
            }, LinearLayout.LayoutParams(0, -1, 1f))
        }
        info.addView(sections, LinearLayout.LayoutParams(-1, dp(56)).apply {
            leftMargin = dp(16);rightMargin = dp(16);topMargin = dp(18);bottomMargin = dp(8)
        })
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
        r.addView(text(name,18f,false,Color.rgb(40,44,48)),LinearLayout.LayoutParams(0,-2,1f))
        r.addView(text(value,18f,true,Color.rgb(40,44,48)).apply {gravity=Gravity.END;maxLines=3
            paintFlags=paintFlags or android.graphics.Paint.UNDERLINE_TEXT_FLAG},
            LinearLayout.LayoutParams(0,-2,1f))
        body.addView(r)
        body.addView(View(activity).apply{setBackgroundColor(line)},LinearLayout.LayoutParams(-1,dp(1)))
    }
    private fun empty(body:LinearLayout,title:String,action:()->Unit) {
        space(body, 96)
        body.addView(text(title,25f,true,ink).apply {
            gravity=Gravity.CENTER
            setPadding(dp(18),0,dp(18),dp(12))
        })
        body.addView(text("Начните с просмотра каталога товаров,\nи вы обязательно найдете то, что вам нужно",16f,false,Color.rgb(40,44,48))
            .apply {gravity=Gravity.CENTER;setLineSpacing(0f,1.15f)})
        space(body,22)
        body.addView(button("Вернуться к покупкам",action).apply {
                textSize=17f;setTypeface(null,Typeface.BOLD);setPadding(dp(26),0,dp(26),0)
            },
            LinearLayout.LayoutParams(-2,dp(56)).apply {gravity=Gravity.CENTER_HORIZONTAL})
        space(body,48)
    }
    fun cartScreen(body:LinearLayout) {
        val items=cart().entries.mapNotNull { (id,n)->product(id)?.let { it to n } }
        if(items.isEmpty()) {
            empty(body,"В вашей корзине пусто") {changeTab("Каталог")}
            if(recent().isNotEmpty()){
                sectionTitle(body,"Ранее вы смотрели") {}
                productGrid(body,recent().take(4))
            }
            return
        }
        val promo=horizontal().apply {setPadding(dp(24),dp(24),dp(24),dp(10))}
        promo.addView(text("Промокод",17f,false,Color.rgb(110,116,122)).apply {
            background=GradientDrawable().apply{setColor(Color.rgb(230,232,234))
                cornerRadii=FloatArray(8){if(it==0||it==1||it==6||it==7)dp(4).toFloat() else 0f}}
            setPadding(dp(32),0,0,0)
        },LinearLayout.LayoutParams(0,dp(52),1f))
        promo.addView(text("Применить",19f,false,Color.WHITE).apply {
            gravity=Gravity.CENTER
            background=GradientDrawable().apply{setColor(blue)
                cornerRadii=FloatArray(8){if(it in 2..5)dp(4).toFloat() else 0f}}
            setOnClickListener{Toast.makeText(activity,"Промокоды официальной ОМА в демоверсии недоступны",Toast.LENGTH_SHORT).show()}
        },LinearLayout.LayoutParams(dp(176),dp(52)))
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
        fun sideAction(glyph:String,name:String,fill:Int,onClick:()->Unit)=LinearLayout(activity).apply {
            gravity=Gravity.CENTER;setBackgroundColor(fill);contentDescription=name
            isClickable=true;isFocusable=true;setOnClickListener{onClick()}
            addView(LineIcon(activity,glyph,Color.WHITE),LinearLayout.LayoutParams(dp(34),dp(34)))
        }
        line.addView(sideAction("heart","В избранное",blue){
            val set=favorites();set.add(p.id)
            prefs.edit().putStringSet("favorites",set).apply()
            addCart(p.id,-qty)
        },LinearLayout.LayoutParams(dp(78),dp(160)))
        line.addView(sideAction("trash","Удалить",Color.rgb(204,51,18)){addCart(p.id,-qty)},
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

    /** Search against the imported OMA catalog, never just the backend demo catalog. */
    fun analyzePhoto(uri: Uri) {
        val requestId = ++photoSearchToken
        photoUri = uri; photoBusy = true; photoError = ""; photoMatches = emptyList()
        photoAnalysisNote = ""; photoDetected = ""
        photoMatchLabel = "Релевантность"
        navigate("shop:photo")

        // The bundled on-device labeler responds quickly, even without a server.
        analyzePhotoOnDevice(uri, requestId)

        // A configured remote vision provider can improve the object terms later.
        pool.execute {
            val photoBytes = runCatching { preparePhotoUpload(uri) }
            photoBytes.onSuccess { bytes ->
                api.visualSearch(bytes, "image/jpeg") { remote ->
                    remote.onSuccess { raw ->
                        pool.execute {
                            val result = runCatching { parseRemoteMatches(raw) }.getOrNull()
                            ui.post {
                                if (requestId != photoSearchToken || !isPhotoSearchVisible() || result == null) return@post
                                val (found, terms, note) = result
                                if (terms.isNotEmpty() && found.isNotEmpty()) {
                                    photoMatches = found
                                    photoDetected = terms.joinToString(", ")
                                    photoAnalysisNote = note +
                                        " Результаты сопоставлены со всем импортированным каталогом ОМА."
                                    photoMatchLabel = "Релевантность"
                                    photoBusy = false; photoError = ""
                                    navigate("shop:photo")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /** Reduce camera files before upload; preserve correct image orientation. */
    private fun preparePhotoUpload(uri: Uri): ByteArray {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        activity.contentResolver.openInputStream(uri)?.use {
            BitmapFactory.decodeStream(it, null, bounds)
        } ?: error("Не удалось открыть фотографию")
        require(bounds.outWidth > 0 && bounds.outHeight > 0) { "Неверный формат изображения" }
        var sample = 1
        while (maxOf(bounds.outWidth, bounds.outHeight) / sample > 1280) sample *= 2
        val opts = BitmapFactory.Options().apply { inSampleSize = sample }
        val source = activity.contentResolver.openInputStream(uri)?.use {
            BitmapFactory.decodeStream(it, null, opts)
        } ?: error("Не удалось прочитать фотографию")
        try {
            val orientation = runCatching {
                activity.contentResolver.openInputStream(uri)?.use {
                    android.media.ExifInterface(it).getAttributeInt(
                        android.media.ExifInterface.TAG_ORIENTATION,
                        android.media.ExifInterface.ORIENTATION_NORMAL
                    )
                }
            }.getOrNull()
            val degrees = when (orientation) {
                android.media.ExifInterface.ORIENTATION_ROTATE_90 -> 90f
                android.media.ExifInterface.ORIENTATION_ROTATE_180 -> 180f
                android.media.ExifInterface.ORIENTATION_ROTATE_270 -> 270f
                else -> 0f
            }
            val rotated = if (degrees == 0f) source else {
                val matrix = android.graphics.Matrix().apply { postRotate(degrees) }
                Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
            }
            try {
                val output = ByteArrayOutputStream()
                check(rotated.compress(Bitmap.CompressFormat.JPEG, 82, output)) {
                    "Не удалось подготовить фотографию"
                }
                return output.toByteArray()
            } finally {
                if (rotated !== source) rotated.recycle()
            }
        } finally {
            source.recycle()
        }
    }

    private fun normalizedObjectTerms(label: String): List<String> {
        val labelText = label.lowercase(Locale.ROOT).trim()
        if (labelText.isBlank()) return emptyList()
        // ML Kit uses English labels; map common DIY subjects to Russian catalog names.
        val dictionary = listOf(
            "drill" to listOf("дрель", "шуруповерт"), "power tool" to listOf("электроинструмент"),
            "hammer" to listOf("молоток"), "screw" to listOf("шуруп", "саморез"),
            "tool" to listOf("инструмент"), "faucet" to listOf("смеситель"),
            "tap" to listOf("смеситель"), "sink" to listOf("раковина", "мойка"),
            "bathtub" to listOf("ванна"), "toilet" to listOf("унитаз"),
            "lamp" to listOf("светильник", "лампа"), "light fixture" to listOf("светильник"),
            "bulb" to listOf("лампа", "лампочка"), "paint brush" to listOf("кисть"),
            "paint" to listOf("краска"), "bucket" to listOf("ведро"),
            "roller" to listOf("валик"), "tile" to listOf("плитка"),
            "wallpaper" to listOf("обои"), "floor" to listOf("ламинат", "покрытие"),
            "chair" to listOf("стул", "кресло"), "table" to listOf("стол"),
            "cabinet" to listOf("шкаф", "тумба"), "shelf" to listOf("полка"),
            "door" to listOf("дверь"), "window" to listOf("окно"),
            "plant" to listOf("растение"), "flower pot" to listOf("горшок"),
            "pipe" to listOf("труба"), "cable" to listOf("кабель"),
            "lawn" to listOf("газон"), "garden" to listOf("сад"),
            "ladder" to listOf("лестница"), "saw" to listOf("пила"),
            "glove" to listOf("перчатки"), "broom" to listOf("веник", "щетка")
        )
        val translated = dictionary.filter { labelText.contains(it.first) }.flatMap { it.second }
        return if (translated.isNotEmpty()) translated.distinct()
            else if (labelText.any { it in 'а'..'я' || it == 'ё' }) listOf(labelText)
            else emptyList()
    }

    /** Matching is done on a worker to keep scrolling responsive with 134k rows. */
    private fun searchLocalTerms(terms: List<String>): List<Pair<Item, Int>> {
        val phrases = terms.map { it.trim().lowercase(Locale.ROOT) }
            .filter { it.length >= 3 }.distinct().take(12)
        if (phrases.isEmpty()) return emptyList()
        val scored = products.asSequence().mapNotNull { item ->
            val title = item.title.lowercase(Locale.ROOT)
            val subcategory = item.subcategory.lowercase(Locale.ROOT)
            val category = item.category.lowercase(Locale.ROOT)
            val brand = item.brand.lowercase(Locale.ROOT)
            var score = 0
            for (phrase in phrases) {
                val tokens = phrase.split(Regex("[^а-яёa-z0-9]+")).filter { it.length >= 3 }
                for (token in tokens) {
                    val stem = if (token.length >= 7) token.dropLast(2) else token
                    score += when {
                        title.contains(stem) -> 12
                        subcategory.contains(stem) -> 7
                        category.contains(stem) -> 4
                        brand.contains(stem) -> 2
                        else -> 0
                    }
                }
            }
            if (score == 0) null else item to score
        }.sortedByDescending { it.second }.take(20).toList()
        return scored.map { it.first to it.second.coerceAtMost(100) }
    }

    private data class RemotePhotoResult(
        val items: List<Pair<Item, Int>>, val terms: List<String>, val note: String
    )

    private fun parseRemoteMatches(raw: String): RemotePhotoResult {
        val response = JSONObject(raw)
        val detected = response.optJSONArray("detected_objects") ?: JSONArray()
        val terms = (0 until detected.length()).map { detected.optString(it) }
            .filter { it.isNotBlank() }.take(5)
        // Server may host a small demo catalog. Its SKUs are not a full OMA index.
        return RemotePhotoResult(
            if (terms.isNotEmpty()) searchLocalTerms(terms) else emptyList(),
            terms,
            response.optString("note", "Сервер распознал предметы на фотографии.")
        )
    }

    private fun analyzePhotoOnDevice(uri: Uri, requestId: Int) {
        val input = runCatching { InputImage.fromFilePath(activity, uri) }
            .getOrElse {
                showPhotoFallback(requestId, "Не удалось открыть фото для распознавания")
                return
            }
        val labeler = ImageLabeling.getClient(
            ImageLabelerOptions.Builder().setConfidenceThreshold(0.35f).build()
        )
        labeler.process(input).addOnSuccessListener { labels ->
            val recognized = labels.sortedByDescending { it.confidence }.take(5)
            val terms = recognized.flatMap { normalizedObjectTerms(it.text) }.distinct()
            pool.execute {
                val results = searchLocalTerms(terms)
                ui.post {
                    if (requestId != photoSearchToken || !isPhotoSearchVisible()) return@post
                    photoMatches = results
                    photoDetected = recognized.joinToString(", ") { it.text }
                    photoBusy = false
                    photoError = ""
                    photoMatchLabel = "Релевантность"
                    photoAnalysisNote = if (results.isNotEmpty())
                        "Предметы распознаны на телефоне. Поиск выполнен по всему каталогу ОМА. Это возможные совпадения, не подтверждение артикула."
                    else "Не удалось уверенно подобрать товар автоматически. Укажите название предмета ниже."
                    navigate("shop:photo")
                }
            }
        }.addOnFailureListener {
            showPhotoFallback(requestId, "Распознавание на телефоне недоступно")
        }.addOnCompleteListener {
            labeler.close()
        }
    }

    private fun showPhotoFallback(requestId: Int, message: String) {
        ui.post {
            if (requestId != photoSearchToken || !isPhotoSearchVisible()) return@post
            photoBusy = false
            photoError = ""
            photoMatches = emptyList()
            photoAnalysisNote = "$message. Можно найти товар по названию в полном каталоге."
            navigate("shop:photo")
        }
    }

    private fun searchPhotoByText(query: String) {
        val terms = listOf(query.trim()).filter { it.isNotBlank() }
        if (terms.isEmpty()) return
        val requestId = ++photoSearchToken
        photoBusy = true
        navigate("shop:photo")
        pool.execute {
            val found = searchLocalTerms(terms)
            ui.post {
                if (requestId != photoSearchToken || !isPhotoSearchVisible()) return@post
                photoMatches = found
                photoDetected = query
                photoBusy = false; photoError = ""
                photoAnalysisNote = "Поиск по уточнённому названию среди всех товаров импортированного каталога."
                photoMatchLabel = "Релевантность"
                navigate("shop:photo")
            }
        }
    }

    private fun photoSearchScreen(body:LinearLayout){
        val preview=ImageView(activity).apply{
            scaleType=ImageView.ScaleType.CENTER_CROP;setBackgroundColor(Color.WHITE)
            photoUri?.let { uri ->
                // Decode a thumbnail in the background instead of a full camera image on UI.
                tag = uri.toString()
                pool.execute {
                    val bitmap = runCatching {
                        val options = BitmapFactory.Options().apply { inSampleSize = 4 }
                        activity.contentResolver.openInputStream(uri)?.use {
                            BitmapFactory.decodeStream(it, null, options)
                        }
                    }.getOrNull()
                    if (bitmap != null) ui.post {
                        if (tag == uri.toString() && !activity.isFinishing) setImageBitmap(bitmap)
                        else bitmap.recycle()
                    }
                }
            }
        }
        body.addView(preview,LinearLayout.LayoutParams(-1,dp(210)).apply{leftMargin=dp(16);rightMargin=dp(16);topMargin=dp(14)})
        body.addView(text("Изображение может отправляться на настроенный демосервер ОМА для уточнения распознавания. Если сервер недоступен, используется анализ на телефоне.", 12f, false, Color.GRAY).apply { setPadding(dp(16),dp(10),dp(16),dp(4)) })
        val hint = EditText(activity).apply {
            setSingleLine(true)
            setTextColor(ink);textSize = 15f
            this.hint = "Что изображено на фото? Например, дрель"
            setPadding(dp(12), 0, dp(12), 0)
            background = rounded(Color.WHITE, 8)
        }
        body.addView(hint, LinearLayout.LayoutParams(-1,dp(50)).apply {
            leftMargin=dp(16);rightMargin=dp(16);topMargin=dp(12)
        })
        body.addView(outlineButton("Уточнить и найти во всём каталоге", {
            val entered = hint.text.toString().trim()
            if (entered.isNotBlank()) searchPhotoByText(entered)
        }),LinearLayout.LayoutParams(-1,dp(46)).apply {
            leftMargin=dp(16);rightMargin=dp(16);topMargin=dp(6);bottomMargin=dp(10)
        })
        when{
            photoBusy->{sectionTitle(body,"Анализируем изображение…");body.addView(ProgressBar(activity).apply{isIndeterminate=true})}
            photoError.isNotBlank()->{
                sectionTitle(body,"Не удалось выполнить поиск")
                body.addView(text(photoError,14f,false,Color.GRAY).apply{setPadding(dp(16),0,dp(16),dp(14))})
                body.addView(outlineButton("Выбрать другое фото",{pickPhoto()}),LinearLayout.LayoutParams(-1,dp(48)).apply{leftMargin=dp(16);rightMargin=dp(16)})
            }
            else->{
                sectionTitle(body,"Похожие товары · ${photoMatches.size}")
                if(photoDetected.isNotBlank())body.addView(text("Распознано: $photoDetected",13f,true,ink).apply{setPadding(dp(16),0,dp(16),dp(6))})
                val explanation=photoAnalysisNote.ifBlank{"Процент показывает визуальную и смысловую близость, а не гарантию совпадения артикула."}
                body.addView(text(explanation,12.5f,false,Color.GRAY).apply{setPadding(dp(16),0,dp(16),dp(12))})
                photoMatches.forEach{(item,score)->
                    val card=horizontal().apply{setPadding(dp(12),dp(8),dp(12),dp(8));setBackgroundColor(Color.WHITE);setOnClickListener{openProduct(item.id)}}
                    card.addView(photo(item,84),LinearLayout.LayoutParams(dp(84),dp(84)))
                    val labels=vertical().apply{addView(text(item.title,14f,true).apply{maxLines=2});addView(text("Визуальное сходство: $score%",12.5f,false,blue));addView(text(price(item.price),14f,true))}
                    card.addView(labels,LinearLayout.LayoutParams(0,dp(84),1f).apply{leftMargin=dp(12)})
                    body.addView(card,LinearLayout.LayoutParams(-1,dp(101)).apply{leftMargin=dp(12);rightMargin=dp(12);bottomMargin=dp(5)})
                }
            }
        }
    }

    private fun loadProductBitmap(item:Item):Bitmap?{
        synchronized(imageCache){imageCache.get(item.image)}?.let{return it}
        return if(item.image.startsWith("http")){
            URL(item.image).openConnection().apply{connectTimeout=5000;readTimeout=7000}.getInputStream().use{BitmapFactory.decodeStream(it)}
        }else BitmapFactory.decodeFile(item.image)
    }

    private fun descriptor(bitmap:Bitmap):FloatArray{
        val small=Bitmap.createScaledBitmap(bitmap,48,48,true)
        val bins=FloatArray(12);var saturation=0f;var brightness=0f;var edges=0f
        val hsv=FloatArray(3);var previous=0f
        for(y in 0 until 48)for(x in 0 until 48){
            val color=small.getPixel(x,y);Color.colorToHSV(color,hsv)
            bins[(hsv[0]/30f).toInt().coerceIn(0,11)]++
            saturation+=hsv[1];brightness+=hsv[2]
            val lum=(Color.red(color)*.299f+Color.green(color)*.587f+Color.blue(color)*.114f)/255f
            if(x>0)edges+=abs(lum-previous);previous=lum
        }
        val n=48f*48f
        for(i in bins.indices)bins[i]/=n
        return bins+floatArrayOf(saturation/n,brightness/n,edges/n)
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
            val purchasedAt=System.currentTimeMillis()
            val lines=JSONArray()
            cart().forEach { (id, quantity) ->
                product(id)?.let { p ->
                    lines.put(JSONObject().put("sku",p.id).put("title",p.title)
                        .put("quantity",quantity).put("unit",p.unit).put("price",p.price)
                        .put("brand",p.brand).put("category",p.category)
                        .put("subcategory",p.subcategory).put("date",purchasedAt))
                }
            }
            record.put(JSONObject().put("sum",total()).put("date",purchasedAt).put("items",lines))
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

    /** Snapshots from orders confirmed inside this demo, never from the official OMA account. */
    fun confirmedPurchases():JSONArray {
        val result=JSONArray()
        val orders=runCatching { JSONArray(prefs.getString("demo_orders","[]")) }.getOrDefault(JSONArray())
        for(i in 0 until orders.length()) {
            val order=orders.optJSONObject(i)?:continue
            val items=order.optJSONArray("items")?:continue
            for(j in 0 until items.length()) items.optJSONObject(j)?.let { item ->
                if(!item.has("date")) item.put("date",order.optLong("date"))
                item.put("demo_order",i+1)
                result.put(item)
            }
        }
        return result
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
        val directory = File(activity.filesDir, "oma_catalog")
        if (!File(directory, "catalog.db").isFile) return
        // Large catalogs must never block Android's main thread during app launch.
        catalogLoading = true
        pool.execute {
            val saved = runCatching { loadDatabase(directory) }.getOrNull()
            ui.post {
                if (!saved.isNullOrEmpty()) products = saved
                catalogLoading = false
                if (!activity.isFinishing && !activity.isDestroyed) refresh()
            }
        }
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
