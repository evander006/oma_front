package by.oma.companion

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PointF
import android.graphics.RectF
import android.view.MotionEvent
import android.view.View
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.sqrt

/**
 * Lightweight procedural room visualizer for the offline demo.
 * It is deliberately approximate: the passport currently stores area, not a measured floor plan.
 */
class Room3DView(context: Context) : View(context) {
    data class Product(val title: String, val quantity: Int, val sku: String)

    var roomName: String = "Комната"
        set(value) { field=value;invalidate() }
    var roomArea: Double = 0.0
        set(value) { field=value;invalidate() }
    var products: List<Product> = emptyList()
        set(value) { field=value;invalidate() }

    private val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { style=Paint.Style.FILL }
    private val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style=Paint.Style.STROKE;strokeWidth=2f;color=Color.rgb(108,130,145)
    }
    private val caption = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color=Color.rgb(32,51,64);textSize=15f;typeface=android.graphics.Typeface.DEFAULT_BOLD
    }
    private val small = Paint(Paint.ANTI_ALIAS_FLAG).apply {color=Color.rgb(57,74,86);textSize=11f}
    private var orientation = 0
    private var downX = 0f

    private fun path(vararg points: PointF) = Path().apply {
        if(points.isNotEmpty()) moveTo(points[0].x,points[0].y)
        for(i in 1 until points.size) lineTo(points[i].x,points[i].y)
        close()
    }
    private fun shade(color:Int,factor:Float):Int = Color.rgb(
        (Color.red(color)*factor).toInt().coerceIn(0,255),
        (Color.green(color)*factor).toInt().coerceIn(0,255),
        (Color.blue(color)*factor).toInt().coerceIn(0,255))

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        canvas.drawColor(Color.rgb(238,244,248))
        val w=width.toFloat();val h=height.toFloat()
        caption.textSize=max(14f,w/25f)
        small.textSize=max(10f,w/38f)
        canvas.drawText(roomName,20f,30f,caption)
        canvas.drawText("≈ ${String.format(java.util.Locale("ru","RU"),"%.1f",roomArea)} м² · проведите влево/вправо для поворота",20f,50f,small)

        val left=PointF(w*.12f,h*.73f)
        val top=PointF(w*.49f,h*.48f)
        val right=PointF(w*.90f,h*.70f)
        val bottom=PointF(w*.51f,h*.94f)
        val wallHeight=h*.36f
        val upperLeft=PointF(left.x,left.y-wallHeight)
        val upperTop=PointF(top.x,top.y-wallHeight)
        val upperRight=PointF(right.x,right.y-wallHeight)

        fill.color=if(orientation%2==0) Color.rgb(250,246,236) else Color.rgb(239,247,250)
        canvas.drawPath(path(left,top,right,bottom),fill)
        canvas.drawPath(path(left,top,upperTop,upperLeft),Paint(fill).apply{color=Color.rgb(224,235,242)})
        canvas.drawPath(path(top,right,upperRight,upperTop),Paint(fill).apply{color=Color.rgb(211,226,236)})
        canvas.drawPath(path(left,top,right,bottom),stroke)
        canvas.drawPath(path(left,top,upperTop,upperLeft),stroke)
        canvas.drawPath(path(top,right,upperRight,upperTop),stroke)

        // Approximate metre grid. Area determines density, not a fabricated exact contour.
        val cells=ceil(sqrt(roomArea.coerceAtLeast(4.0))).toInt().coerceIn(2,8)
        stroke.color=Color.argb(75,90,112,126);stroke.strokeWidth=1f
        for(i in 1 until cells){
            val t=i.toFloat()/cells
            canvas.drawLine(lerp(left,top,t).x,lerp(left,top,t).y,lerp(bottom,right,t).x,lerp(bottom,right,t).y,stroke)
            canvas.drawLine(lerp(left,bottom,t).x,lerp(left,bottom,t).y,lerp(top,right,t).x,lerp(top,right,t).y,stroke)
        }
        stroke.color=Color.rgb(108,130,145);stroke.strokeWidth=2f

        // Door and window are indicative until the passport gains exact wall positions.
        fill.color=Color.rgb(156,204,227)
        canvas.drawRect(w*.57f,h*.19f,w*.75f,h*.34f,fill)
        canvas.drawRect(w*.58f,h*.20f,w*.74f,h*.33f,Paint(stroke).apply{style=Paint.Style.STROKE})
        fill.color=Color.rgb(190,142,93)
        canvas.drawRect(w*.16f,h*.48f,w*.25f,h*.73f,fill)

        val visible=products.flatMap { p -> List(p.quantity.coerceIn(1,4)){p} }.take(8)
        visible.forEachIndexed { index, product ->
            val col=index%3;val row=index/3
            val cx=w*(.30f+col*.19f) + if(row%2==0) 0f else w*.07f
            val cy=h*(.70f+row*.075f)
            drawProduct(canvas,product,cx,cy,w*.105f,h*.095f,index)
        }
        if(visible.isEmpty()){
            fill.color=Color.argb(210,255,255,255)
            canvas.drawRoundRect(RectF(w*.24f,h*.58f,w*.77f,h*.67f),16f,16f,fill)
            small.textAlign=Paint.Align.CENTER
            canvas.drawText("В этой комнате пока нет размещённых покупок ОМА",w*.505f,h*.63f,small)
            small.textAlign=Paint.Align.LEFT
        }
        canvas.drawText("Модель приблизительная: точность повысится после добавления обмеров и планировки.",20f,h-12f,small)
    }

    private fun drawProduct(canvas:Canvas,p:Product,cx:Float,cy:Float,bw:Float,bh:Float,index:Int){
        val title=p.title.lowercase()
        if(drawDetailedExample(canvas,p,title,cx,cy,bw,bh)) return
        val base=when{
            listOf("ламп","свет","люстр").any{title.contains(it)}->Color.rgb(244,191,57)
            listOf("смес","труб","сантех","шланг").any{title.contains(it)}->Color.rgb(89,157,194)
            listOf("ламинат","покрытие","пвх").any{title.contains(it)}->Color.rgb(171,126,80)
            listOf("стул","табур","мебел").any{title.contains(it)}->Color.rgb(142,97,68)
            listOf("дрел","инструмент","аккумулятор").any{title.contains(it)}->Color.rgb(224,119,44)
            else->listOf(Color.rgb(82,145,184),Color.rgb(102,164,125),Color.rgb(170,115,163))[index%3]
        }
        if(listOf("ламинат","покрытие","пвх").any{title.contains(it)}){
            fill.color=Color.argb(190,Color.red(base),Color.green(base),Color.blue(base))
            canvas.drawPath(path(PointF(cx-bw,cy),PointF(cx,cy-bh*.45f),PointF(cx+bw,cy),PointF(cx,cy+bh*.45f)),fill)
        }else{
            val a=PointF(cx-bw*.5f,cy);val b=PointF(cx,cy-bh*.28f);val c=PointF(cx+bw*.5f,cy);val d=PointF(cx,cy+bh*.28f)
            val lift=bh*.65f
            fill.color=base;canvas.drawPath(path(PointF(a.x,a.y-lift),PointF(b.x,b.y-lift),PointF(c.x,c.y-lift),PointF(d.x,d.y-lift)),fill)
            fill.color=shade(base,.78f);canvas.drawPath(path(a,d,PointF(d.x,d.y-lift),PointF(a.x,a.y-lift)),fill)
            fill.color=shade(base,.62f);canvas.drawPath(path(d,c,PointF(c.x,c.y-lift),PointF(d.x,d.y-lift)),fill)
        }
        val name=if(p.title.length>18)p.title.take(17)+"…" else p.title
        small.textAlign=Paint.Align.CENTER
        canvas.drawText(name,cx,cy+bh*.62f,small)
        small.textAlign=Paint.Align.LEFT
    }

    /** A few procedural sample assets demonstrate how catalog products can gain generated geometry. */
    private fun drawDetailedExample(canvas:Canvas,p:Product,title:String,cx:Float,cy:Float,bw:Float,bh:Float):Boolean{
        when{
            title.contains("аэрогрил")->{
                // Rounded dark appliance body, basket, display and handle.
                fill.color=Color.rgb(51,57,61)
                canvas.drawRoundRect(RectF(cx-bw*.48f,cy-bh*.80f,cx+bw*.48f,cy+bh*.16f),bw*.16f,bw*.16f,fill)
                fill.color=Color.rgb(17,23,27)
                canvas.drawRoundRect(RectF(cx-bw*.38f,cy-bh*.60f,cx+bw*.38f,cy-bh*.16f),8f,8f,fill)
                fill.color=Color.rgb(72,174,211)
                canvas.drawCircle(cx,cy-bh*.43f,bw*.09f,fill)
                stroke.color=Color.rgb(30,35,39);stroke.strokeWidth=5f
                canvas.drawLine(cx-bw*.20f,cy+bh*.15f,cx+bw*.20f,cy+bh*.15f,stroke)
                labelProduct(canvas,p,cx,cy+bh*.48f)
                return true
            }
            title.contains("табур") || title.contains("стул")->{
                // Seat and four legs.
                fill.color=Color.rgb(172,119,76)
                canvas.drawPath(path(PointF(cx-bw*.52f,cy-bh*.48f),PointF(cx,cy-bh*.72f),PointF(cx+bw*.52f,cy-bh*.48f),PointF(cx,cy-bh*.20f)),fill)
                stroke.color=Color.rgb(107,70,43);stroke.strokeWidth=5f
                listOf(-.38f,-.15f,.15f,.38f).forEachIndexed{i,x->
                    val topY=if(i%2==0)cy-bh*.40f else cy-bh*.28f
                    canvas.drawLine(cx+bw*x,topY,cx+bw*x*.86f,cy+bh*.28f,stroke)
                }
                labelProduct(canvas,p,cx,cy+bh*.55f)
                return true
            }
            title.contains("светиль") || title.contains("люстр") || title.contains("ламп")->{
                stroke.color=Color.rgb(70,78,83);stroke.strokeWidth=3f
                canvas.drawLine(cx,cy-bh*1.55f,cx,cy-bh*.72f,stroke)
                fill.color=Color.rgb(251,202,75)
                canvas.drawPath(path(PointF(cx-bw*.42f,cy-bh*.45f),PointF(cx-bw*.23f,cy-bh*.80f),PointF(cx+bw*.23f,cy-bh*.80f),PointF(cx+bw*.42f,cy-bh*.45f)),fill)
                fill.color=Color.argb(65,255,220,107);canvas.drawCircle(cx,cy-bh*.30f,bw*.62f,fill)
                labelProduct(canvas,p,cx,cy+bh*.48f)
                return true
            }
        }
        return false
    }
    private fun labelProduct(canvas:Canvas,p:Product,x:Float,y:Float){
        val name=if(p.title.length>18)p.title.take(17)+"…" else p.title
        small.textAlign=Paint.Align.CENTER;canvas.drawText(name,x,y,small);small.textAlign=Paint.Align.LEFT
    }
    private fun lerp(a:PointF,b:PointF,t:Float)=PointF(a.x+(b.x-a.x)*t,a.y+(b.y-a.y)*t)

    override fun onTouchEvent(event: MotionEvent): Boolean {
        when(event.actionMasked){
            MotionEvent.ACTION_DOWN->{downX=event.x;return true}
            MotionEvent.ACTION_UP->{
                if(kotlin.math.abs(event.x-downX)>45f){orientation=(orientation+if(event.x>downX)1 else 3)%4;invalidate()}
                return true
            }
        }
        return true
    }
}
