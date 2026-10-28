package by.oma.companion

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.text.InputType
import android.view.Gravity
import android.view.View
import android.widget.*
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID

/** Local digital-home demo. It never reads the real OMA account or purchase history. */
class HomeHub(
    private val activity: Activity,
    private val navigate: (String) -> Unit,
    private val purchases: () -> JSONArray
) {
    companion object { const val SAVE_PDF_REQUEST = 8821 }

    private val blue = Style.BLUE
    private val ink = Color.rgb(43, 58, 70)
    private val line = Color.rgb(224, 229, 233)
    private val prefs = activity.getSharedPreferences("oma_home_hub", Activity.MODE_PRIVATE)
    private val dateFormat = SimpleDateFormat("dd.MM.yyyy", Locale("ru", "RU"))
    private var currentPdf: File? = null
    private var renderer: PdfRenderer? = null
    private var descriptor: ParcelFileDescriptor? = null
    private var pageIndex = 0
    private var zoom = 1f

    private data class Room(
        val name: String, val area: Double, val width: Double = 0.0,
        val length: Double = 0.0, val height: Double = 2.7,
        val doorWall: String = "Левая", val windowWall: String = "Задняя"
    )
    private data class Home(
        val id: String,
        val type: String,
        val name: String,
        val address: String,
        val area: Double,
        val floor: String,
        val floors: String,
        val year: String,
        val bathroom: String,
        val heating: String,
        val walls: String,
        val ceiling: String,
        val features: String,
        val rooms: List<Room>
    )

    private fun dp(n: Int) = Style.dp(activity, n)
    private fun text(value: String, size: Float = 15f, bold: Boolean = false, color: Int = ink) =
        TextView(activity).apply {
            text = value; textSize = size; setTextColor(color)
            gravity = Gravity.CENTER_VERTICAL
            if (bold) setTypeface(null, Typeface.BOLD)
        }
    private fun divider(body: LinearLayout) = body.addView(View(activity).apply {
        setBackgroundColor(line)
    }, LinearLayout.LayoutParams(-1, dp(1)))
    private fun heading(body: LinearLayout, value: String) {
        body.addView(text(value, 21f, true).apply { setPadding(dp(17), dp(22), dp(15), dp(13)) })
    }
    private fun note(body: LinearLayout, value: String) {
        body.addView(text(value, 13f, false, Color.rgb(99, 112, 122)).apply {
            setPadding(dp(17), dp(8), dp(17), dp(14))
        })
    }
    private fun button(body: LinearLayout, value: String, filled: Boolean = true, action: () -> Unit) {
        val view = text(value, 15f, true, if (filled) Color.WHITE else blue).apply {
            gravity = Gravity.CENTER
            background = Style.bg(if (filled) blue else Color.WHITE, 8f, if (filled) blue else line)
            isClickable = true
            setOnClickListener { action() }
        }
        body.addView(view, LinearLayout.LayoutParams(-1, dp(50)).apply {
            leftMargin = dp(16); rightMargin = dp(16); topMargin = dp(7); bottomMargin = dp(7)
        })
    }
    private fun field(body: LinearLayout, caption: String, hint: String = "", numeric: Boolean = false): EditText {
        body.addView(text(caption, 13.5f, true).apply { setPadding(dp(18), dp(9), dp(18), dp(5)) })
        return EditText(activity).apply {
            this.hint = hint; textSize = 15f; setSingleLine(true)
            inputType = if (numeric) InputType.TYPE_CLASS_NUMBER or InputType.TYPE_NUMBER_FLAG_DECIMAL
                else InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
            background = Style.bg(Color.WHITE, 7f, line)
            setPadding(dp(13), 0, dp(13), 0)
            body.addView(this, LinearLayout.LayoutParams(-1, dp(50)).apply {
                leftMargin = dp(16); rightMargin = dp(16); bottomMargin = dp(5)
            })
        }
    }

    private fun homes(): MutableList<Home> {
        val result = mutableListOf<Home>()
        val source = runCatching { JSONArray(prefs.getString("homes", "[]")) }.getOrDefault(JSONArray())
        for (i in 0 until source.length()) {
            val o = source.optJSONObject(i) ?: continue
            val rooms = mutableListOf<Room>()
            val array = o.optJSONArray("rooms") ?: JSONArray()
            for (r in 0 until array.length()) {
                val room = array.optJSONObject(r) ?: continue
                rooms += Room(room.optString("name"), room.optDouble("area"),
                    room.optDouble("width"), room.optDouble("length"),
                    room.optDouble("height", 2.7), room.optString("doorWall", "Левая"),
                    room.optString("windowWall", "Задняя"))
            }
            result += Home(
                o.optString("id"), o.optString("type"), o.optString("name"),
                o.optString("address"), o.optDouble("area"), o.optString("floor"),
                o.optString("floors"), o.optString("year"), o.optString("bathroom"),
                o.optString("heating"), o.optString("walls"), o.optString("ceiling"),
                o.optString("features"), rooms
            )
        }
        return result
    }
    private fun saveHomes(items: List<Home>) {
        val array = JSONArray()
        items.forEach { h ->
            val rooms = JSONArray()
            h.rooms.forEach { rooms.put(JSONObject().put("name", it.name).put("area", it.area)
                .put("width", it.width).put("length", it.length).put("height", it.height)
                .put("doorWall", it.doorWall).put("windowWall", it.windowWall)) }
            array.put(JSONObject().put("id", h.id).put("type", h.type).put("name", h.name)
                .put("address", h.address).put("area", h.area).put("floor", h.floor)
                .put("floors", h.floors).put("year", h.year).put("bathroom", h.bathroom)
                .put("heating", h.heating).put("walls", h.walls).put("ceiling", h.ceiling)
                .put("features", h.features).put("rooms", rooms))
        }
        prefs.edit().putString("homes", array.toString()).apply()
    }
    private fun selectedHome(): Home? {
        val list = homes()
        if (list.isEmpty()) return null
        val id = prefs.getString("selected_home", "")
        return list.firstOrNull { it.id == id } ?: list.first().also {
            prefs.edit().putString("selected_home", it.id).apply()
        }
    }

    fun title(screen: String): String = when (screen) {
        "home:add" -> "Добавить объект"
        "home:passport" -> "Паспорт объекта"
        "home:preview" -> "Просмотр PDF"
        "home:3d" -> "3D-модель дома"
        else -> "Цифровой дом"
    }

    fun render(screen: String, body: LinearLayout) {
        if (screen != "home:preview") closePreview()
        when (screen) {
            "home:add" -> createHome(body)
            "home:passport" -> passport(body)
            "home:preview" -> preview(body)
            "home:3d" -> placeholder3d(body)
            else -> hub(body)
        }
    }

    private fun hub(body: LinearLayout) {
        heading(body, "Мои объекты")
        button(body, "+  Добавить квартиру или дом", false) { navigate("home:add") }
        val items = homes()
        if (items.isEmpty()) {
            note(body, "Объектов пока нет. Создайте квартиру или дом, чтобы сформировать паспорт.")
            return
        }
        val current = selectedHome()!!
        val spinner = Spinner(activity)
        spinner.adapter = ArrayAdapter(activity, android.R.layout.simple_spinner_dropdown_item,
            items.map { it.name + " · " + if (it.type == "apartment") "квартира" else "дом" })
        spinner.setSelection(items.indexOfFirst { it.id == current.id }.coerceAtLeast(0))
        spinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onNothingSelected(parent: AdapterView<*>?) = Unit
            override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                prefs.edit().putString("selected_home", items[position].id).apply()
            }
        }
        body.addView(spinner, LinearLayout.LayoutParams(-1, dp(58)).apply {
            leftMargin = dp(16); rightMargin = dp(16); bottomMargin = dp(10)
        })
        note(body, "Выберите объект, затем нужную функцию.")
        functionRow(body, "Паспорт дома", "Данные, помещения, покупки и PDF") { navigate("home:passport") }
        functionRow(body, "3D-модель дома", "Пространственная модель выбранного объекта") { navigate("home:3d") }
        functionRow(body, "Знающий мастер", "Подбор мастера и заявка на работы") { navigate("master") }
    }

    private fun functionRow(body: LinearLayout, name: String, subtitle: String, action: () -> Unit) {
        val row = LinearLayout(activity).apply {
            orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(17), dp(9), dp(13), dp(9)); setBackgroundColor(Color.WHITE)
            setOnClickListener { action() }
        }
        val labels = LinearLayout(activity).apply { orientation = LinearLayout.VERTICAL }
        labels.addView(text(name, 16.5f, true))
        labels.addView(text(subtitle, 12.5f, false, Color.GRAY))
        row.addView(labels, LinearLayout.LayoutParams(0, dp(62), 1f))
        row.addView(text("›", 27f, false, blue).apply { gravity = Gravity.CENTER },
            LinearLayout.LayoutParams(dp(28), dp(62)))
        body.addView(row, LinearLayout.LayoutParams(-1, dp(80)).apply {
            leftMargin = dp(14); rightMargin = dp(14); topMargin = dp(4); bottomMargin = dp(4)
        })
    }

    private fun createHome(body: LinearLayout) {
        heading(body, "Основные данные")
        body.addView(text("Тип объекта", 13.5f, true).apply { setPadding(dp(18), dp(7), dp(18), dp(5)) })
        val type = Spinner(activity).apply {
            adapter = ArrayAdapter(activity, android.R.layout.simple_spinner_dropdown_item,
                listOf("Квартира", "Частный дом"))
        }
        body.addView(type, LinearLayout.LayoutParams(-1, dp(52)).apply { leftMargin=dp(16);rightMargin=dp(16) })
        val name = field(body, "Название", "Например, Квартира на Победителей")
        val address = field(body, "Адрес", "Город, улица, дом")
        val area = field(body, "Общая площадь, м²", "65.4", true)
        val floor = field(body, "Этаж", "5", true)
        val floors = field(body, "Этажей в доме", "9", true)
        val year = field(body, "Год постройки", "2018", true)
        val ceiling = field(body, "Высота потолков, м", "2.7", true)
        val bathroom = choice(body, "Санузел", listOf("Совмещённый", "Раздельный", "Несколько санузлов", "Не указан"))
        val heating = choice(body, "Отопление", listOf("Центральное", "Газовое", "Электрическое", "Другое"))
        val walls = choice(body, "Материал стен", listOf("Кирпич", "Панель", "Блок", "Дерево", "Другое"))
        val features = field(body, "Особенности", "Балкон, тёплый пол, кладовая…")

        heading(body, "Помещения и площади")
        note(body, "Отметьте помещения, которые есть в объекте, и при необходимости укажите их площадь.")
        data class RoomInput(val name:String,val check:CheckBox,val area:EditText,val width:EditText,
            val length:EditText,val height:EditText,val door:Spinner,val window:Spinner)
        val roomInputs = mutableListOf<RoomInput>()
        listOf("Кухня", "Коридор", "Ванная", "Туалет", "Гостиная", "Спальня 1",
            "Спальня 2", "Детская", "Кабинет", "Кладовая", "Балкон").forEach { roomName ->
            val card = LinearLayout(activity).apply {
                orientation = LinearLayout.VERTICAL; setPadding(dp(14), dp(5), dp(14), dp(8))
                background=Style.bg(Color.WHITE,7f,line)
            }
            val check = CheckBox(activity).apply { text = roomName; textSize = 14.5f }
            val roomArea = EditText(activity).apply {
                hint = "Площадь, м²"; textSize = 13f; setSingleLine(true)
                inputType = InputType.TYPE_CLASS_NUMBER or InputType.TYPE_NUMBER_FLAG_DECIMAL
            }
            card.addView(check,LinearLayout.LayoutParams(-1,dp(43)))
            val dimensions=LinearLayout(activity).apply{orientation=LinearLayout.HORIZONTAL}
            fun number(hint:String,default:String="")=EditText(activity).apply{
                this.hint=hint;setText(default);textSize=12.5f;setSingleLine(true)
                inputType=InputType.TYPE_CLASS_NUMBER or InputType.TYPE_NUMBER_FLAG_DECIMAL
            }
            val width=number("Ширина, м");val length=number("Длина, м");val height=number("Высота, м","2.7")
            listOf(roomArea,width,length,height).forEach{dimensions.addView(it,LinearLayout.LayoutParams(0,dp(47),1f).apply{rightMargin=dp(4)})}
            card.addView(dimensions)
            val openings=LinearLayout(activity).apply{orientation=LinearLayout.HORIZONTAL}
            val walls=listOf("Нет","Левая","Задняя","Правая","Передняя")
            val door=Spinner(activity).apply{adapter=ArrayAdapter(activity,android.R.layout.simple_spinner_dropdown_item,walls);setSelection(1)}
            val window=Spinner(activity).apply{adapter=ArrayAdapter(activity,android.R.layout.simple_spinner_dropdown_item,walls);setSelection(2)}
            openings.addView(LinearLayout(activity).apply{orientation=LinearLayout.VERTICAL;addView(text("Дверь",11.5f,true));addView(door)},LinearLayout.LayoutParams(0,dp(68),1f))
            openings.addView(LinearLayout(activity).apply{orientation=LinearLayout.VERTICAL;addView(text("Окно",11.5f,true));addView(window)},LinearLayout.LayoutParams(0,dp(68),1f))
            card.addView(openings)
            body.addView(card,LinearLayout.LayoutParams(-1,-2).apply{leftMargin=dp(14);rightMargin=dp(14);bottomMargin=dp(8)})
            roomInputs += RoomInput(roomName,check,roomArea,width,length,height,door,window)
        }
        button(body, "Создать объект") {
            val totalArea = area.text.toString().replace(',', '.').toDoubleOrNull()
            if (name.text.toString().trim().length < 2) { name.error = "Укажите название"; return@button }
            if (totalArea == null || totalArea <= 0) { area.error = "Укажите площадь"; return@button }
            val rooms = roomInputs.filter { it.check.isChecked }.map {
                val w=it.width.text.toString().replace(',','.').toDoubleOrNull()?:0.0
                val l=it.length.text.toString().replace(',','.').toDoubleOrNull()?:0.0
                val entered=it.area.text.toString().replace(',', '.').toDoubleOrNull() ?: 0.0
                Room(it.name, if(entered>0)entered else w*l, w, l,
                    it.height.text.toString().replace(',','.').toDoubleOrNull()?:2.7,
                    it.door.selectedItem.toString(),it.window.selectedItem.toString())
            }
            if (rooms.isEmpty()) { Toast.makeText(activity, "Выберите хотя бы одно помещение", Toast.LENGTH_LONG).show(); return@button }
            val home = Home(UUID.randomUUID().toString(), if (type.selectedItemPosition == 0) "apartment" else "house",
                name.text.toString().trim(), address.text.toString().trim(), totalArea,
                floor.text.toString().trim(), floors.text.toString().trim(), year.text.toString().trim(),
                bathroom.selectedItem.toString(), heating.selectedItem.toString(), walls.selectedItem.toString(),
                ceiling.text.toString().trim(), features.text.toString().trim(), rooms)
            val all = homes(); all += home; saveHomes(all)
            prefs.edit().putString("selected_home", home.id).apply()
            Toast.makeText(activity, "Объект создан", Toast.LENGTH_SHORT).show()
            navigate("home:hub")
        }
    }

    private fun choice(body: LinearLayout, caption: String, variants: List<String>): Spinner {
        body.addView(text(caption, 13.5f, true).apply { setPadding(dp(18), dp(9), dp(18), dp(4)) })
        return Spinner(activity).apply {
            adapter = ArrayAdapter(activity, android.R.layout.simple_spinner_dropdown_item, variants)
            body.addView(this, LinearLayout.LayoutParams(-1, dp(52)).apply { leftMargin=dp(16);rightMargin=dp(16) })
        }
    }

    private fun passport(body: LinearLayout) {
        val home = selectedHome()
        if (home == null) {
            heading(body, "Паспорт объекта")
            note(body, "Сначала создайте квартиру или дом.")
            button(body, "Добавить объект") { navigate("home:add") }
            return
        }
        heading(body, home.name)
        info(body, "Тип", if (home.type == "apartment") "Квартира" else "Частный дом")
        info(body, "Адрес", home.address.ifBlank { "Не указан" })
        info(body, "Общая площадь", formatArea(home.area))
        info(body, "Этаж", home.floor.ifBlank { "Не указан" })
        info(body, "Этажность", home.floors.ifBlank { "Не указана" })
        info(body, "Год постройки", home.year.ifBlank { "Не указан" })
        info(body, "Санузел", home.bathroom)
        info(body, "Отопление", home.heating)
        info(body, "Материал стен", home.walls)
        info(body, "Высота потолков", home.ceiling.ifBlank { "Не указана" })
        info(body, "Особенности", home.features.ifBlank { "Нет данных" })
        heading(body, "Помещения")
        home.rooms.forEach { room ->
            val geometry=if(room.width>0&&room.length>0) " · ${room.width} × ${room.length} × ${room.height} м" else " · размеры не указаны"
            info(body, room.name, (if (room.area > 0) formatArea(room.area) else "Площадь не указана")+geometry)
            info(body,"Проёмы", "дверь: ${room.doorWall.lowercase()}, окно: ${room.windowWall.lowercase()}")
        }

        heading(body, "Товары из демопокупок ОМА")
        val bought = purchases()
        if (bought.length() == 0) {
            note(body, "Подтверждённых демопокупок пока нет. Реальная история заказов ОМА к приложению не подключена.")
        } else {
            val locations = locations()
            for (i in 0 until bought.length()) {
                val item = bought.optJSONObject(i) ?: continue
                val key = purchaseKey(home, item)
                val card = LinearLayout(activity).apply {
                    orientation = LinearLayout.VERTICAL; setPadding(dp(16), dp(10), dp(16), dp(10)); setBackgroundColor(Color.WHITE)
                }
                card.addView(text(item.optString("title", "Товар"), 14.5f, true))
                card.addView(text("Артикул: ${item.optString("sku")} · Количество: ${item.optInt("quantity", 1)}", 12.5f, false, Color.GRAY))
                card.addView(text("Покупка: ${dateFormat.format(Date(item.optLong("date")))} · Гарантия/обслуживание: нет данных", 12.5f, false, Color.GRAY))
                val place = Spinner(activity).apply {
                    adapter = ArrayAdapter(activity, android.R.layout.simple_spinner_dropdown_item,
                        listOf("Место не назначено") + home.rooms.map { it.name })
                    val saved = locations.optString(key)
                    setSelection((home.rooms.indexOfFirst { it.name == saved } + 1).coerceAtLeast(0))
                    onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
                        override fun onNothingSelected(parent: AdapterView<*>?) = Unit
                        override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                            if (position == 0) locations.remove(key) else locations.put(key, home.rooms[position - 1].name)
                            saveLocations(locations)
                        }
                    }
                }
                card.addView(place, LinearLayout.LayoutParams(-1, dp(48)))
                body.addView(card, LinearLayout.LayoutParams(-1, -2).apply {
                    leftMargin=dp(14);rightMargin=dp(14);topMargin=dp(4);bottomMargin=dp(4)
                })
            }
        }
        note(body, "Паспорт строится из локальных данных демоверсии. Неизвестные гарантийные и сервисные сроки не выдумываются.")
        // Both actions below use this exact file. Preview and export can never diverge.
        currentPdf = generatePdf(home)
        button(body, "Просмотреть паспорт PDF") {
            navigate("home:preview")
        }
        button(body, "Скачать этот же PDF", false) {
            requestSave(home)
        }
    }

    private fun info(body: LinearLayout, label: String, value: String) {
        val row = LinearLayout(activity).apply { orientation=LinearLayout.HORIZONTAL;setPadding(dp(17),dp(11),dp(17),dp(11)) }
        row.addView(text(label, 13.5f), LinearLayout.LayoutParams(0, -2, 1f))
        row.addView(text(value, 13.5f, true).apply { gravity=Gravity.END;maxLines=3 }, LinearLayout.LayoutParams(0, -2, 1f))
        body.addView(row); divider(body)
    }

    private fun placeholder3d(body: LinearLayout) {
        val home = selectedHome()
        heading(body, "3D-модель")
        if (home == null) {
            note(body, "Сначала добавьте объект.")
            button(body, "Добавить объект") { navigate("home:add") }
            return
        }
        note(body, "Объект «${home.name}». Выберите комнату слева. Вращение и наклон — одним пальцем, масштаб — двумя пальцами.")
        val shell=LinearLayout(activity).apply {orientation=LinearLayout.HORIZONTAL;setBackgroundColor(Color.WHITE)}
        val menu=LinearLayout(activity).apply {orientation=LinearLayout.VERTICAL;setBackgroundColor(Color.rgb(231,241,248))}
        val viewer=Room3DView(activity)
        val bought=purchases()
        val places=locations()
        fun productsIn(room:Room):List<Room3DView.Product>{
            val result=mutableListOf<Room3DView.Product>()
            for(i in 0 until bought.length()){
                val item=bought.optJSONObject(i)?:continue
                if(places.optString(purchaseKey(home,item))==room.name){
                    result+=Room3DView.Product(item.optString("title","Товар"),item.optInt("quantity",1),item.optString("sku"))
                }
            }
            return result
        }
        fun select(room:Room){
            viewer.roomName=room.name
            viewer.roomArea=room.area
            viewer.roomWidth=room.width
            viewer.roomLength=room.length
            viewer.roomHeight=room.height
            viewer.doorWall=room.doorWall
            viewer.windowWall=room.windowWall
            viewer.products=productsIn(room)
            for(i in 0 until menu.childCount){
                val child=menu.getChildAt(i) as? TextView ?: continue
                child.setTextColor(if(child.text==room.name)Color.WHITE else ink)
                child.setBackgroundColor(if(child.text==room.name)blue else Color.TRANSPARENT)
            }
        }
        home.rooms.forEach { room ->
            menu.addView(text(room.name,12.5f,true).apply {
                gravity=Gravity.CENTER;setPadding(dp(5),dp(7),dp(5),dp(7));setOnClickListener{select(room)}
            },LinearLayout.LayoutParams(-1,dp(58)))
        }
        val roomScroll=ScrollView(activity).apply {addView(menu,android.widget.FrameLayout.LayoutParams(-1,-2))}
        shell.addView(roomScroll,LinearLayout.LayoutParams(dp(105),dp(590)))
        shell.addView(viewer,LinearLayout.LayoutParams(0,dp(590),1f))
        body.addView(shell,LinearLayout.LayoutParams(-1,dp(590)).apply{leftMargin=dp(8);rightMargin=dp(8);bottomMargin=dp(14)})
        home.rooms.firstOrNull()?.let{select(it)}
        if(home.rooms.isEmpty()) note(body,"В паспорте нет помещений. Создайте объект заново с перечнем комнат.")
        note(body,"OpenGL-сцена использует ширину, длину, высоту и стены проёмов из паспорта. Если размеры не заполнены, пропорции вычисляются приближённо из площади. Точная сложная форма комнаты всё ещё требует обмерного плана.")
    }

    private fun locations(): JSONObject = runCatching {
        JSONObject(prefs.getString("locations", "{}") ?: "{}")
    }.getOrDefault(JSONObject())
    private fun saveLocations(value: JSONObject) = prefs.edit().putString("locations", value.toString()).apply()
    private fun purchaseKey(home: Home, item: JSONObject) = home.id + ":" + item.optString("sku") + ":" + item.optLong("date")
    private fun formatArea(value: Double) = String.format(Locale("ru", "RU"), "%.1f м²", value)

    private inner class PdfWriter(private val document: PdfDocument) {
        private val normal = Paint(Paint.ANTI_ALIAS_FLAG).apply { color=Color.rgb(35,45,54);textSize=12f }
        private val bold = Paint(normal).apply { typeface=Typeface.create(Typeface.DEFAULT, Typeface.BOLD) }
        private var page: PdfDocument.Page? = null
        private var canvas: android.graphics.Canvas? = null
        private var y = 0f
        private var number = 0
        init { newPage() }
        private fun newPage() {
            page?.let { document.finishPage(it) }
            number++
            page = document.startPage(PdfDocument.PageInfo.Builder(595, 842, number).create())
            canvas = page!!.canvas
            y = 48f
            canvas!!.drawText("ОМА · Паспорт объекта (демоверсия)", 42f, 28f, Paint(bold).apply {textSize=10f;color=blue})
        }
        fun line(value: String, isBold: Boolean = false, size: Float = 12f, gap: Float = 7f) {
            val paint = Paint(if (isBold) bold else normal).apply { textSize=size }
            val words = value.split(" ")
            var row = ""
            val rows = mutableListOf<String>()
            words.forEach { word ->
                val candidate = if (row.isBlank()) word else "$row $word"
                if (paint.measureText(candidate) > 510f && row.isNotBlank()) { rows += row; row = word } else row = candidate
            }
            if (row.isNotBlank()) rows += row
            rows.ifEmpty { listOf("") }.forEach { rendered ->
                if (y > 800f) newPage()
                canvas!!.drawText(rendered, 42f, y, paint); y += size + 5f
            }
            y += gap
        }
        fun section(value: String) { y += 7f; line(value, true, 16f, 8f) }
        fun finish() { page?.let { document.finishPage(it) }; page=null }
    }

    private fun generatePdf(home: Home): File {
        val document = PdfDocument()
        val out = PdfWriter(document)
        out.line(home.name, true, 22f, 12f)
        out.line("Сформирован: ${dateFormat.format(Date())}", false, 10f, 12f)
        out.section("1. Данные объекта")
        out.line("Тип: ${if (home.type == "apartment") "квартира" else "частный дом"}")
        out.line("Адрес: ${home.address.ifBlank { "не указан" }}")
        out.line("Общая площадь: ${formatArea(home.area)}")
        out.line("Этаж: ${home.floor.ifBlank { "не указан" }}; этажность: ${home.floors.ifBlank { "не указана" }}")
        out.line("Год постройки: ${home.year.ifBlank { "не указан" }}")
        out.line("Санузел: ${home.bathroom}; отопление: ${home.heating}")
        out.line("Материал стен: ${home.walls}; высота потолков: ${home.ceiling.ifBlank { "не указана" }}")
        out.line("Особенности: ${home.features.ifBlank { "нет данных" }}")
        out.section("2. Помещения")
        home.rooms.forEachIndexed { index, room -> out.line("${index+1}. ${room.name} — ${if(room.area>0) formatArea(room.area) else "площадь не указана"}") }
        out.section("3. Подтверждённые демопокупки")
        val bought = purchases()
        val places = locations()
        if (bought.length() == 0) out.line("Покупок в демоверсии пока нет.")
        for (i in 0 until bought.length()) {
            val item = bought.optJSONObject(i) ?: continue
            val place = places.optString(purchaseKey(home, item), "не назначено")
            out.line("${i+1}. ${item.optString("title", "Товар")}", true)
            out.line("Артикул: ${item.optString("sku")}; количество: ${item.optInt("quantity",1)} ${item.optString("unit","шт")}; дата покупки: ${dateFormat.format(Date(item.optLong("date")))}")
            out.line("Размещение: $place; гарантия: не указана; обслуживание и ожидаемый срок службы: не указаны")
        }
        out.section("4. Примечание")
        out.line("Документ сформирован демонстрационным приложением. В него включены только подтверждённые покупки, оформленные внутри этой демоверсии. Доступа к реальной истории заказов официальной ОМА нет.")
        out.finish()
        val file = File(activity.cacheDir, "oma_passport_${home.id}.pdf")
        FileOutputStream(file).use { document.writeTo(it) }
        document.close()
        return file
    }

    private fun requestSave(home: Home) {
        val safe = home.name.replace(Regex("[^A-Za-zА-Яа-я0-9_-]+"), "_").take(45)
        activity.startActivityForResult(Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE); type="application/pdf"
            putExtra(Intent.EXTRA_TITLE, "Паспорт_${safe}.pdf")
        }, SAVE_PDF_REQUEST)
    }
    fun savePdf(uri: Uri): Boolean = runCatching {
        val file = currentPdf ?: error("PDF не сформирован")
        activity.contentResolver.openOutputStream(uri)?.use { output -> file.inputStream().use { it.copyTo(output) } }
            ?: error("Не удалось открыть файл")
    }.isSuccess

    private fun preview(body: LinearLayout) {
        val file = currentPdf
        if (file == null || !file.exists()) { note(body, "PDF не найден. Вернитесь в паспорт и сформируйте его заново.");return }
        closePreview()
        descriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
        renderer = PdfRenderer(descriptor!!)
        pageIndex = pageIndex.coerceIn(0, (renderer!!.pageCount - 1).coerceAtLeast(0))
        heading(body, "Паспорт объекта")
        val status = text("", 13f, true).apply { gravity=Gravity.CENTER }
        val image = ImageView(activity).apply { adjustViewBounds=true;scaleType=ImageView.ScaleType.FIT_CENTER;setBackgroundColor(Color.WHITE) }
        val horizontal = HorizontalScrollView(activity).apply { isFillViewport=false;addView(image) }
        fun drawPage() {
            val r = renderer ?: return
            val page = r.openPage(pageIndex)
            val width = (activity.resources.displayMetrics.widthPixels * zoom).toInt().coerceAtLeast(595)
            val height = (width * page.height.toFloat() / page.width).toInt()
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            bitmap.eraseColor(Color.WHITE)
            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
            page.close()
            image.setImageBitmap(bitmap)
            image.layoutParams = LinearLayout.LayoutParams(width, height)
            horizontal.layoutParams = LinearLayout.LayoutParams(-1, height).apply {
                leftMargin=dp(8);rightMargin=dp(8)
            }
            status.text = "Страница ${pageIndex+1} из ${r.pageCount} · ${String.format(Locale.US,"%.0f",zoom*100)}%"
        }
        val controls = LinearLayout(activity).apply { orientation=LinearLayout.HORIZONTAL;gravity=Gravity.CENTER }
        fun control(caption: String, action: () -> Unit) = text(caption, 14f, true, blue).apply {gravity=Gravity.CENTER;setOnClickListener{action()} }
        controls.addView(control("‹", { if(pageIndex>0){pageIndex--;drawPage()} }),LinearLayout.LayoutParams(0,dp(48),1f))
        controls.addView(control("−", { zoom=(zoom-.25f).coerceAtLeast(.75f);drawPage() }),LinearLayout.LayoutParams(0,dp(48),1f))
        controls.addView(status,LinearLayout.LayoutParams(0,dp(48),3f))
        controls.addView(control("+", { zoom=(zoom+.25f).coerceAtMost(2.5f);drawPage() }),LinearLayout.LayoutParams(0,dp(48),1f))
        controls.addView(control("›", { if(pageIndex<(renderer?.pageCount?:1)-1){pageIndex++;drawPage()} }),LinearLayout.LayoutParams(0,dp(48),1f))
        body.addView(controls)
        body.addView(horizontal,LinearLayout.LayoutParams(-1,-2).apply{leftMargin=dp(8);rightMargin=dp(8)})
        button(body, "Скачать этот PDF", false) { selectedHome()?.let { requestSave(it) } }
        drawPage()
    }

    fun closePreview() {
        runCatching { renderer?.close() }; renderer=null
        runCatching { descriptor?.close() }; descriptor=null
    }
}
