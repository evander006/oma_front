package by.oma.companion

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.widget.*
import org.json.JSONArray
import org.json.JSONObject

/** Hackathon demo UI for both client and contractor phones. Not an official OMA app. */
class MainActivity : Activity() {
    private lateinit var api: Api
    private lateinit var content: LinearLayout
    private lateinit var info: TextView
    private var mode = "customer"
    private var selectedContractor = 0
    private var selectedProperty = 0
    private var requestTitle: EditText? = null
    private var requestNotes: EditText? = null
    private var consent: CheckBox? = null
    private val handler = Handler(Looper.getMainLooper())
    private var customerOrders: LinearLayout? = null
    private var masterOrders: LinearLayout? = null
    private var currentContractorId = 0
    private var screenGeneration = 0
    private val refreshTask = object : Runnable {
        override fun run() {
            if (mode == "master" && !isFinishing) reloadMasterOrders()
            handler.postDelayed(this, 10000)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        api = Api(this)
        mode = intent.getStringExtra("mode")?.takeIf { it == "master" } ?: "customer"
        selectedContractor = getPreferences(MODE_PRIVATE).getInt("contractor", 0)
        currentContractorId = selectedContractor
        render()
    }

    override fun onResume() { super.onResume(); handler.removeCallbacks(refreshTask); handler.postDelayed(refreshTask, 10000) }
    override fun onPause() { handler.removeCallbacks(refreshTask); super.onPause() }
    override fun onDestroy() { handler.removeCallbacks(refreshTask); api.close(); super.onDestroy() }

    private fun present(message: String) { info.text = message }
    private fun isActive(generation: Int) = generation == screenGeneration && !isFinishing

    private fun root(): LinearLayout {
        val scroller = ScrollView(this).apply { isFillViewport = true; setBackgroundColor(Style.BACK) }
        val column = Style.column(this)
        scroller.addView(column)
        setContentView(scroller)
        return column
    }

    private fun section(target: LinearLayout, name: String, description: String? = null): LinearLayout {
        target.addView(Style.gap(this, 14))
        val box = Style.column(this).apply { background = Style.bg(-1, 15f, 0xffdce4e9.toInt()) }
        box.addView(Style.text(this, name, 18f, true))
        if (description != null) box.addView(Style.text(this, description, 12f, false, Style.MUTED))
        target.addView(box)
        return box
    }

    private fun render() {
        screenGeneration++
        content = root()
        val title = Style.text(this, "ОМА  ·  COMPANION", 24f, true, Style.BLUE)
        content.addView(title)
        content.addView(Style.text(this, "Хакатонный прототип · неофициальное дополнение", 12f, false, Style.MUTED))
        val controls = section(content, "Настройка демонстрации")
        controls.addView(Style.button(this, "Открыть настоящее приложение ОМА", { launchOma() }))
        controls.addView(Style.gap(this, 5))
        controls.addView(Style.button(this, "Включить плавающую панель", { startOverlay() }, false))
        controls.addView(Style.gap(this, 5))
        controls.addView(Style.button(this, "Остановить панель", {
            stopService(Intent(this, OverlayService::class.java))
            present("Панель остановлена")
        }, false))
        val host = EditText(this).apply {
            setSingleLine(true)
            inputType = android.text.InputType.TYPE_TEXT_VARIATION_URI
            setText(api.baseUrl)
            hint = "https://your-demo-backend"
            textSize = 13f
        }
        controls.addView(Style.gap(this))
        controls.addView(Style.text(this, "Адрес Backend (одинаковый на двух телефонах):", 12f, false, Style.MUTED))
        controls.addView(host)
        controls.addView(Style.button(this, "Сохранить адрес и проверить", {
            val value = host.text.toString().trim()
            if (!value.startsWith("https://")) { present("Адрес должен начинаться с https://"); return@button }
            api.baseUrl = value
            api.request("GET", "/me") { r -> present(r.fold({ "Backend подключён: ${JSONObject(it).optString("display_name", "demo")}" }, { "Ошибка Backend: ${it.message}" })) }
        }, false))

        val modes = section(content, "Режим телефона")
        modes.addView(Style.button(this, "1 · Клиент", { mode = "customer"; render() }, mode == "customer"))
        modes.addView(Style.gap(this, 5))
        modes.addView(Style.button(this, "2 · Мастер", { mode = "master"; render() }, mode == "master"))
        info = Style.text(this, "На Backend используются общие демонстрационные данные. Реальные данные не вводите.", 12f, false, Style.MUTED)
        content.addView(Style.gap(this))
        content.addView(info)
        if (mode == "master") buildMaster() else buildCustomer()
    }

    private fun startOverlay() {
        if (!Settings.canDrawOverlays(this)) {
            startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")))
            present("Разрешите отображение поверх приложений и вернитесь сюда")
            return
        }
        if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 71)
            // FGS itself can start without notification permission, but we request it for visibility.
        }
        try {
            startForegroundService(Intent(this, OverlayService::class.java))
            present("Панель активирована. Откройте оригинальное приложение ОМА.")
        } catch (ex: Exception) { present("Ошибка запуска наложения: ${ex.message}") }
    }

    private fun launchOma() {
        try {
            val launch = packageManager.getLaunchIntentForPackage("ru.oma.android")
            if (launch == null) {
                present("Оригинальное приложение ОМА не обнаружено. Установите его отдельно через официальный магазин.")
            } else startActivity(launch)
        } catch (ex: Exception) { present("Невозможно запустить ОМА: ${ex.message}") }
    }

    private fun link(path: String) {
        try {
            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(api.baseUrl + "/api/v1" + path)))
        } catch (ex: Exception) { present("Не удалось открыть ссылку: ${ex.message}") }
    }

    private fun buildCustomer() {
        val generation = screenGeneration
        val home = section(content, "01 · Моё жильё", "Здесь можно открыть 3D-сцену и PDF-паспорт квартиры")
        val homes = Style.column(this)
        home.addView(homes)
        api.request("GET", "/properties") { r ->
            if (!isActive(generation)) return@request
            homes.removeAllViews()
            r.fold({ data ->
                val props = Api.entries(Api.array(data))
                if (props.isEmpty()) homes.addView(Style.text(this, "Создайте демо-квартиру в Flutter-приложении", 13f))
                props.take(5).forEach { prop ->
                    val id = prop.optInt("id")
                    if (selectedProperty == 0) selectedProperty = id
                    homes.addView(Style.text(this, prop.optString("name", "Квартира #$id"), 14f, true))
                    homes.addView(Style.button(this, "3D-квартира #$id", { link("/scene/view/$id") }, false))
                    homes.addView(Style.gap(this, 4))
                    homes.addView(Style.button(this, "Скачать PDF-паспорт #$id", { link("/properties/$id/passport.pdf") }, false))
                }
            }, { homes.addView(Style.text(this, "Ошибка загрузки жилья: ${it.message}", 12f)) })
        }
        val masters = section(content, "02 · Найти мастера", "Выберите демо-исполнителя из Backend")
        val masterList = Style.column(this)
        masters.addView(masterList)
        api.request("GET", "/contractors") { r ->
            if (!isActive(generation)) return@request
            masterList.removeAllViews()
            r.fold({ data ->
                val items = Api.entries(Api.array(data))
                if (items.isEmpty()) masterList.addView(Style.text(this, "Демо-мастера отсутствуют", 13f))
                items.take(8).forEach { person ->
                    val id = person.optInt("id")
                    if (selectedContractor == 0) selectedContractor = id
                    val name = person.optString("display_name", "Мастер #$id")
                    masterList.addView(Style.button(this, "$name  ·  Выбрать", {
                        selectedContractor = id
                        getPreferences(MODE_PRIVATE).edit().putInt("contractor", id).apply()
                        present("Выбран $name, ID=$id. Теперь отправьте заявку ниже.")
                    }, false))
                    masterList.addView(Style.gap(this, 4))
                }
            }, { masterList.addView(Style.text(this, "Ошибка загрузки мастеров: ${it.message}", 12f)) })
        }
        val orderForm = section(content, "03 · Отправить заявку", "Из этого демо-запроса мастер получит задачу на другом телефоне")
        requestTitle = EditText(this).apply { hint = "Название заявки"; setSingleLine(true); setText("Монтаж светильника в квартире") }
        requestNotes = EditText(this).apply { hint = "Комментарий"; setText("Нужно установить оборудование. Материалы подобрать в ОМА.") }
        consent = CheckBox(this).apply { text = "Согласен передать мастеру текст заявки (без адреса и фото)"; isChecked = false }
        orderForm.addView(requestTitle)
        orderForm.addView(requestNotes)
        orderForm.addView(consent)
        orderForm.addView(Style.button(this, "Отправить заявку мастеру", {
            if (selectedContractor == 0) { present("Сначала выберите мастера"); return@button }
            if (consent?.isChecked != true) { present("Нужно явное согласие на передачу информации"); return@button }
            val title = requestTitle?.text?.toString()?.trim().orEmpty()
            val notes = requestNotes?.text?.toString()?.trim().orEmpty()
            if (title.isEmpty() || notes.isEmpty()) { present("Укажите тему и описание заявки"); return@button }
            val payload = JSONObject()
                .put("contractor_id", selectedContractor)
                .put("title", title)
                .put("description", notes)
                .put("consent_granted", true)
                .put("shared_fields", JSONArray())
            present("Отправляем заявку…")
            api.request("POST", "/work-orders", payload) { r ->
                present(r.fold({ "Заявка #${JSONObject(it).optInt("id")} отправлена. Откройте второй телефон." }, { "Ошибка заявки: ${it.message}" }))
                if (r.isSuccess) reloadCustomerOrders()
            }
        }))
        val orders = section(content, "04 · Мои заявки", "Подтверждение предложенных мастером материалов добавляет их в демо-корзину")
        orders.addView(Style.button(this, "Обновить статусы", { reloadCustomerOrders() }, false))
        customerOrders = Style.column(this)
        orders.addView(customerOrders)
        reloadCustomerOrders()
    }

    private fun reloadCustomerOrders() {
        val generation = screenGeneration
        val target = customerOrders ?: return
        api.request("GET", "/work-orders/mine") { result ->
            if (!isActive(generation)) return@request
            target.removeAllViews()
            result.fold({ data ->
                val rows = Api.entries(Api.array(data))
                if (rows.isEmpty()) target.addView(Style.text(this, "Пока нет заявок", 13f))
                rows.take(12).forEach { row ->
                    val id = row.optInt("id")
                    val status = row.optString("status")
                    target.addView(Style.text(this, "#${id} · $status · ${row.optString("title")}", 13f, true))
                    if (status == "materials_proposed") {
                        target.addView(Style.button(this, "Принять предложение #$id в корзину", {
                            api.request("POST", "/work-orders/$id/proposal/accept", JSONObject()) { r ->
                                present(r.fold({ "Материалы по заявке #$id добавлены в демо-корзину" }, { "Ошибка: ${it.message}" }))
                                if (r.isSuccess) reloadCustomerOrders()
                            }
                        }))
                    }
                    target.addView(Style.gap(this, 6))
                }
            }, { target.addView(Style.text(this, "Ошибка статусов: ${it.message}", 13f)) })
        }
    }

    private fun buildMaster() {
        val area = section(content, "Кабинет демо-мастера", "Заявки поступают с первого телефона через общий Backend")
        val selector = EditText(this).apply {
            inputType = android.text.InputType.TYPE_CLASS_NUMBER
            setSingleLine(true)
            hint = "ID мастера"
            setText(if (currentContractorId == 0) "" else currentContractorId.toString())
        }
        area.addView(Style.text(this, "ID выбранного мастера должен совпадать с ID в телефоне клиента.", 12f, false, Style.MUTED))
        area.addView(selector)
        area.addView(Style.button(this, "Подключить демо-мастера", {
            currentContractorId = selector.text.toString().toIntOrNull() ?: 0
            if (currentContractorId <= 0) { present("Введите ID мастера из каталога первого телефона"); return@button }
            getPreferences(MODE_PRIVATE).edit().putInt("contractor", currentContractorId).apply()
            present("Мастер #$currentContractorId подключён")
            reloadMasterOrders()
        }))
        area.addView(Style.gap(this, 5))
        area.addView(Style.button(this, "Обновить заявки", { reloadMasterOrders() }, false))
        masterOrders = Style.column(this)
        area.addView(masterOrders)
        reloadMasterOrders()
    }

    private fun reloadMasterOrders() {
        val target = masterOrders ?: return
        val generation = screenGeneration
        val id = currentContractorId
        if (id <= 0) { target.removeAllViews(); target.addView(Style.text(this, "Укажите ID мастера", 13f)); return }
        api.request("GET", "/contractor/work-orders?contractor_id=$id", contractorId = id) { result ->
            if (!isActive(generation) || id != currentContractorId) return@request
            target.removeAllViews()
            result.fold({ data ->
                val orders = Api.entries(Api.array(data))
                if (orders.isEmpty()) target.addView(Style.text(this, "Пока заявок нет. Создайте их на телефоне клиента.", 13f))
                orders.take(15).forEach { order ->
                    val orderId = order.optInt("id")
                    val status = order.optString("status")
                    target.addView(Style.text(this, "#${orderId} · $status", 15f, true))
                    target.addView(Style.text(this, order.optString("title"), 13f))
                    when (status) {
                        "submitted" -> target.addView(Style.button(this, "Принять заявку #$orderId", {
                            api.request("PATCH", "/work-orders/$orderId/status", JSONObject().put("status", "accepted"), id) { r ->
                                present(r.fold({ "Заявка #$orderId принята" }, { "Ошибка: ${it.message}" }))
                                if (r.isSuccess) reloadMasterOrders()
                            }
                        }))
                        "accepted" -> target.addView(Style.button(this, "Предложить первый товар из демо-каталога", { proposeMaterials(orderId, id) }))
                        "materials_proposed" -> target.addView(Style.text(this, "Предложение отправлено клиенту", 12f, false, Style.MUTED))
                    }
                    target.addView(Style.gap(this, 10))
                }
            }, { target.addView(Style.text(this, "Ошибка загрузки: ${it.message}", 12f)) })
        }
    }

    private fun proposeMaterials(workOrderId: Int, contractorId: Int) {
        present("Подбираем доступный товар из демо-каталога…")
        api.request("GET", "/products?page_size=1") { r ->
            r.fold({ data ->
                val products = JSONObject(data).optJSONArray("items") ?: JSONArray()
                val product = products.optJSONObject(0)
                val productId = product?.optString("id").orEmpty()
                if (productId.isEmpty()) { present("В каталоге Backend нет товаров. Заполните каталог."); return@fold }
                val items = JSONArray().put(JSONObject().put("product_id", productId).put("quantity", 1))
                api.request("POST", "/work-orders/$workOrderId/proposal", JSONObject().put("items", items), contractorId) { result ->
                    present(result.fold({ "Предложение товара «${product.optString("name") }» отправлено" }, { "Ошибка предложения: ${it.message}" }))
                    if (result.isSuccess) reloadMasterOrders()
                }
            }, { present("Ошибка поиска товара: ${it.message}") })
        }
    }
}
