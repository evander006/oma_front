package by.oma.companion

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.view.View

/** Custom line pictograms: consistent with the thin, monochrome OMA menu shown in screenshots. */
class LineIcon(context: Context, private val shape: String, private val tint: Int) : View(context) {
    private val pen=Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color=tint;style=Paint.Style.STROKE;strokeWidth=1.4f
        strokeCap=Paint.Cap.ROUND;strokeJoin=Paint.Join.ROUND
    }
    private fun Canvas.chain(vararg points:Float) {
        val p=Path();p.moveTo(points[0],points[1])
        var i=2;while(i+1<points.size){p.lineTo(points[i],points[i+1]);i+=2}
        drawPath(p,pen)
    }
    private fun Canvas.rect(l:Float,t:Float,r:Float,b:Float) {
        drawRoundRect(l,t,r,b,0.9f,0.9f,pen)
    }
    override fun onDraw(canvas:Canvas) {
        super.onDraw(canvas)
        canvas.save()
        val s=kotlin.math.min(width,height)/24f
        canvas.translate((width-24*s)/2f,(height-24*s)/2f);canvas.scale(s,s)
        when(shape) {
            "home"-> {canvas.chain(2f,11f,12f,2f,22f,11f);canvas.chain(5f,10f,5f,22f,19f,22f,19f,10f)}
            "profile"->{canvas.drawCircle(12f,12f,10f,pen);canvas.drawCircle(12f,9f,3.3f,pen);canvas.chain(5f,19f,6.5f,16f,9f,14.5f,15f,14.5f,17.5f,16f,19f,19f)}
            "grid"->{canvas.rect(2f,2f,10f,10f);canvas.rect(14f,2f,22f,10f);canvas.rect(2f,14f,10f,22f);canvas.rect(14f,14f,22f,22f)}
            "search"->{canvas.drawCircle(10f,10f,7f,pen);canvas.chain(15.5f,15.5f,22f,22f)}
            "bag"->{canvas.chain(5f,8f,4f,22f,20f,22f,19f,8f,5f,8f);canvas.chain(8f,9f,8f,6f,10f,3f,14f,3f,16f,6f,16f,9f)}
            "heart"->{val p=Path();p.moveTo(12f,21f);p.cubicTo(0f,14f,1f,5f,5f,4f);p.cubicTo(9f,2f,12f,6f,12f,6f);p.cubicTo(12f,6f,16f,2f,20f,4f);p.cubicTo(25f,9f,21f,15f,12f,21f);canvas.drawPath(p,pen)}
            "bell","bell-settings"->{canvas.chain(4f,18f,6f,16f,6f,9f,8f,5f,12f,4f,16f,5f,18f,9f,18f,16f,20f,18f,4f,18f);canvas.chain(10f,21f,14f,21f);if(shape=="bell-settings")canvas.drawCircle(20f,7f,2f,pen)}
            "receipt"->{canvas.rect(4f,2f,20f,22f);canvas.chain(8f,8f,16f,8f);canvas.chain(8f,12f,16f,12f);canvas.chain(8f,16f,14f,16f)}
            "history"->{canvas.drawArc(2f,2f,22f,22f,-128f,315f,false,pen);canvas.chain(3f,2f,3f,8f,9f,8f);canvas.chain(12f,6f,12f,12f,16f,14f)}
            "contact"->{canvas.rect(2f,4f,22f,20f);canvas.drawCircle(8f,10f,2f,pen);canvas.chain(5f,17f,5f,15f,8f,14f,11f,15f,11f,17f);canvas.chain(14f,9f,20f,9f);canvas.chain(14f,13f,20f,13f);canvas.chain(14f,17f,18f,17f)}
            "phone"->{canvas.chain(6f,3f,10f,6f,8f,10f,12f,14f,17f,16f,20f,14f,22f,18f,19f,22f,13f,21f,7f,17f,3f,11f,2f,5f,6f,3f)}
            "return"->{canvas.rect(3f,9f,19f,21f);canvas.chain(6f,9f,6f,5f,11f,2f,17f,5f,21f,8f);canvas.chain(8f,15f,11f,18f,16f,12f)}
            "store"->{canvas.chain(2f,10f,4f,3f,20f,3f,22f,10f,19f,12f,16f,10f,13f,12f,10f,10f,7f,12f,4f,10f);canvas.chain(4f,12f,4f,22f,20f,22f,20f,12f);canvas.rect(8f,15f,12f,22f);canvas.rect(14f,15f,18f,19f)}
            "compare"->{for(y in listOf(5f,10f,15f,20f)){canvas.drawCircle(3f,y,0.6f,pen);canvas.chain(7f,y,22f,y)}}
            "box"->{canvas.chain(2f,7f,12f,2f,22f,7f,12f,12f,2f,7f);canvas.chain(2f,7f,2f,18f,12f,23f,22f,18f,22f,7f);canvas.chain(12f,12f,12f,23f)}
            "hammer"->{canvas.chain(3f,21f,15f,9f);canvas.chain(12f,4f,16f,2f,22f,8f,20f,12f,15f,7f,12f,4f)}
            "back"->{canvas.chain(16f,4f,8f,12f,16f,20f)}
            "chevron"->{canvas.chain(9f,5f,16f,12f,9f,19f)}
            else->{canvas.drawCircle(12f,12f,10f,pen)}
        }
        canvas.restore()
    }
}
