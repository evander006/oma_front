package by.oma.companion

import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.StateListDrawable
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

object Style {
    const val BRAND_RED = 0xffdf0a15.toInt()
    const val BRAND_RED_DARK = 0xffb90710.toInt()
    const val BRAND_RED_SOFT = 0xffffecee.toInt()
    // Kept as a compatibility alias for existing feature modules.
    const val BLUE = BRAND_RED
    const val DARK = 0xff252a2e.toInt()
    const val MUTED = 0xff697177.toInt()
    const val PALE = BRAND_RED_SOFT
    const val BACK = 0xfff5f5f3.toInt()
    const val SURFACE = 0xffffffff.toInt()
    const val BORDER = 0xffdedfdd.toInt()
    const val PRESSED = 0xfff1f1ef.toInt()
    const val ORANGE = 0xfffb981e.toInt()

    fun dp(c: Context, v: Int): Int = (v * c.resources.displayMetrics.density + .5f).toInt()
    fun bg(color: Int, radius: Float = 14f, stroke: Int? = null): GradientDrawable =
        GradientDrawable().apply {
            setColor(color)
            cornerRadius = radius * 3
            if (stroke != null) setStroke(1, stroke)
        }
    fun interactiveBg(
        color: Int,
        pressed: Int = PRESSED,
        radius: Float = 12f,
        stroke: Int? = null
    ): StateListDrawable = StateListDrawable().apply {
        addState(intArrayOf(android.R.attr.state_pressed), bg(pressed, radius, stroke))
        addState(intArrayOf(android.R.attr.state_focused), bg(pressed, radius, BRAND_RED))
        addState(intArrayOf(), bg(color, radius, stroke))
    }
    fun text(c: Context, value: String, size: Float = 15f, bold: Boolean = false, color: Int = DARK): TextView =
        TextView(c).apply {
            text = value
            textSize = size
            setTextColor(color)
            setPadding(dp(c, 2), dp(c, 5), dp(c, 2), dp(c, 5))
            if (bold) setTypeface(null, Typeface.BOLD)
        }
    fun button(c: Context, name: String, action: () -> Unit, filled: Boolean = true): Button =
        Button(c).apply {
            text = name
            textSize = 13f
            isAllCaps = false
            setTextColor(if (filled) Color.WHITE else BLUE)
            background = interactiveBg(
                if (filled) BRAND_RED else Color.WHITE,
                if (filled) BRAND_RED_DARK else BRAND_RED_SOFT,
                10f,
                if (filled) BRAND_RED else BORDER
            )
            minHeight = dp(c, 48)
            isAllCaps = false
            letterSpacing = .01f
            stateListAnimator = null
            isFocusable = true
            contentDescription = name
            setOnClickListener { action() }
        }
    fun column(c: Context): LinearLayout = LinearLayout(c).apply {
        orientation = LinearLayout.VERTICAL
        setPadding(dp(c, 16), dp(c, 12), dp(c, 16), dp(c, 16))
    }
    fun gap(c: Context, px: Int = 8): View = View(c).apply {
        layoutParams = LinearLayout.LayoutParams(1, dp(c, px))
    }
}
