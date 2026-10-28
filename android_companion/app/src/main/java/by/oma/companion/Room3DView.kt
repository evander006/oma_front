package by.oma.companion

import android.content.Context
import android.graphics.Color
import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.opengl.Matrix
import android.view.MotionEvent
import android.view.ScaleGestureDetector
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import kotlin.math.cos
import kotlin.math.sin

/** Real GPU-rendered 3D room: orbit with one finger and zoom with two fingers. */
class Room3DView(context: Context) : GLSurfaceView(context) {
    data class Product(val title: String, val quantity: Int, val sku: String)
    private val scene = SceneRenderer()
    private val scaleDetector = ScaleGestureDetector(context, object : ScaleGestureDetector.SimpleOnScaleGestureListener() {
        override fun onScale(detector: ScaleGestureDetector): Boolean {
            scene.distance = (scene.distance / detector.scaleFactor).coerceIn(3.4f, 13f)
            requestRender();return true
        }
    })
    private var lastX=0f
    private var lastY=0f
    var roomName:String
        get()=scene.roomName
        set(value){scene.roomName=value;requestRender()}
    var roomArea:Double
        get()=scene.roomArea
        set(value){scene.roomArea=value;requestRender()}
    var roomWidth:Double get()=scene.roomWidth set(value){scene.roomWidth=value;requestRender()}
    var roomLength:Double get()=scene.roomLength set(value){scene.roomLength=value;requestRender()}
    var roomHeight:Double get()=scene.roomHeight set(value){scene.roomHeight=value;requestRender()}
    var doorWall:String get()=scene.doorWall set(value){scene.doorWall=value;requestRender()}
    var windowWall:String get()=scene.windowWall set(value){scene.windowWall=value;requestRender()}
    var products:List<Product>
        get()=scene.products
        set(value){scene.products=value.toList();requestRender()}

    init {
        setEGLContextClientVersion(2);setRenderer(scene);renderMode=RENDERMODE_WHEN_DIRTY
        preserveEGLContextOnPause=true
    }
    override fun onTouchEvent(event:MotionEvent):Boolean{
        scaleDetector.onTouchEvent(event)
        if(!scaleDetector.isInProgress){
            when(event.actionMasked){
                MotionEvent.ACTION_DOWN->{lastX=event.x;lastY=event.y}
                MotionEvent.ACTION_MOVE->{
                    scene.yaw=(scene.yaw+(event.x-lastX)*.35f)%360f
                    scene.pitch=(scene.pitch+(event.y-lastY)*.25f).coerceIn(8f,82f)
                    lastX=event.x;lastY=event.y;requestRender()
                }
            }
        }
        return true
    }

    private class SceneRenderer:GLSurfaceView.Renderer{
        @Volatile var roomName="Комната"
        @Volatile var roomArea=0.0
        @Volatile var roomWidth=0.0
        @Volatile var roomLength=0.0
        @Volatile var roomHeight=2.7
        @Volatile var doorWall="Левая"
        @Volatile var windowWall="Задняя"
        @Volatile var products:List<Product> = emptyList()
        @Volatile var yaw=42f
        @Volatile var pitch=32f
        @Volatile var distance=7.4f
        private var program=0;private var positionHandle=0;private var matrixHandle=0;private var colorHandle=0
        private val projection=FloatArray(16);private val view=FloatArray(16);private val model=FloatArray(16)
        private val vp=FloatArray(16);private val mvp=FloatArray(16)
        private val cube:FloatBuffer by lazy{
            ByteBuffer.allocateDirect(CUBE.size*4).order(ByteOrder.nativeOrder()).asFloatBuffer().apply{put(CUBE);position(0)}
        }
        override fun onSurfaceCreated(gl:javax.microedition.khronos.opengles.GL10?,config:javax.microedition.khronos.egl.EGLConfig?){
            GLES20.glClearColor(.91f,.95f,.97f,1f);GLES20.glEnable(GLES20.GL_DEPTH_TEST);GLES20.glEnable(GLES20.GL_CULL_FACE)
            program=link(VERTEX_SHADER,FRAGMENT_SHADER);positionHandle=GLES20.glGetAttribLocation(program,"aPosition")
            matrixHandle=GLES20.glGetUniformLocation(program,"uMvp");colorHandle=GLES20.glGetUniformLocation(program,"uColor")
        }
        override fun onSurfaceChanged(gl:javax.microedition.khronos.opengles.GL10?,width:Int,height:Int){
            GLES20.glViewport(0,0,width,height);Matrix.perspectiveM(projection,0,45f,width.toFloat()/height.coerceAtLeast(1),.1f,40f)
        }
        override fun onDrawFrame(gl:javax.microedition.khronos.opengles.GL10?){
            GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT or GLES20.GL_DEPTH_BUFFER_BIT);GLES20.glUseProgram(program)
            val yr=Math.toRadians(yaw.toDouble());val pr=Math.toRadians(pitch.toDouble())
            val eyeX=(distance*cos(pr)*sin(yr)).toFloat();val eyeY=(distance*sin(pr)).toFloat()+.8f
            val eyeZ=(distance*cos(pr)*cos(yr)).toFloat()
            Matrix.setLookAtM(view,0,eyeX,eyeY,eyeZ,0f,.7f,0f,0f,1f,0f);Matrix.multiplyMM(vp,0,projection,0,view,0)
            drawRoom();drawProducts()
        }
        private fun drawRoom(){
            val ratio=(roomArea.coerceAtLeast(6.0)/16.0).toFloat().coerceIn(.55f,2.1f)
            val width=(if(roomWidth>0)roomWidth.toFloat() else 4.2f*ratio.coerceAtMost(1.35f)).coerceIn(2.2f,7f)
            val depth=(if(roomLength>0)roomLength.toFloat() else 4f*(1f/ratio).coerceIn(.72f,1.45f)).coerceIn(2.2f,7f)
            val height=roomHeight.toFloat().coerceIn(2.2f,4.2f)
            drawCube(0f,-.08f,0f,width,.12f,depth,Color.rgb(202,174,132))
            drawCube(0f,height/2f,-depth/2f,width,height,.10f,Color.rgb(219,232,240))
            drawCube(-width/2f,height/2f,0f,.10f,height,depth,Color.rgb(204,221,232))
            drawOpening(windowWall,true,width,depth,height)
            drawOpening(doorWall,false,width,depth,height)
            drawCube(0f,.08f,-depth/2f+.08f,width,.14f,.08f,Color.rgb(238,241,243))
            drawCube(-width/2f+.08f,.08f,0f,.08f,.14f,depth,Color.rgb(238,241,243))
        }
        private fun drawOpening(wall:String,window:Boolean,width:Float,depth:Float,height:Float){
            if(wall=="Нет")return
            val w=if(window)1.25f else 1.0f;val h=if(window).86f else 2.05f
            val y=if(window)(height*.62f).coerceIn(1.35f,height-.5f) else h/2f
            val frame=if(window)Color.rgb(85,119,139) else Color.rgb(145,92,52)
            val fill=if(window)Color.rgb(115,193,224) else Color.rgb(119,76,47)
            when(wall){
                "Задняя"->{drawCube(.55f,y,-depth/2f+.065f,w+.18f,h+.18f,.035f,frame);drawCube(.55f,y,-depth/2f+.09f,w,h,.025f,fill)}
                "Левая"->{drawCube(-width/2f+.065f,y,.55f,.035f,h+.18f,w+.18f,frame);drawCube(-width/2f+.09f,y,.55f,.025f,h,w,fill)}
                "Правая"->{drawCube(width/2f-.065f,y,-.55f,.035f,h+.18f,w+.18f,frame);drawCube(width/2f-.09f,y,-.55f,.025f,h,w,fill)}
                "Передняя"->{drawCube(-.55f,y,depth/2f-.065f,w+.18f,h+.18f,.035f,frame);drawCube(-.55f,y,depth/2f-.09f,w,h,.025f,fill)}
            }
        }
        private fun drawProducts(){
            products.flatMap{p->List(p.quantity.coerceIn(1,4)){p}}.take(10).forEachIndexed{index,p->
                val x=-1.25f+(index%4)*.82f;val z=-.85f+(index/4)*.88f;val t=p.title.lowercase()
                when{
                    t.contains("аэрогрил")->drawAirFryer(x,z)
                    t.contains("табур")||t.contains("стул")->drawStool(x,z)
                    t.contains("светиль")||t.contains("люстр")||t.contains("ламп")->drawLamp(x,z)
                    t.contains("ламинат")||t.contains("покрытие")||t.contains("пвх")->drawFloorPack(x,z)
                    else->drawGeneric(x,z,index)
                }
            }
        }
        private fun drawAirFryer(x:Float,z:Float){
            drawCube(x,.47f,z,.68f,.86f,.58f,Color.rgb(42,47,50));drawCube(x,.57f,z+.301f,.51f,.34f,.035f,Color.rgb(15,20,23))
            drawCube(x,.63f,z+.325f,.16f,.11f,.025f,Color.rgb(47,170,219));drawCube(x,.32f,z+.36f,.32f,.07f,.16f,Color.rgb(24,28,30))
            drawCube(x,.91f,z,.55f,.08f,.45f,Color.rgb(76,81,83))
        }
        private fun drawStool(x:Float,z:Float){
            drawCube(x,.72f,z,.72f,.13f,.64f,Color.rgb(160,106,67))
            listOf(-.27f to -.23f,.27f to -.23f,-.27f to .23f,.27f to .23f).forEach{(dx,dz)->drawCube(x+dx,.37f,z+dz,.10f,.70f,.10f,Color.rgb(103,66,41))}
            drawCube(x,.35f,z,.58f,.07f,.08f,Color.rgb(117,74,44))
        }
        private fun drawLamp(x:Float,z:Float){
            drawCube(x,.06f,z,.55f,.10f,.55f,Color.rgb(82,87,90));drawCube(x,.82f,z,.07f,1.48f,.07f,Color.rgb(65,70,73))
            drawCube(x,1.48f,z,.62f,.42f,.62f,Color.rgb(244,194,57));drawCube(x,1.22f,z,.25f,.12f,.25f,Color.rgb(255,239,174))
        }
        private fun drawFloorPack(x:Float,z:Float){for(i in 0..4)drawCube(x-.28f+i*.14f,.045f,z,.12f,.07f,.75f,Color.rgb(169+i*5,120+i*3,76))}
        private fun drawGeneric(x:Float,z:Float,index:Int){
            val colors=intArrayOf(Color.rgb(72,139,181),Color.rgb(91,159,115),Color.rgb(166,105,156),Color.rgb(220,127,54))
            drawCube(x,.32f,z,.55f,.62f,.55f,colors[index%colors.size]);drawCube(x,.68f,z,.38f,.10f,.38f,Color.rgb(235,239,242))
        }
        private fun drawCube(x:Float,y:Float,z:Float,sx:Float,sy:Float,sz:Float,color:Int){
            Matrix.setIdentityM(model,0);Matrix.translateM(model,0,x,y,z);Matrix.scaleM(model,0,sx,sy,sz);Matrix.multiplyMM(mvp,0,vp,0,model,0)
            cube.position(0);GLES20.glEnableVertexAttribArray(positionHandle);GLES20.glVertexAttribPointer(positionHandle,3,GLES20.GL_FLOAT,false,0,cube)
            GLES20.glUniformMatrix4fv(matrixHandle,1,false,mvp,0);GLES20.glUniform4f(colorHandle,Color.red(color)/255f,Color.green(color)/255f,Color.blue(color)/255f,1f)
            GLES20.glDrawArrays(GLES20.GL_TRIANGLES,0,36);GLES20.glDisableVertexAttribArray(positionHandle)
        }
        private fun link(vertex:String,fragment:String):Int{
            fun shader(type:Int,source:String):Int=GLES20.glCreateShader(type).also{s->GLES20.glShaderSource(s,source);GLES20.glCompileShader(s)}
            return GLES20.glCreateProgram().also{p->GLES20.glAttachShader(p,shader(GLES20.GL_VERTEX_SHADER,vertex));GLES20.glAttachShader(p,shader(GLES20.GL_FRAGMENT_SHADER,fragment));GLES20.glLinkProgram(p)}
        }
        companion object{
            private const val VERTEX_SHADER="attribute vec4 aPosition;uniform mat4 uMvp;void main(){gl_Position=uMvp*aPosition;}"
            private const val FRAGMENT_SHADER="precision mediump float;uniform vec4 uColor;void main(){gl_FragColor=uColor;}"
            private val CUBE=floatArrayOf(
                -.5f,-.5f,.5f,.5f,-.5f,.5f,.5f,.5f,.5f,-.5f,-.5f,.5f,.5f,.5f,.5f,-.5f,.5f,.5f,
                .5f,-.5f,-.5f,-.5f,-.5f,-.5f,-.5f,.5f,-.5f,.5f,-.5f,-.5f,-.5f,.5f,-.5f,.5f,.5f,-.5f,
                -.5f,-.5f,-.5f,-.5f,-.5f,.5f,-.5f,.5f,.5f,-.5f,-.5f,-.5f,-.5f,.5f,.5f,-.5f,.5f,-.5f,
                .5f,-.5f,.5f,.5f,-.5f,-.5f,.5f,.5f,-.5f,.5f,-.5f,.5f,.5f,.5f,-.5f,.5f,.5f,.5f,
                -.5f,.5f,.5f,.5f,.5f,.5f,.5f,.5f,-.5f,-.5f,.5f,.5f,.5f,.5f,-.5f,-.5f,.5f,-.5f,
                -.5f,-.5f,-.5f,.5f,-.5f,-.5f,.5f,-.5f,.5f,-.5f,-.5f,-.5f,.5f,-.5f,.5f,-.5f,-.5f,.5f)
        }
    }
}
