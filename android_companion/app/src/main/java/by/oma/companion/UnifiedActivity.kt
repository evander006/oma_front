package by.oma.companion

import android.app.Activity
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.text.InputType
import android.view.Gravity
import android.view.View
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.*
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

/** Unofficial hackathon demo; reproduces the profile layout but does not alter the OMA APK. */
class UnifiedActivity : Activity() {
    private val ink = Color.rgb(47, 58, 67)
    private val faint = Color.rgb(225, 225, 225)
    private val surface = Color.rgb(250, 250, 250)
    private val omaBlue = Color.rgb(0, 101, 174)
    private val selected = Color.rgb(187, 148, 74)
    private lateinit var api: Api
    private lateinit var body: LinearLayout
    private val prefs by lazy { getSharedPreferences("unified_profile_demo", MODE_PRIVATE) }
    private var tab = "Профиль"
    private var screen = ""
    private var authMode = "register"
    private var generation = 0
    private var contractorId = 0
    private var masterId = 0
    private var propertyId = 0
    private var query = ""
    private val pickPhoto = 182
    private var web: WebView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = Color.rgb(150,150,150)
        window.navigationBarColor = Color.WHITE
        window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
        api = Api(this)
        contractorId = prefs.getInt("contractor", 0)
        masterId = contractorId
        tab = savedInstanceState?.getString("tab") ?: "Профиль"
        screen = savedInstanceState?.getString("screen") ?: ""
        authMode = savedInstanceState?.getString("authMode")
            ?: if (prefs.contains("demo_auth_hash")) "login" else "register"
        render()
    }
    override fun onSaveInstanceState(out: Bundle) {
        out.putString("tab",tab); out.putString("screen",screen)
        out.putString("authMode", authMode)
        super.onSaveInstanceState(out)
    }
    override fun onDestroy() { web?.destroy(); api.close(); super.onDestroy() }
    private fun dp(n:Int):Int = Style.dp(this,n)
    private fun signedIn():Boolean = prefs.getBoolean("registered",false)
    private fun notice(s:String) { Toast.makeText(this,s,Toast.LENGTH_LONG).show() }
    private fun active(id:Int):Boolean = generation == id && !isFinishing
    private fun go(s:String) { screen=s; render() }
    private fun tabTo(s:String) { tab=s; screen=""; render() }
    @Deprecated("Deprecated in Android")
    override fun onBackPressed() {
        if (screen in listOf("3d","passport","master","smart")) go("digital")
        else if (screen == "masterMode") go("master")
        else if (screen != "") go("")
        else if (tab != "Профиль") tabTo("Профиль")
        else super.onBackPressed()
    }
    private fun label(text:String,size:Float=15.6f,bold:Boolean=false,color:Int=ink):TextView =
        TextView(this).apply {
            this.text=text; textSize=size; setTextColor(color)
            gravity=Gravity.CENTER_VERTICAL
            if (bold) setTypeface(null,android.graphics.Typeface.BOLD)
        }
    private fun icon(name:String,size:Int=28,color:Int=ink):View =
        LineIcon(this,name,color).apply { layoutParams=LinearLayout.LayoutParams(dp(size),dp(size)) }
    private fun divider(into:LinearLayout=body) {
        into.addView(View(this).apply { setBackgroundColor(faint) },
            LinearLayout.LayoutParams(-1,dp(1)).apply { leftMargin=dp(9);rightMargin=dp(9) })
    }
    private fun title(text:String) {
        val view=label(text,22f,true).apply { setPadding(dp(17),dp(12),dp(12),dp(7)) }
        body.addView(view,LinearLayout.LayoutParams(-1,dp(75)))
        divider()
    }
    private fun note(text:String) {
        val view=label(text,13f,false,Color.rgb(106,116,124)).apply {
            setPadding(dp(18),dp(10),dp(17),dp(10))
        }
        body.addView(view)
    }
    private fun row(text:String,glyph:String,onClick:()->Unit,arrow:Boolean=false) {
        val item=LinearLayout(this).apply {
            orientation=LinearLayout.HORIZONTAL;gravity=Gravity.CENTER_VERTICAL
            setBackgroundColor(surface); setPadding(dp(17),0,dp(17),0)
            isClickable=true; setOnClickListener { onClick() }
        }
        item.addView(icon(glyph,27),LinearLayout.LayoutParams(dp(27),dp(27)))
        item.addView(label(text),LinearLayout.LayoutParams(0,-1,1f).apply{leftMargin=dp(18)})
        if (arrow) item.addView(icon("chevron",17,Color.GRAY))
        body.addView(item,LinearLayout.LayoutParams(-1,dp(58)))
        divider()
    }
    private fun input(hint:String,value:String="",type:Int=InputType.TYPE_CLASS_TEXT):EditText {
        val edit=EditText(this).apply {
            this.hint=hint;setText(value);inputType=type;textSize=15f;setSingleLine(true)
        }
        body.addView(edit,LinearLayout.LayoutParams(-1,dp(51)).apply {
            leftMargin=dp(18);rightMargin=dp(18);bottomMargin=dp(8)
        })
        return edit
    }
    private fun button(text:String,click:()->Unit) {
        val view=label(text,15f,true,omaBlue).apply {
            setPadding(dp(18),dp(5),dp(12),dp(5))
            setOnClickListener {click()}
        }
        body.addView(view,LinearLayout.LayoutParams(-1,dp(52)))
        divider()
    }
    private fun holder():LinearLayout {
        return LinearLayout(this).apply {
            orientation=LinearLayout.VERTICAL
            body.addView(this,LinearLayout.LayoutParams(-1,-2))
        }
    }
    private fun message(target:LinearLayout,text:String) {
        target.removeAllViews()
        target.addView(label(text,14f).apply {setPadding(dp(17),dp(15),dp(12),dp(15))})
    }
    private fun render() {
        generation++
        web?.destroy();web=null
        val root=LinearLayout(this).apply {orientation=LinearLayout.VERTICAL;setBackgroundColor(surface)}
        val header=LinearLayout(this).apply {
            gravity=Gravity.CENTER_VERTICAL;setBackgroundColor(Color.WHITE)
            setPadding(dp(16),0,dp(16),0)
        }
        if (screen != "") header.addView(icon("back",24).apply {
            setOnClickListener {onBackPressed()}
        },LinearLayout.LayoutParams(dp(30),dp(32)).apply {rightMargin=dp(10)})
        val heading=when(screen) {
            "auth"->"Вход и регистрация";"digital"->"Цифровой дом"
            "3d"->"3D-модель";"passport"->"Паспорт жилья"
            "master"->"Мой мастер";"masterMode"->"Кабинет мастера"
            "smart"->"Умный поиск";"account"->"Моя информация"
            "orders"->"История заказов";"settings"->"Настройки"
            "info"->"Информация";else->tab
        }
        header.addView(label(heading,19.5f,true),LinearLayout.LayoutParams(0,-1,1f))
        root.addView(header,LinearLayout.LayoutParams(-1,dp(58)))
        divider(root)
        val scroller=ScrollView(this).apply {isFillViewport=true;setBackgroundColor(surface)}
        body=LinearLayout(this).apply {orientation=LinearLayout.VERTICAL}
        scroller.addView(body,android.widget.FrameLayout.LayoutParams(-1,-2))
        root.addView(scroller,LinearLayout.LayoutParams(-1,0,1f))
        divider(root)
        val bottom=LinearLayout(this).apply{setBackgroundColor(Color.WHITE);gravity=Gravity.CENTER}
        listOf(Pair("Главная","grid"),Pair("Каталог","search"),Pair("Корзина","bag"),
            Pair("Избранное","heart"),Pair("Профиль","profile")).forEach { (name,glyph) ->
            val col=LinearLayout(this).apply{orientation=LinearLayout.VERTICAL;gravity=Gravity.CENTER
                setOnClickListener {tabTo(name)}}
            val color=if (tab==name) selected else ink
            col.addView(icon(glyph,28,color))
            col.addView(label(name,10f,false,color).apply{gravity=Gravity.CENTER})
            bottom.addView(col,LinearLayout.LayoutParams(0,-1,1f))
        }
        root.addView(bottom,LinearLayout.LayoutParams(-1,dp(65)))
        setContentView(root)
        when(screen) {
            "auth"->auth()
            "digital"->digital()
            "3d"->property("3d")
            "passport"->property("passport")
            "master"->masters()
            "masterMode"->masterMode()
            "smart"->smart()
            "account","settings"->account()
            "orders"->orders()
            "info"-> {title("Информация");note("Оригинальные сервисы ОМА доступны только в официальном приложении. Здесь — демоверсия.") }
            else->when(tab) {
                "Профиль"->profile()
                "Главная"->home()
                "Каталог"->catalog()
                "Корзина"->cart()
                "Избранное"->favorites()
            }
        }
    }
    private fun profile() {
        title("Личный кабинет")
        if (signedIn()) row("Цифровой дом","home",{go("digital")})
        else row("Войти или зарегистрироваться","profile",{go("auth")})
        row("История уведомлений","bell",{go("info")})
        row("Настройки уведомлений","bell-settings",{go("info")})
        row("Купленные товары","bag",{go("orders")})
        row("История заказов","receipt",{go("orders")})
        row("История просмотров","history",{go("info")})
        row("Моя информация","contact",{go("account")})
        title("Помощь")
        row("Позвонить нам","phone",{go("info")})
        row("Возврат и гарантия","return",{go("info")})
        row("Договор публичной оферты","receipt",{go("info")})
        row("Адреса магазинов","store",{go("info")})
        row("Список сравнения","compare",{go("info")})
    }
    /**
     * Independent local demo sign-in. No OMA credentials, SMS, or external identity service.
     * Native widgets intentionally copy the existing OMA visual language: white inputs,
     * fine grey borders, blue primary CTA, restrained copy, no extra feature cards.
     */
    private fun auth() {
        title("Личный кабинет")
        val controls = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(dp(18), dp(17), dp(18), dp(15))
            setBackgroundColor(Color.WHITE)
        }
        listOf("login" to "Вход", "register" to "Регистрация").forEach { (key, text) ->
            val selectedTab = authMode == key
            val item = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setOnClickListener {
                    if (authMode != key) {
                        authMode = key
                        render()
                    }
                }
            }
            val label = label(text, 16f, selectedTab,
                if (selectedTab) ink else Color.rgb(137, 145, 151)).apply {
                gravity = Gravity.CENTER
            }
            item.addView(label, LinearLayout.LayoutParams(-1, dp(44)))
            item.addView(View(this).apply {
                setBackgroundColor(if (selectedTab) Style.ORANGE else faint)
            }, LinearLayout.LayoutParams(-1, dp(if (selectedTab) 3 else 1)))
            controls.addView(item, LinearLayout.LayoutParams(0, -2, 1f))
        }
        body.addView(controls)
        body.addView(label(
            if (authMode == "register") "Создайте профиль для доступа к цифровому дому"
            else "Войдите в свой демонстрационный профиль",
            15f, false, ink
        ).apply { setPadding(dp(18), dp(23), dp(18), dp(12)) })

        val name = if (authMode == "register") authField(
            "Ваше имя", "Например, Анна",
            InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
        ) else null
        val email = authField(
            "Электронная почта", "demo@example.com",
            InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS
        )
        if (authMode == "login") {
            email.setText(prefs.getString("demo_auth_email", ""))
        }
        val pin = authField(
            if (authMode == "register") "Придумайте код входа" else "Код входа",
            "4 цифры",
            InputType.TYPE_CLASS_NUMBER or InputType.TYPE_NUMBER_VARIATION_PASSWORD
        )
        pin.filters = arrayOf(android.text.InputFilter.LengthFilter(4))

        authPrimaryButton(if (authMode == "register") "Зарегистрироваться" else "Войти") {
            val address = email.text.toString().trim().lowercase(java.util.Locale.ROOT)
            val code = pin.text.toString()
            if (!android.util.Patterns.EMAIL_ADDRESS.matcher(address).matches()) {
                email.error = "Укажите корректный email";return@authPrimaryButton
            }
            if (code.length != 4 || !code.all { it.isDigit() }) {
                pin.error = "Введите 4 цифры";return@authPrimaryButton
            }
            if (authMode == "register") {
                val displayName = name?.text?.toString()?.trim().orEmpty()
                if (displayName.length < 2) {
                    name?.error = "Укажите имя";return@authPrimaryButton
                }
                val salt = java.util.UUID.randomUUID().toString()
                prefs.edit()
                    .putString("demo_auth_email", address)
                    .putString("demo_auth_salt", salt)
                    .putString("demo_auth_hash", authDigest(address, code, salt))
                    .putString("name", displayName)
                    .putBoolean("registered", true)
                    .apply()
            } else {
                val salt = prefs.getString("demo_auth_salt", "").orEmpty()
                val expected = prefs.getString("demo_auth_hash", "").orEmpty()
                if (salt.isBlank() || expected.isBlank()
                    || address != prefs.getString("demo_auth_email", "")
                    || authDigest(address, code, salt) != expected) {
                    notice("Неверный демо-email или код входа")
                    return@authPrimaryButton
                }
                prefs.edit().putBoolean("registered", true).apply()
            }
            tab = "Профиль"
            go("")
            notice("Цифровой дом теперь доступен в профиле")
        }

        val help = if (authMode == "register")
            "Уже есть демо-профиль?  Войти"
        else "Нет демо-профиля?  Зарегистрироваться"
        val switch = label(help, 14f, false, omaBlue).apply {
            gravity = Gravity.CENTER
            setOnClickListener {
                authMode = if (authMode == "register") "login" else "register"
                render()
            }
        }
        body.addView(switch, LinearLayout.LayoutParams(-1, dp(50)))
        note("Демо-режим: используйте только тестовые данные. " +
            "Регистрация работает на этом устройстве и не связана с аккаунтом ОМА.")
    }

    private fun authField(caption:String, hint:String, type:Int):EditText {
        body.addView(label(caption, 14f, true).apply {
            setPadding(dp(19), dp(12), dp(19), dp(7))
        })
        val border = android.graphics.drawable.GradientDrawable().apply {
            setColor(Color.WHITE)
            cornerRadius = dp(7).toFloat()
            setStroke(dp(1), Color.rgb(215, 220, 224))
        }
        val edit = EditText(this).apply {
            this.hint = hint
            inputType = type
            textSize = 16f
            setTextColor(ink)
            setHintTextColor(Color.rgb(165, 171, 176))
            isSingleLine = true
            background = border
            setPadding(dp(15), 0, dp(15), 0)
        }
        body.addView(edit, LinearLayout.LayoutParams(-1, dp(54)).apply {
            leftMargin = dp(18);rightMargin = dp(18);bottomMargin = dp(8)
        })
        return edit
    }

    private fun authPrimaryButton(text:String, click:()->Unit) {
        val background = android.graphics.drawable.GradientDrawable().apply {
            setColor(omaBlue)
            cornerRadius = dp(6).toFloat()
        }
        val button = label(text, 16f, true, Color.WHITE).apply {
            gravity = Gravity.CENTER
            this.background = background
            isClickable = true
            setOnClickListener { click() }
        }
        body.addView(button, LinearLayout.LayoutParams(-1, dp(54)).apply {
            leftMargin = dp(18);rightMargin = dp(18)
            topMargin = dp(22);bottomMargin = dp(8)
        })
    }

    private fun authDigest(email:String, code:String, salt:String):String =
        java.security.MessageDigest.getInstance("SHA-256")
            .digest("$salt:$email:$code".toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it.toInt() and 0xff) }

    private fun digital() {
        title("Цифровой дом")
        row("3D-модель","box",{go("3d")},true)
        row("Паспорт жилья","receipt",{go("passport")},true)
        row("Мой мастер","hammer",{go("master")},true)
        row("Умный поиск","search",{go("smart")},true)
    }
    private fun property(mode:String) {
        title(if(mode=="3d") "3D-модель" else "Паспорт жилья")
        val target=holder()
        message(target,"Загружаем демо-квартиры…")
        val serial=generation
        api.request("GET","/properties") { outcome->
            if(!active(serial))return@request
            outcome.fold({ raw->
                val items=Api.entries(Api.array(raw))
                target.removeAllViews()
                if(items.isEmpty()) {
                    message(target,"Пока нет демо-квартиры.")
                    button("Создать демо-квартиру") {
                        val data=JSONObject().put("name","Моя демо-квартира")
                            .put("address","Демонстрационный адрес")
                            .put("property_type","apartment")
                        api.request("POST","/properties",data) {r->
                            r.fold({raw->
                                val newId=JSONObject(raw).optInt("id")
                                if(newId<=0) {notice("Квартира создана");go(mode)}
                                else {
                                    val rooms=listOf(
                                        arrayOf("Гостиная","living_room","4.8","4.0"),
                                        arrayOf("Кухня","kitchen","3.3","3.0"),
                                        arrayOf("Спальня","bedroom","4.1","3.5"))
                                    fun addRoom(index:Int) {
                                        if(index>=rooms.size) {notice("Демо-квартира и комнаты созданы");go(mode);return}
                                        val room=rooms[index]
                                        val data=JSONObject().put("property_id",newId)
                                            .put("name",room[0]).put("room_type",room[1])
                                            .put("width_m",room[2].toDouble())
                                            .put("length_m",room[3].toDouble()).put("height_m",2.7)
                                        api.request("POST","/rooms",data) {answer->
                                            if(answer.isFailure) notice("Не удалось добавить "+room[0])
                                            addRoom(index+1)
                                        }
                                    }
                                    addRoom(0)
                                }
                            }, {notice("Ошибка: "+it.message)})
                        }
                    }
                } else items.forEach {item->
                    val id=item.optInt("id")
                    val text=label(item.optString("name","Квартира") + "  ›",16f).apply{
                        setPadding(dp(18),0,dp(12),0)
                        setOnClickListener {propertyId=id;openProperty(id,mode)}
                    }
                    target.addView(text,LinearLayout.LayoutParams(-1,dp(60)))
                    divider(target)
                }
            },{message(target,"Ошибка подключения: "+it.message)})
        }
    }
    private fun openProperty(id:Int,mode:String) {
        if(mode=="3d") {
            body.removeAllViews()
            note("3D-сцена из демонстрационного Backend, не из аккаунта ОМА.")
            val viewer=WebView(this)
            viewer.settings.javaScriptEnabled=true
            viewer.settings.domStorageEnabled=true
            viewer.webViewClient=WebViewClient()
            web=viewer
            body.addView(viewer,LinearLayout.LayoutParams(-1,dp(570)))
            viewer.loadUrl(api.baseUrl+"/api/v1/scene/view/"+id)
        } else {
            val link=api.baseUrl+"/api/v1/properties/"+id+"/passport.pdf"
            try {startActivity(Intent(Intent.ACTION_VIEW,Uri.parse(link)))}
            catch(e:Exception) {notice("Не удалось открыть PDF: "+e.message)}
        }
    }
    private fun masters() {
        title("Мой мастер")
        button("Кабинет мастера (демо)") {go("masterMode")}
        note("Выберите исполнителя. На этом же телефоне можно переключиться в кабинет мастера.")
        val list=holder();message(list,"Загружаем мастеров…")
        val serial=generation
        api.request("GET","/contractors") {r->
            if(!active(serial))return@request
            r.fold({raw->
                list.removeAllViews()
                val items=Api.entries(Api.array(raw))
                if(items.isEmpty())message(list,"Демо-мастера пока не добавлены")
                items.take(12).forEach {item->
                    val id=item.optInt("id")
                    val name=item.optString("display_name","Мастер #"+id)
                    val view=label(name+" · ID "+id,15.5f).apply {
                        setPadding(dp(18),0,dp(10),0)
                        setOnClickListener {contractorId=id;masterId=id;
                            prefs.edit().putInt("contractor",id).apply()
                            notice("Выбран мастер #"+id)}
                    }
                    list.addView(view,LinearLayout.LayoutParams(-1,dp(56)));divider(list)
                }
            },{message(list,"Ошибка: "+it.message)})
        }
        title("Заявка мастеру")
        val work=input("Название работы","Установить светильник")
        val detail=input("Описание","Нужны материалы и монтаж")
        val check=CheckBox(this).apply {text="Согласен передать мастеру текст заявки";textSize=13f}
        body.addView(check)
        button("Отправить заявку") {
            if(contractorId<=0) {notice("Выберите мастера выше");return@button}
            if(!check.isChecked) {notice("Требуется согласие");return@button}
            val request=JSONObject().put("contractor_id",contractorId)
                .put("title",work.text.toString()).put("description",detail.text.toString())
                .put("consent_granted",true).put("shared_fields",JSONArray())
            api.request("POST","/work-orders",request){r->
                r.fold({notice("Заявка отправлена");go("master")},{notice("Ошибка: "+it.message)})
            }
        }
        title("Мои заявки")
        val orders=holder();message(orders,"Загружаем заявки…")
        api.request("GET","/work-orders/mine") {r->
            if(!active(serial))return@request
            r.fold({raw->
                orders.removeAllViews()
                val items=Api.entries(Api.array(raw))
                if(items.isEmpty()) message(orders,"Заявок пока нет")
                items.take(15).forEach {item->
                    val id=item.optInt("id")
                    orders.addView(label("#"+id+" · "+item.optString("title")+" · "+item.optString("status"),14f).apply{
                        setPadding(dp(17),dp(12),dp(12),dp(8))})
                    if(item.optString("status")=="materials_proposed") {
                        val accept=label("Принять материалы в демо-корзину",14f,true,omaBlue)
                        accept.setPadding(dp(17),dp(9),0,dp(12))
                        accept.setOnClickListener {
                            api.request("POST","/work-orders/"+id+"/proposal/accept",JSONObject()){result->
                                result.fold({notice("Материалы приняты");go("master")},
                                    {notice("Ошибка: "+it.message)})
                            }
                        }
                        orders.addView(accept)
                    }
                    divider(orders)
                }
            },{message(orders,"Ошибка: "+it.message)})
        }
    }
    private fun masterMode() {
        title("Кабинет мастера (демо)")
        note("ID мастера — демонстрационный, это не настоящая авторизация.")
        val idField=input("ID мастера",if(masterId==0)"" else masterId.toString(),InputType.TYPE_CLASS_NUMBER)
        button("Подключить мастера") {
            masterId=idField.text.toString().toIntOrNull()?:0
            if(masterId<=0)notice("Введите ID") else go("masterMode")
        }
        if(masterId<=0)return
        val area=holder();message(area,"Загружаем заявки…")
        val serial=generation
        api.request("GET","/contractor/work-orders?contractor_id="+masterId,contractorId=masterId){r->
            if(!active(serial))return@request
            r.fold({raw->
                area.removeAllViews()
                val items=Api.entries(Api.array(raw))
                if(items.isEmpty()) message(area,"Заявок для мастера пока нет")
                items.take(15).forEach{item->
                    val id=item.optInt("id")
                    val state=item.optString("status")
                    area.addView(label("#"+id+" · "+item.optString("title")+" · "+state,14f).apply {
                        setPadding(dp(18),dp(12),dp(10),dp(12))
                    })
                    if(state=="submitted") {
                        val link=label("Принять заявку →",15f,true,omaBlue)
                        link.setPadding(dp(18),dp(9),0,dp(12))
                        link.setOnClickListener {
                            api.request("PATCH","/work-orders/"+id+"/status",
                                JSONObject().put("status","accepted"),masterId){res->
                                res.fold({notice("Заявка принята");go("masterMode")},
                                    {notice("Ошибка: "+it.message)})
                            }
                        }
                        area.addView(link)
                    }
                    if(state=="accepted") {
                        val link=label("Предложить товар →",15f,true,omaBlue)
                        link.setPadding(dp(18),dp(9),0,dp(12))
                        link.setOnClickListener {offer(id)}
                        area.addView(link)
                    }
                    divider(area)
                }
            },{message(area,"Ошибка: "+it.message)})
        }
    }
    private fun offer(orderId:Int) {
        api.request("GET","/products?page_size=1"){r->
            r.fold({raw->
                val product=JSONObject(raw).optJSONArray("items")?.optJSONObject(0)
                val id=product?.optString("id").orEmpty()
                if(id.isBlank()) {notice("Демо-каталог пуст");return@fold}
                val lines=JSONArray().put(JSONObject().put("product_id",id).put("quantity",1))
                api.request("POST","/work-orders/"+orderId+"/proposal",
                    JSONObject().put("items",lines),masterId){response->
                    response.fold({notice("Предложение отправлено");go("masterMode")},
                        {notice("Ошибка: "+it.message)})
                }
            },{notice("Ошибка: "+it.message)})
        }
    }
    private fun smart() {
        title("Умный поиск")
        note("Поиск по демо-каталогу; для фотографии используется распознавание категорий при наличии AI на сервере.")
        val value=input("Название товара",query)
        button("Найти товары") {query=value.text.toString().trim();products(query)}
        button("Поиск по фотографии") {
            val intent=Intent(Intent.ACTION_GET_CONTENT).apply {type="image/*";addCategory(Intent.CATEGORY_OPENABLE)}
            startActivityForResult(Intent.createChooser(intent,"Выберите фото"),pickPhoto)
        }
        if(query.isNotBlank()) products(query)
        else note("Введите запрос или выберите фотографию.")
    }
    private fun products(term:String) {
        val holder=holder();message(holder,"Загружаем товары…")
        val serial=generation
        val q=if(term.isBlank())"" else "&q="+URLEncoder.encode(term,"UTF-8")
        api.request("GET","/products?page_size=20"+q){r->
            if(!active(serial))return@request
            r.fold({raw->
                holder.removeAllViews()
                val items=JSONObject(raw).optJSONArray("items")?:JSONArray()
                if(items.length()==0)message(holder,"Товары не найдены")
                Api.entries(items).forEach{item->
                    val name=item.optString("name","Товар")
                    val price=item.optString("price","—")
                    val id=item.optString("id")
                    val element=label(name+" · "+price+" BYN",14f).apply {
                        setPadding(dp(16),dp(12),dp(14),dp(12))
                        setOnClickListener {
                            api.request("POST","/cart/items",
                                JSONObject().put("product_id",id).put("quantity",1)){reply->
                                reply.fold({notice("Добавлено в демо-корзину")},{notice("Ошибка: "+it.message)})
                            }
                        }
                    }
                    holder.addView(element);divider(holder)
                }
            },{message(holder,"Ошибка: "+it.message)})
        }
    }
    @Deprecated("Deprecated in Android")
    override fun onActivityResult(code:Int,result:Int,data:Intent?) {
        super.onActivityResult(code,result,data)
        if(code!=pickPhoto||result!=RESULT_OK||data?.data==null)return
        val uri=data.data?:return
        notice("Анализируем фотографию…")
        Thread {
            val outcome=runCatching {
                val bytes=contentResolver.openInputStream(uri)?.use {it.readBytes()}?:error("Нельзя открыть изображение")
                require(bytes.size <= 8*1024*1024) {"Фото больше 8 МБ"}
                val boundary="OMADemoBoundary"+System.nanoTime()
                val c=URL(api.baseUrl+"/api/v1/visual-search").openConnection() as HttpURLConnection
                try {
                    c.requestMethod="POST";c.connectTimeout=10000;c.readTimeout=60000;c.doOutput=true
                    c.setRequestProperty("Content-Type","multipart/form-data; boundary="+boundary)
                    c.outputStream.use{ stream->
                        stream.write(("--"+boundary+"\r\nContent-Disposition: form-data; name=\"file\"; filename=\"photo.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n").toByteArray())
                        stream.write(bytes)
                        stream.write(("\r\n--"+boundary+"--\r\n").toByteArray())
                    }
                    val status=c.responseCode
                    val raw=(if(status in 200..299)c.inputStream else c.errorStream)
                        ?.bufferedReader()?.use{it.readText()}.orEmpty()
                    if(status !in 200..299)error("HTTP "+status+": "+raw.take(130))
                    JSONObject(raw)
                } finally {c.disconnect()}
            }
            runOnUiThread {
                outcome.fold({response->
                    go("smart")
                    note(response.optString("note","Возможные совпадения"))
                    val matches=response.optJSONArray("matches")?:JSONArray()
                    if(matches.length()==0) note("Совпадения не найдены")
                    Api.entries(matches).forEach{m->
                        row(m.optString("name","Товар"),"search",{notice("Возможное совпадение, не точный артикул")})
                    }
                },{notice("Ошибка поиска по фото: "+it.message)})
            }
        }.start()
    }
    private fun home() {
        title("ОМА")
        note("Демонстрационная версия каталога товаров для дома и ремонта.")
        button("Открыть каталог"){tabTo("Каталог")}
        button("Перейти в профиль"){tabTo("Профиль")}
    }
    private fun catalog() {title("Каталог");button("Найти товары"){go("smart")};products("")}
    private fun cart() {
        title("Корзина")
        val target=holder();message(target,"Загрузка…")
        val serial=generation
        api.request("GET","/cart"){r->
            if(!active(serial))return@request
            r.fold({raw->
                val json=JSONObject(raw)
                val items=json.optJSONArray("items")?:JSONArray()
                message(target,if(items.length()==0)"Демо-корзина пуста" else "Товаров в корзине: "+items.length())
            },{message(target,"Ошибка: "+it.message)})
        }
    }
    private fun favorites() {title("Избранное");note("Список официальной ОМА недоступен в демонстрационном APK.")}
    private fun orders() {
        title("История заказов")
        note("История официальной ОМА недоступна. Показаны данные демо-Backend.")
        val target=holder()
        api.request("GET","/orders"){r->
            r.fold({raw->message(target,"Демо-заказов: "+Api.array(raw).length())},
                {message(target,"Ошибка: "+it.message)})
        }
    }
    private fun account() {
        title("Демо-профиль")
        if(signedIn()) note("Имя: "+prefs.getString("name","Анна"))
        note("Этот экран не использует настоящий аккаунт ОМА.")
        val host=input("HTTPS-адрес Backend",api.baseUrl,InputType.TYPE_TEXT_VARIATION_URI)
        button("Сохранить адрес и проверить") {
            val s=host.text.toString().trim().trimEnd('/')
            if(!s.startsWith("https://")) {notice("Укажите HTTPS");return@button}
            api.baseUrl=s
            api.request("GET","/me"){r->
                r.fold({notice("Демо-Backend подключён")},{notice("Ошибка: "+it.message)})
            }
        }
        if(signedIn()) button("Выйти из демо-профиля") {
            prefs.edit().putBoolean("registered",false).apply();go("")
        } else button("Войти"){go("auth")}
    }
}
