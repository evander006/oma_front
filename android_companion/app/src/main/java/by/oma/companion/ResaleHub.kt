package by.oma.companion

import android.app.Activity
import android.graphics.Color
import android.graphics.Typeface
import android.text.InputType
import android.view.Gravity
import android.view.View
import android.widget.*
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID

/** Local second-hand demo: resell things you already own. Nothing leaves the device. */
class ResaleHub(
    private val activity:Activity,
    private val navigate:(String)->Unit,
    private val purchases:()->JSONArray
){
    private val blue=Style.BLUE
    private val ink=Style.DARK
    private val line=Style.BORDER
    private val green=Color.rgb(46,132,82)
    private val prefs=activity.getSharedPreferences("oma_resale_hub",Activity.MODE_PRIVATE)
    private var selectedId=""
    private val date=SimpleDateFormat("dd.MM.yyyy",Locale("ru","RU"))
    private val conditions=listOf("Как новое","Отличное","Хорошее","Есть следы использования")

    data class Listing(val id:String,val title:String,val condition:String,val price:Double,
        val seller:String,val district:String,val about:String,val mine:Boolean,val sold:Boolean,val created:Long)

    private val market=listOf(
        Listing("d1","Шуруповёрт аккумуляторный, 2 АКБ","Отличное",95.0,"Игорь","Минск, Фрунзенский",
            "Пользовался пару раз при ремонте. Полный комплект, кейс.",false,false,0),
        Listing("d2","Смеситель для кухни","Как новое",48.0,"Анна","Минск, Московский",
            "Не подошёл по цвету, в упаковке.",false,false,0),
        Listing("d3","Ламинат 33 класс, 2 упаковки","Как новое",60.0,"Павел","Минск, Заводской",
            "Остаток после ремонта, дуб светлый.",false,false,0),
        Listing("d4","Люстра потолочная, 5 плафонов","Хорошее",70.0,"Елена","Минск, Центральный",
            "Рабочая, сняли после смены интерьера.",false,false,0),
        Listing("d5","Краска интерьерная белая, 9 л","Как новое",35.0,"Олег","Минск, Партизанский",
            "Открыта, использовано около литра.",false,false,0)
    )

    private fun dp(n:Int)=Style.dp(activity,n)
    private fun text(value:String,size:Float=15f,bold:Boolean=false,color:Int=ink)=TextView(activity).apply{
        text=value;textSize=size;setTextColor(color);gravity=Gravity.CENTER_VERTICAL;includeFontPadding=false
        if(bold)setTypeface(null,Typeface.BOLD)
    }
    private fun heading(body:LinearLayout,value:String)=body.addView(text(value,21f,true).apply{setPadding(dp(16),dp(20),dp(16),dp(12))})
    private fun note(body:LinearLayout,value:String)=body.addView(text(value,13f,false,Color.GRAY).apply{setPadding(dp(16),dp(5),dp(16),dp(13))})
    private fun button(body:LinearLayout,value:String,filled:Boolean=true,action:()->Unit){
        body.addView(text(value,15f,true,if(filled)Color.WHITE else blue).apply{
            gravity=Gravity.CENTER
            background=Style.interactiveBg(if(filled)blue else Color.WHITE,
                if(filled)Style.BRAND_RED_DARK else Style.BRAND_RED_SOFT,8f,
                if(filled)blue else line)
            isClickable=true;isFocusable=true;contentDescription=value
            setOnClickListener{action()}
        },LinearLayout.LayoutParams(-1,dp(50)).apply{leftMargin=dp(16);rightMargin=dp(16);topMargin=dp(7);bottomMargin=dp(7)})
    }
    private fun divider(body:LinearLayout)=body.addView(View(activity).apply{setBackgroundColor(line)},LinearLayout.LayoutParams(-1,dp(1)))
    private fun price(value:Double)=if(value%1.0==0.0)"${value.toInt()} BYN" else String.format(Locale("ru","RU"),"%.2f BYN",value)

    fun title(screen:String)=when(screen){"resale:new"->"Продать вещь";"resale:detail"->"Объявление";else->"Секонд-хэнд"}
    fun back(screen:String)=when(screen){"resale:new","resale:detail"->"resale:hub";else->""}
    fun render(screen:String,body:LinearLayout){when(screen){
        "resale:new"->sell(body);"resale:detail"->detail(body);else->list(body)
    }}

    private fun stored():JSONArray=runCatching{JSONArray(prefs.getString("listings","[]"))}.getOrDefault(JSONArray())
    private fun mine():List<Listing>{
        val items=stored();val result=mutableListOf<Listing>()
        for(i in 0 until items.length()){val o=items.optJSONObject(i)?:continue
            result+=Listing(o.optString("id"),o.optString("title"),o.optString("condition"),o.optDouble("price",0.0),
                "Вы","Минск",o.optString("about"),true,o.optBoolean("sold"),o.optLong("created"))
        }
        return result.sortedByDescending{it.created}
    }
    private fun update(id:String,change:(JSONObject?)->Boolean){
        val items=stored();val next=JSONArray()
        for(i in 0 until items.length()){val o=items.optJSONObject(i)?:continue
            if(o.optString("id")!=id||change(o))next.put(o)
        }
        prefs.edit().putString("listings",next.toString()).apply()
    }

    private fun list(body:LinearLayout){
        heading(body,"Продайте то, что уже есть дома")
        note(body,"Мебель, техника, инструмент и остатки материалов. Объявления хранятся только на этом устройстве.")
        button(body,"+  Продать вещь"){navigate("resale:new")}
        val own=mine()
        if(own.isNotEmpty()){
            heading(body,"Мои объявления")
            own.forEach{card(body,it)}
        }
        heading(body,"Объявления рядом")
        market.forEach{card(body,it)}
        note(body,"Объявления других пользователей демонстрационные.")
    }
    private fun card(body:LinearLayout,l:Listing){
        val card=LinearLayout(activity).apply{orientation=LinearLayout.VERTICAL;setPadding(dp(15),dp(13),dp(15),dp(13))
            background=Style.interactiveBg(Color.WHITE,Style.BRAND_RED_SOFT,9f,line);elevation=dp(1).toFloat()
            isClickable=true;isFocusable=true;contentDescription="${l.title}, ${price(l.price)}, ${l.condition}"
            setOnClickListener{selectedId=l.id;navigate("resale:detail")}
            if(l.sold)alpha=.6f}
        card.addView(text(l.title,16f,true).apply{maxLines=2})
        card.addView(text(l.condition+" · "+l.district,13f,false,Color.GRAY).apply{setPadding(0,dp(6),0,0)})
        val bottom=LinearLayout(activity).apply{orientation=LinearLayout.HORIZONTAL;gravity=Gravity.CENTER_VERTICAL;setPadding(0,dp(8),0,0)}
        bottom.addView(text(price(l.price),17f,true,blue),LinearLayout.LayoutParams(0,dp(30),1f))
        bottom.addView(text(when{l.sold->"Продано";l.mine->"Активно";else->"Подробнее  ›"},13f,true,if(l.mine&&!l.sold)green else blue))
        card.addView(bottom)
        body.addView(card,LinearLayout.LayoutParams(-1,-2).apply{leftMargin=dp(14);rightMargin=dp(14);topMargin=dp(5);bottomMargin=dp(5)})
    }
    private fun info(body:LinearLayout,key:String,value:String){
        val row=LinearLayout(activity).apply{orientation=LinearLayout.HORIZONTAL;setPadding(dp(16),dp(10),dp(16),dp(10))}
        row.addView(text(key,13.5f),LinearLayout.LayoutParams(0,-2,1f));row.addView(text(value,13.5f,true).apply{gravity=Gravity.END},LinearLayout.LayoutParams(0,-2,1f));body.addView(row);divider(body)
    }
    private fun detail(body:LinearLayout){
        val l=(mine()+market).firstOrNull{it.id==selectedId}?:run{navigate("resale:hub");return}
        heading(body,l.title)
        body.addView(text(price(l.price),24f,true,blue).apply{setPadding(dp(16),0,dp(16),dp(10))})
        info(body,"Состояние",l.condition);info(body,"Продавец",l.seller);info(body,"Район",l.district)
        if(l.mine)info(body,"Опубликовано",date.format(Date(l.created)))
        if(l.about.isNotBlank()){heading(body,"Описание");note(body,l.about)}
        if(l.mine){
            if(!l.sold)button(body,"Отметить как проданное"){update(l.id){it?.put("sold",true);true};navigate("resale:detail")}
            button(body,"Удалить объявление",false){update(l.id){false};Toast.makeText(activity,"Объявление удалено",Toast.LENGTH_SHORT).show();navigate("resale:hub")}
        }else{
            button(body,"Написать продавцу"){Toast.makeText(activity,"Демо: сообщение продавцу не отправляется",Toast.LENGTH_LONG).show()}
            note(body,"Осмотрите вещь при встрече и не переводите предоплату незнакомым людям.")
        }
    }
    private fun field(body:LinearLayout,caption:String,hint:String,value:String="",type:Int=InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES,multi:Boolean=false):EditText{
        body.addView(text(caption,13f,true).apply{setPadding(dp(17),dp(8),dp(17),dp(4))})
        return EditText(activity).apply{this.hint=hint;setText(value);textSize=14.5f
            inputType=if(multi)type or InputType.TYPE_TEXT_FLAG_MULTI_LINE else type;setSingleLine(!multi)
            gravity=if(multi)Gravity.TOP else Gravity.CENTER_VERTICAL;background=Style.bg(Color.WHITE,7f,line);setPadding(dp(12),dp(8),dp(12),dp(8))
            body.addView(this,LinearLayout.LayoutParams(-1,dp(if(multi)100 else 50)).apply{leftMargin=dp(16);rightMargin=dp(16);bottomMargin=dp(6)})}
    }
    private fun spinner(body:LinearLayout,caption:String,values:List<String>):Spinner{
        body.addView(text(caption,13f,true).apply{setPadding(dp(17),dp(8),dp(17),dp(3))})
        return Spinner(activity).apply{adapter=ArrayAdapter(activity,android.R.layout.simple_spinner_dropdown_item,values)
            body.addView(this,LinearLayout.LayoutParams(-1,dp(50)).apply{leftMargin=dp(16);rightMargin=dp(16);bottomMargin=dp(6)})}
    }
    private fun sell(body:LinearLayout){
        heading(body,"Новое объявление")
        val bought=purchases()
        val owned=(0 until bought.length()).mapNotNull{bought.optJSONObject(it)}
        note(body,if(owned.isEmpty())"Покупок ОМА пока нет — опишите вещь вручную."
            else "Выберите вещь из своих покупок ОМА или опишите другую.")
        val source=spinner(body,"Что продаёте",listOf("Другая вещь")+owned.map{it.optString("title","Товар")})
        val name=field(body,"Название","Например, диван угловой")
        val condition=spinner(body,"Состояние",conditions)
        val cost=field(body,"Цена, BYN","Например, 120","",InputType.TYPE_CLASS_NUMBER or InputType.TYPE_NUMBER_FLAG_DECIMAL)
        val about=field(body,"Описание","Сколько пользовались, комплектация, дефекты",multi=true)
        val hintView=text("",13f,false,green).apply{setPadding(dp(16),dp(2),dp(16),dp(6))}
        body.addView(hintView)
        source.onItemSelectedListener=object:AdapterView.OnItemSelectedListener{
            override fun onNothingSelected(parent:AdapterView<*>?)=Unit
            override fun onItemSelected(parent:AdapterView<*>?,view:View?,position:Int,id:Long){
                if(position==0){hintView.text="";return}
                val item=owned[position-1]
                name.setText(item.optString("title"))
                val paid=item.optDouble("price",0.0)
                // Suggest ~60% of the original price as a starting point.
                if(paid>0){val suggested=Math.round(paid*.6).toDouble();cost.setText(suggested.toInt().toString())
                    hintView.text="Куплено в ОМА за ${price(paid)}. Предлагаем начать с ${price(suggested)}."}
            }
        }
        button(body,"Опубликовать"){
            val title=name.text.toString().trim()
            val value=cost.text.toString().replace(',','.').toDoubleOrNull()
            if(title.length<3){name.error="Укажите название";return@button}
            if(value==null||value<=0){cost.error="Укажите цену";return@button}
            val items=stored()
            items.put(JSONObject().put("id",UUID.randomUUID().toString()).put("title",title)
                .put("condition",condition.selectedItem.toString()).put("price",value)
                .put("about",about.text.toString().trim()).put("sold",false).put("created",System.currentTimeMillis()))
            prefs.edit().putString("listings",items.toString()).apply()
            Toast.makeText(activity,"Объявление опубликовано",Toast.LENGTH_SHORT).show();navigate("resale:hub")
        }
    }
}
