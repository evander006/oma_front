package by.oma.companion

import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.animation.AccelerateDecelerateInterpolator
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView

/**
 * In-app (not SYSTEM_ALERT_WINDOW) promotional entry to the digital-home demo.
 *
 * The original five store tabs are not replaced. This small, semi-transparent
 * widget stays above their content and gently bobs, with independent star
 * twinkles. A full-screen scrim and pale blue list are only displayed after
 * a customer explicitly taps the chip and is locally signed in.
 */
object FloatingFeatures {
    private val blue = Color.rgb(0, 101, 174)
    private val ink = Color.rgb(41, 64, 87)
    private val pale = Color.argb(237, 219, 240, 251)
    private val lighter = Color.argb(235, 244, 250, 255)

    private fun dp(context: Context, n: Int): Int = Style.dp(context, n)

    private fun shape(context: Context, color: Int, radius: Int, line: Int? = null) =
        GradientDrawable().apply {
            setColor(color)
            cornerRadius = dp(context, radius).toFloat()
            if (line != null) setStroke(dp(context, 1), line)
        }

    private fun label(
        context: Context,
        text: String,
        size: Float,
        color: Int = ink,
        bold: Boolean = false
    ) = TextView(context).apply {
        this.text = text
        textSize = size
        setTextColor(color)
        gravity = Gravity.CENTER_VERTICAL
        includeFontPadding = true
        if (bold) setTypeface(null, Typeface.BOLD)
    }

    /** Small floating promotional chip visible on every original store tab. */
    fun attachChip(
        context: Context,
        parent: FrameLayout,
        clearanceFromBottomDp: Int = 87,
        open: () -> Unit
    ) {
        val chip = FrameLayout(context).apply {
            background = shape(context, pale, 19, Color.rgb(172, 217, 239))
            elevation = dp(context, 10).toFloat()
            isClickable = true
            isFocusable = true
            contentDescription = "Новые функции — открыть"
            setOnClickListener { open() }
        }
        val main = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(context, 18), dp(context, 8), dp(context, 18), dp(context, 8))
        }
        main.addView(label(context, "✦  Новые функции  ✦", 15.6f, blue, true).apply {
            gravity = Gravity.CENTER
        }, LinearLayout.LayoutParams(-1, dp(context, 27)))
        main.addView(label(context, "Откройте цифровой дом", 11.5f, ink).apply {
            gravity = Gravity.CENTER
        }, LinearLayout.LayoutParams(-1, dp(context, 20)))
        chip.addView(main, FrameLayout.LayoutParams(-1, -1))

        val sparkleLeft = label(context, "✧", 19f, Color.rgb(91, 161, 206)).apply {
            gravity = Gravity.CENTER
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
        }
        val sparkleRight = label(context, "✦", 13f, Color.rgb(104, 178, 220)).apply {
            gravity = Gravity.CENTER
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
        }
        chip.addView(sparkleLeft, FrameLayout.LayoutParams(
            dp(context, 24), dp(context, 24), Gravity.TOP or Gravity.LEFT
        ).apply { leftMargin = dp(context, -3); topMargin = dp(context, -12) })
        chip.addView(sparkleRight, FrameLayout.LayoutParams(
            dp(context, 21), dp(context, 21), Gravity.TOP or Gravity.RIGHT
        ).apply { rightMargin = dp(context, -4); topMargin = dp(context, -10) })

        parent.addView(chip, FrameLayout.LayoutParams(
            dp(context, 203), dp(context, 74), Gravity.RIGHT or Gravity.BOTTOM
        ).apply { rightMargin = dp(context, 13); bottomMargin = dp(context, clearanceFromBottomDp) })

        // Animate only the small in-app chip, never the whole store screen.
        val bob = ObjectAnimator.ofFloat(
            chip, View.TRANSLATION_Y, 0f, -dp(context, 9).toFloat(), 0f
        ).apply {
            duration = 2800L
            repeatCount = ValueAnimator.INFINITE
            interpolator = AccelerateDecelerateInterpolator()
        }
        val twinkle1 = ObjectAnimator.ofFloat(sparkleLeft, View.ALPHA, .25f, 1f, .25f).apply {
            duration = 1650L
            repeatCount = ValueAnimator.INFINITE
        }
        val twinkle2 = ObjectAnimator.ofFloat(sparkleRight, View.ALPHA, 1f, .28f, 1f).apply {
            duration = 2270L
            repeatCount = ValueAnimator.INFINITE
        }
        chip.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(view: View) = Unit
            override fun onViewDetachedFromWindow(view: View) {
                bob.cancel()
                twinkle1.cancel()
                twinkle2.cancel()
            }
        })
        bob.start()
        twinkle1.start()
        twinkle2.start()
    }

    /**
     * Modal within our own app. User can close it with X, tapping outside,
     * or Android Back. No overlay permission or access to official OMA needed.
     */
    fun attachMenu(
        context: Context,
        parent: FrameLayout,
        onDismiss: () -> Unit,
        onSelect: (String) -> Unit
    ) {
        val shade = FrameLayout(context).apply {
            setBackgroundColor(Color.argb(140, 21, 38, 56))
            isClickable = true
            setOnClickListener { onDismiss() }
        }
        val card = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            background = shape(context, pale, 22, Color.rgb(155, 208, 234))
            elevation = dp(context, 16).toFloat()
            setPadding(dp(context, 18), dp(context, 15), dp(context, 18), dp(context, 18))
            isClickable = true
            setOnClickListener { /* Do not dismiss when tapping inside the panel */ }
        }

        val top = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        top.addView(label(context, "✦", 23f, Color.rgb(95, 161, 204)),
            LinearLayout.LayoutParams(dp(context, 30), dp(context, 42)))
        top.addView(label(context, "Новые функции", 21f, blue, true),
            LinearLayout.LayoutParams(0, dp(context, 47), 1f))
        top.addView(label(context, "×", 28f, blue).apply {
            gravity = Gravity.CENTER
            isClickable = true
            isFocusable = true
            contentDescription = "Закрыть новые функции"
            setOnClickListener { onDismiss() }
        }, LinearLayout.LayoutParams(dp(context, 45), dp(context, 48)))
        card.addView(top)

        card.addView(label(context,
            "✧  Ваш дом — в одном приложении  ✧", 12.5f, Color.rgb(79, 126, 165)
        ).apply { gravity = Gravity.CENTER; setPadding(0, 0, 0, dp(context, 8)) },
            LinearLayout.LayoutParams(-1, dp(context, 39)))

        val links = listOf(
            "Паспорт дома" to "passport",
            "3D-модель дома" to "3d",
            "Поиск по фото" to "smart",
            "Знающий мастер" to "master"
        )
        links.forEachIndexed { index, (name, route) ->
            val row = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                background = shape(context, lighter, 10, Color.rgb(188, 223, 244))
                setPadding(dp(context, 16), 0, dp(context, 12), 0)
                isClickable = true
                isFocusable = true
                contentDescription = "Открыть: $name"
                setOnClickListener { onSelect(route) }
            }
            row.addView(label(context, name, 16.5f, ink, true),
                LinearLayout.LayoutParams(0, -1, 1f))
            row.addView(label(context, "›", 27f, blue).apply { gravity = Gravity.CENTER },
                LinearLayout.LayoutParams(dp(context, 24), -1))
            card.addView(row, LinearLayout.LayoutParams(-1, dp(context, 62)))
            if (index != links.lastIndex) {
                card.addView(View(context), LinearLayout.LayoutParams(1, dp(context, 9)))
            }
        }

        card.addView(label(context, "✦             ✧              ✦", 13f,
            Color.rgb(106, 167, 207)).apply {
            gravity = Gravity.CENTER
            setPadding(0, dp(context, 8), 0, 0)
        }, LinearLayout.LayoutParams(-1, dp(context, 30)))

        val width = minOf(
            dp(context, 348),
            context.resources.displayMetrics.widthPixels - dp(context, 32)
        )
        shade.addView(card, FrameLayout.LayoutParams(
            width, ViewGroup.LayoutParams.WRAP_CONTENT, Gravity.CENTER
        ))
        parent.addView(shade, FrameLayout.LayoutParams(-1, -1))

        card.alpha = 0f
        card.scaleX = .96f
        card.scaleY = .96f
        card.animate().alpha(1f).scaleX(1f).scaleY(1f).setDuration(220L).start()
    }
}
