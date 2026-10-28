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
 * twinkles. A full-screen scrim and light blue list are only displayed after
 * a customer explicitly taps the chip and is locally signed in.
 */
object FloatingFeatures {
    private val blue = Style.BRAND_RED
    private val ink = Style.DARK
    private val pale = Color.argb(246, 232, 243, 255)
    private val lighter = Color.argb(248, 246, 250, 255)
    private val sky = Color.rgb(236, 246, 255)
    private val skyDeep = Color.rgb(205, 229, 252)
    private val skyLine = Color.rgb(150, 198, 243)
    private val sparkA = Color.rgb(46, 150, 240)
    private val sparkB = Color.rgb(110, 190, 250)

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
        // Outer frame is unclipped so sparkles can poke out; the face clips the shine sweep.
        val chip = FrameLayout(context).apply {
            clipChildren = false
            clipToPadding = false
            isClickable = true
            isFocusable = true
            contentDescription = "Новые функции — открыть"
            setOnClickListener { open() }
        }
        val face = FrameLayout(context).apply {
            background = GradientDrawable(GradientDrawable.Orientation.TL_BR, intArrayOf(sky, skyDeep)).apply {
                cornerRadius = dp(context, 19).toFloat()
                setStroke(dp(context, 1), skyLine)
            }
            elevation = dp(context, 10).toFloat()
            clipToOutline = true
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
        face.addView(main, FrameLayout.LayoutParams(-1, -1))
        val shine = View(context).apply {
            background = GradientDrawable(GradientDrawable.Orientation.LEFT_RIGHT,
                intArrayOf(Color.TRANSPARENT, Color.argb(150, 255, 255, 255), Color.TRANSPARENT))
            rotation = 18f
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
        }
        face.addView(shine, FrameLayout.LayoutParams(dp(context, 46), dp(context, 120), Gravity.CENTER_VERTICAL))
        chip.addView(face, FrameLayout.LayoutParams(-1, -1))

        fun sparkle(glyph: String, size: Float, color: Int, w: Int, gravity: Int, side: Int, top: Int) =
            label(context, glyph, size, color).apply {
                this.gravity = Gravity.CENTER
                elevation = dp(context, 11).toFloat()
                importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
                chip.addView(this, FrameLayout.LayoutParams(dp(context, w), dp(context, w), gravity).apply {
                    topMargin = dp(context, top)
                    if ((gravity and Gravity.RIGHT) == Gravity.RIGHT) rightMargin = dp(context, side) else leftMargin = dp(context, side)
                })
            }
        val sparkleLeft = sparkle("✧", 19f, sparkA, 24, Gravity.TOP or Gravity.LEFT, -3, -12)
        val sparkleRight = sparkle("✦", 13f, sparkB, 21, Gravity.TOP or Gravity.RIGHT, -4, -10)
        val sparkleBottom = sparkle("✦", 11f, sparkA, 18, Gravity.BOTTOM or Gravity.RIGHT, 22, 0).apply {
            (layoutParams as FrameLayout.LayoutParams).bottomMargin = dp(context, -7)
        }

        parent.addView(chip, FrameLayout.LayoutParams(
            dp(context, 203), dp(context, 74), Gravity.RIGHT or Gravity.BOTTOM
        ).apply { rightMargin = dp(context, 13); bottomMargin = dp(context, clearanceFromBottomDp) })

        // Animate only the small in-app chip, never the whole store screen.
        val animators = mutableListOf<android.animation.Animator>()
        animators += ObjectAnimator.ofFloat(
            chip, View.TRANSLATION_Y, 0f, -dp(context, 10).toFloat(), 0f
        ).apply {
            duration = 2400L
            repeatCount = ValueAnimator.INFINITE
            interpolator = AccelerateDecelerateInterpolator()
        }
        listOf(Triple(sparkleLeft, 1650L, 0L), Triple(sparkleRight, 2270L, 400L),
            Triple(sparkleBottom, 1900L, 900L)).forEach { (star, period, delay) ->
            animators += ObjectAnimator.ofPropertyValuesHolder(star,
                android.animation.PropertyValuesHolder.ofFloat(View.ALPHA, .2f, 1f, .2f),
                android.animation.PropertyValuesHolder.ofFloat(View.SCALE_X, .6f, 1.25f, .6f),
                android.animation.PropertyValuesHolder.ofFloat(View.SCALE_Y, .6f, 1.25f, .6f),
                android.animation.PropertyValuesHolder.ofFloat(View.ROTATION, 0f, 45f, 90f)
            ).apply {
                duration = period
                startDelay = delay
                repeatCount = ValueAnimator.INFINITE
            }
        }
        // Glint sweeps across the chip every ~3s.
        animators += ObjectAnimator.ofFloat(shine, View.TRANSLATION_X,
            -dp(context, 70).toFloat(), dp(context, 250).toFloat()).apply {
            duration = 3200L
            repeatCount = ValueAnimator.INFINITE
            interpolator = android.view.animation.PathInterpolator(.6f, 0f, .4f, 1f)
        }
        chip.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(view: View) = Unit
            override fun onViewDetachedFromWindow(view: View) { animators.forEach { it.cancel() } }
        })
        animators.forEach { it.start() }
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
            background = shape(context, pale, 22, skyLine)
            elevation = dp(context, 16).toFloat()
            setPadding(dp(context, 18), dp(context, 15), dp(context, 18), dp(context, 18))
            isClickable = true
            setOnClickListener { /* Do not dismiss when tapping inside the panel */ }
        }

        val top = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        top.addView(label(context, "✦", 23f, sparkA),
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
            "✧  Ваш дом — в одном приложении  ✧", 12.5f, Style.MUTED
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
                background = shape(context, lighter, 10, Color.rgb(204, 226, 248))
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
            sparkB).apply {
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
