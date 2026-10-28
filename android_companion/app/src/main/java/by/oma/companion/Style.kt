package by.oma.companion

import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

object Style {
    const val BLUE = 0xff0065ae.toInt()
    const val DARK = 0xff172f40.toInt()
    const val MUTED = 0xff607482.toInt()
    const val PALE = 0xffeaf3fa.toInt()
    const val BACK = 0xfff4f6f8.toInt()
    const val ORANGE = 0xfffb981e.toInt()

    fun dp(c: Context, v: Int): Int = (v * c.resources.displayMetrics.density + .5f).toInt()
    fun bg(color: Int, radius: Float = 14f, stroke: Int? = null): GradientDrawable =
        GradientDrawable().apply {
            setColor(color)
            cornerRadius = radius * 3
            if (stroke != null) setStroke(1, stroke)
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
            background = bg(if (filled) BLUE else PALE, 10f)
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
