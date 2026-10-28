package by.oma.companion

import android.app.*
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.*
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import kotlin.math.abs
import kotlin.math.roundToInt

/** Explicit opt-in, user-controlled bubble. Does not inspect, automate, or modify the OMA app. */
class OverlayService : Service() {
    companion object {
        const val STOP = "by.oma.companion.STOP"
        private const val CHANNEL = "oma_companion_demo"
        private const val ID = 5101
    }

    private lateinit var manager: WindowManager
    private var bubble: View? = null
    private var panel: View? = null
    private lateinit var bubbleParams: WindowManager.LayoutParams
    private val api by lazy { Api(this) }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        manager = getSystemService(WINDOW_SERVICE) as WindowManager
        val channels = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        channels.createNotificationChannel(
            NotificationChannel(CHANNEL, "OMA Companion (демо)", NotificationManager.IMPORTANCE_LOW)
        )
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification = Notification.Builder(this, CHANNEL)
            .setContentTitle("OMA Companion — демо-панель")
            .setContentText("Нажмите, чтобы открыть настройки и остановить панель")
            .setSmallIcon(android.R.drawable.ic_menu_manage)
            .setContentIntent(open)
            .setOngoing(true).build()
        startForeground(ID, notification)
        if (!Settings.canDrawOverlays(this)) { stopSelf(); return }
        showBubble()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == STOP) { stopSelf(); return START_NOT_STICKY }
        return START_NOT_STICKY
    }

    private fun window(width: Int, height: Int, y: Int, x: Int = 12): WindowManager.LayoutParams =
        WindowManager.LayoutParams(
            width, height,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            android.graphics.PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.END
            this.x = Style.dp(this@OverlayService, x)
            this.y = Style.dp(this@OverlayService, y)
        }

    private fun showBubble() {
        val badge = TextView(this).apply {
            text = "⌂"
            textSize = 29f
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            background = Style.bg(Style.BLUE, 28f)
            elevation = Style.dp(this@OverlayService, 8).toFloat()
            contentDescription = "Открыть сервисы OMA Companion"
        }
        bubbleParams = window(Style.dp(this, 58), Style.dp(this, 58), y = 150)
        var downX = 0f
        var downY = 0f
        var originalX = 0
        var originalY = 0
        var moved = false
        badge.setOnTouchListener { _, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    downX = event.rawX; downY = event.rawY
                    originalX = bubbleParams.x; originalY = bubbleParams.y
                    moved = false; true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - downX; val dy = event.rawY - downY
                    if (abs(dx) > Style.dp(this, 7) || abs(dy) > Style.dp(this, 7)) moved = true
                    if (moved) {
                        bubbleParams.x = (originalX - dx.roundToInt()).coerceAtLeast(0)
                        bubbleParams.y = (originalY + dy.roundToInt()).coerceAtLeast(0)
                        manager.updateViewLayout(badge, bubbleParams)
                    }; true
                }
                MotionEvent.ACTION_UP -> { if (!moved) togglePanel(); true }
                else -> false
            }
        }
        bubble = badge
        manager.addView(badge, bubbleParams)
    }

    private fun togglePanel() {
        if (panel != null) { hidePanel(); return }
        val root = Style.column(this).apply {
            background = Style.bg(Color.WHITE, 18f)
            elevation = Style.dp(this@OverlayService, 10).toFloat()
        }
        val heading = Style.text(this, "ОМА  +  МОЙ ДОМ", 18f, true, Style.BLUE)
        root.addView(heading)
        root.addView(Style.text(this, "Демонстрационное расширение поверх ОМА", 12f, false, Style.MUTED))
        root.addView(Style.gap(this))
        listOf(
            "◫  3D-модель жилья",
            "▤  Цифровой паспорт и история",
            "⚒  Каталог мастеров и заявки",
            "▣  Материалы и проект ремонта"
        ).forEach { root.addView(Style.text(this, it, 14f)) }
        root.addView(Style.gap(this))
        val status = Style.text(this, "Подключаемся к демо-серверу…", 12f, false, Style.MUTED)
        root.addView(status)
        root.addView(Style.button(this, "Открыть сервисы клиента", { openFull("customer") }))
        root.addView(Style.gap(this, 5))
        root.addView(Style.button(this, "Режим мастера", { openFull("master") }, false))
        root.addView(Style.gap(this, 5))
        root.addView(Style.button(this, "Свернуть панель", { hidePanel() }, false))
        val display = resources.displayMetrics
        val width = minOf(Style.dp(this, 340), display.widthPixels - Style.dp(this, 24))
        val maxHeight = display.heightPixels - Style.dp(this, 120)
        val params = window(width, WindowManager.LayoutParams.WRAP_CONTENT, y = 70)
        panel = root
        manager.addView(root, params)
        // The window never covers the full screen; untouched portions stay interactive.
        api.request("GET", "/work-orders/mine") { result ->
            if (panel !== root) return@request
            status.text = result.fold(
                onSuccess = { "●  Backend подключён · заявок: ${Api.array(it).length()}" },
                onFailure = { "○  Нет соединения: ${it.message?.take(80)}" }
            )
        }
    }

    private fun hidePanel() {
        panel?.let { runCatching { manager.removeView(it) } }
        panel = null
    }

    private fun openFull(mode: String) {
        hidePanel()
        try {
            startActivity(Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("mode", mode)
            })
        } catch (ex: Exception) {
            Toast.makeText(this, "Откройте OMA Companion из списка приложений", Toast.LENGTH_LONG).show()
        }
    }

    override fun onDestroy() {
        hidePanel()
        bubble?.let { runCatching { manager.removeView(it) } }
        bubble = null
        api.close()
        super.onDestroy()
    }
}
