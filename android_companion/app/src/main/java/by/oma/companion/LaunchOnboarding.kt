package by.oma.companion

import android.app.Activity
import android.graphics.Color
import android.graphics.Typeface
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

/**
 * One introduction per fresh Activity launch. The parent Activity keeps this
 * instance through normal navigation and saves its page on configuration changes.
 * No 'seen onboarding' flag or changes to the signed-in demo account are needed.
 */
internal class LaunchOnboarding(
    private val activity: Activity,
    initialPage: Int,
    private val onPageChanged: (Int) -> Unit,
    private val onComplete: () -> Unit
) {
    private data class Slide(val image: Int, val title: String, val description: String)

    private val slides = listOf(
        Slide(
            R.drawable.oma_story_passport,
            "Всё о вашем доме — в одном месте",
            "Храните сведения о комнатах и покупках, просматривайте паспорт объекта и сохраняйте его в PDF."
        ),
        Slide(
            R.drawable.oma_story_interior,
            "Представьте свой дом в 3D",
            "Просматривайте объёмную модель комнат и расположение добавленных товаров в вашем доме."
        ),
        Slide(
            R.drawable.oma_story_visual,
            "Нашли идею? Найдите товар",
            "Сфотографируйте предмет или выберите фото, чтобы найти похожие товары в каталоге ОМА."
        ),
        Slide(
            R.drawable.oma_story_service,
            "Помощь специалиста — рядом",
            "Выбирайте мастеров для ремонта, монтажа и других задач по дому."
        )
    )

    var currentPage: Int = initialPage.coerceIn(0, slides.lastIndex)
        private set

    private val content = LinearLayout(activity).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER
    }
    private val indicators = LinearLayout(activity).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER
    }
    private lateinit var primary: TextView
    private var touchX = 0f
    private var touchY = 0f

    private fun dp(value: Int): Int = Style.dp(activity, value)

    private fun text(value: String, size: Float, color: Int, bold: Boolean = false) =
        TextView(activity).apply {
            this.text = value
            textSize = size
            setTextColor(color)
            gravity = Gravity.CENTER
            includeFontPadding = true
            if (bold) typeface = Typeface.create("sans-serif", Typeface.BOLD)
        }

    fun show() {
        val root = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
        }
        val top = LinearLayout(activity).apply {
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(24), dp(12), dp(24), dp(8))
        }
        top.addView(ImageView(activity).apply {
            setImageResource(R.drawable.oma_logo)
            scaleType = ImageView.ScaleType.FIT_START
            contentDescription = "ОМА"
        }, LinearLayout.LayoutParams(0, dp(38), 1f))
        val skip = text("Пропустить", 14f, Style.BRAND_RED).apply {
            setPadding(dp(10), dp(12), 0, dp(12))
            isClickable = true
            isFocusable = true
            contentDescription = "Пропустить приветствие"
            setOnClickListener { onComplete() }
        }
        top.addView(skip)
        root.addView(top, LinearLayout.LayoutParams(-1, -2))

        val scroll = ScrollView(activity).apply {
            isFillViewport = true
            isVerticalScrollBarEnabled = false
            setBackgroundColor(Color.WHITE)
        }
        scroll.addView(content, FrameLayout.LayoutParams(-1, -1))
        root.addView(scroll, LinearLayout.LayoutParams(-1, 0, 1f))

        root.addView(indicators, LinearLayout.LayoutParams(-1, dp(30)).apply {
            bottomMargin = dp(10)
        })
        primary = text("Далее", 17f, Color.WHITE, true).apply {
            background = Style.interactiveBg(Style.BRAND_RED, Style.BRAND_RED_DARK, 14f)
            isClickable = true
            isFocusable = true
            setOnClickListener { next() }
        }
        root.addView(primary, LinearLayout.LayoutParams(-1, dp(54)).apply {
            leftMargin = dp(24)
            rightMargin = dp(24)
            bottomMargin = dp(22)
        })
        activity.setContentView(root)
        display(animate = false)
    }

    fun next() {
        if (currentPage == slides.lastIndex) {
            onComplete()
        } else {
            currentPage += 1
            onPageChanged(currentPage)
            display(animate = true)
        }
    }

    fun previous() {
        if (currentPage > 0) {
            currentPage -= 1
            onPageChanged(currentPage)
            display(animate = true)
        }
    }

    /** Called from Activity.dispatchTouchEvent to preserve ordinary vertical scrolling. */
    fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                touchX = event.x
                touchY = event.y
            }
            MotionEvent.ACTION_UP -> {
                val dx = event.x - touchX
                val dy = event.y - touchY
                if (kotlin.math.abs(dx) > dp(65) &&
                    kotlin.math.abs(dx) > kotlin.math.abs(dy) * 1.35f) {
                    if (dx < 0) next() else previous()
                    return true
                }
            }
        }
        return false
    }

    private fun display(animate: Boolean) {
        val slide = slides[currentPage]
        content.removeAllViews()
        content.setPadding(dp(24), dp(14), dp(24), dp(14))

        val screenHeightDp = activity.resources.displayMetrics.heightPixels /
            activity.resources.displayMetrics.density
        val imageHeight = if (screenHeightDp < 650f) 168 else 242
        val imageWidth = if (screenHeightDp < 650f) 158 else 216
        val picture = ImageView(activity).apply {
            setImageResource(slide.image)
            scaleType = ImageView.ScaleType.FIT_CENTER
            contentDescription = slide.title
            background = Style.bg(Style.BRAND_RED_SOFT, 24f)
            clipToOutline = true
        }
        content.addView(picture, LinearLayout.LayoutParams(dp(imageWidth), dp(imageHeight)))
        content.addView(text(slide.title, 25f, Style.DARK, true).apply {
            setPadding(0, dp(25), 0, dp(12))
            maxLines = 3
        }, LinearLayout.LayoutParams(-1, -2))
        content.addView(text(slide.description, 16f, Style.MUTED).apply {
            setLineSpacing(dp(4).toFloat(), 1f)
            maxLines = 8
        }, LinearLayout.LayoutParams(-1, -2))

        indicators.removeAllViews()
        slides.indices.forEach { index ->
            indicators.addView(View(activity).apply {
                background = Style.bg(
                    if (index == currentPage) Style.BRAND_RED else Style.BORDER,
                    4f
                )
                contentDescription = "Экран ${index + 1} из ${slides.size}" +
                    if (index == currentPage) ", выбран" else ""
            }, LinearLayout.LayoutParams(dp(if (index == currentPage) 25 else 8), dp(8)).apply {
                leftMargin = dp(4)
                rightMargin = dp(4)
            })
        }
        primary.text = if (currentPage == slides.lastIndex) "Начать" else "Далее"
        primary.contentDescription = primary.text
        if (animate) {
            content.alpha = 0f
            content.translationX = dp(12).toFloat()
            content.animate().alpha(1f).translationX(0f).setDuration(220).start()
        } else {
            content.alpha = 1f
            content.translationX = 0f
        }
    }
}
