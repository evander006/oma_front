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

/** Local marketplace demo. No request is sent to a real contractor. */
class MasterHub(
    private val activity:Activity,
    private val navigate:(String)->Unit,
    private val selectedHome:()->String?
){
    private val blue=Style.BLUE
    private val ink=Style.DARK
    private val line=Style.BORDER
    private val prefs=activity.getSharedPreferences("oma_master_hub",Activity.MODE_PRIVATE)
    private var selectedId="m1"
    private var filter="Все специалисты"
    private val date=SimpleDateFormat("dd.MM.yyyy HH:mm",Locale("ru","RU"))

    data class Review(val author:String,val rating:Double,val text:String,val date:String)
    data class Master(val id:String,val name:String,val specialty:String,val experience:Int,
        val rating:Double,val jobs:Int,val price:String,val visit:String,val about:String,
        val verified:Boolean,val reviews:List<Review>)

    private val masters=listOf(
        Master("m1","Александр Ковалёв","Электрик",12,4.9,186,"от 45 BYN","Выезд от 20 BYN",
            "Монтаж проводки, розеток, освещения и диагностика электросетей.",true,listOf(
                Review("Мария",5.0,"Быстро нашёл неисправность и всё объяснил.","18.10.2026"),
                Review("Игорь",4.8,"Аккуратная установка светильников.","03.10.2026"))),
        Master("m2","Сергей Новик","Сантехник",9,4.8,142,"от 40 BYN","Выезд от 15 BYN",
            "Смесители, трубы, протечки, санузлы и подключение техники.",true,listOf(
                Review("Анна",5.0,"Устранил протечку в день обращения.","21.10.2026"),
                Review("Павел",4.6,"Хорошая работа, немного задержался.","11.09.2026"))),
        Master("m3","Дмитрий Орлов","Ремонт техники",8,4.7,98,"от 55 BYN","Диагностика 25 BYN",
            "Диагностика и обслуживание бытовой техники для дома и кухни.",true,listOf(
                Review("Олег",4.7,"Вернул стиральную машину в работу.","14.10.2026"),
                Review("Елена",4.7,"Назвал цену до ремонта, без сюрпризов.","30.09.2026"))),
        Master("m4","Андрей Лис","Отделочник",15,4.9,211,"от 18 BYN/м²","Замер бесплатно",
            "Напольные покрытия, стены, плитка и комплексная отделка помещений.",true,listOf(
                Review("Виктор",5.0,"Ламинат уложен ровно и чисто.","16.10.2026"),
                Review("Светлана",4.9,"Помог точно рассчитать материалы.","28.09.2026"))),
        Master("m5","Михаил Борисов","Сборщик мебели",7,4.6,75,"от 35 BYN","Выезд от 15 BYN",
            "Сборка, установка и мелкий ремонт корпусной мебели.",false,listOf(
                Review("Роман",4.6,"Шкаф собран хорошо.","08.10.2026"),
                Review("Алёна",4.5,"Всё нормально, приехал вовремя.","19.09.2026"))),
        Master("m6","Николай Жук","Универсальный мастер",11,4.8,164,"от 50 BYN","Выезд от 20 BYN",
            "Мелкий бытовой ремонт, монтаж, навеска и обслуживание дома.",true,listOf(
                Review("Наталья",4.9,"Закрыл сразу несколько задач за один приезд.","20.10.2026"),
                Review("Артём",4.7,"Работает спокойно и аккуратно.","05.10.2026")))
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
    fun title(screen:String)=when(screen){"master:detail"->"Профиль мастера";"master:request"->"Оформление заявки";"master:requests"->"Мои заявки";else->"Знающий мастер"}
    fun back(screen:String)=when(screen){"master:request"->"master:detail";"master:detail","master:requests"->"master:hub";else->"home:hub"}
    fun render(screen:String,body:LinearLayout){when(screen){
        "master:detail"->detail(body);"master:request"->request(body);"master:requests"->requests(body);else->list(body)
    }}

    private fun list(body:LinearLayout){
        heading(body,"Найдите проверенного мастера")
        note(body,"Отзывы и цены в этой версии демонстрационные. Реальные исполнители к приложению не подключены.")
        val variants=listOf("Все специалисты")+masters.map{it.specialty}.distinct()
        val spinner=Spinner(activity).apply{adapter=ArrayAdapter(activity,android.R.layout.simple_spinner_dropdown_item,variants);setSelection(variants.indexOf(filter).coerceAtLeast(0))}
        spinner.onItemSelectedListener=object:AdapterView.OnItemSelectedListener{
            override fun onNothingSelected(parent:AdapterView<*>?)=Unit
            override fun onItemSelected(parent:AdapterView<*>?,view:View?,position:Int,id:Long){
                val next=variants[position];if(next!=filter){filter=next;navigate("master:hub")}
            }
        }
        body.addView(spinner,LinearLayout.LayoutParams(-1,dp(54)).apply{leftMargin=dp(16);rightMargin=dp(16);bottomMargin=dp(8)})
        button(body,"Мои заявки",false){navigate("master:requests")}
        masters.filter{filter=="Все специалисты"||it.specialty==filter}.forEach{masterCard(body,it)}
    }
    private fun masterCard(body:LinearLayout,m:Master){
        val card=LinearLayout(activity).apply{orientation=LinearLayout.VERTICAL;setPadding(dp(15),dp(13),dp(15),dp(13));background=Style.interactiveBg(Color.WHITE,Style.BRAND_RED_SOFT,9f,line);elevation=dp(1).toFloat();isClickable=true;isFocusable=true;contentDescription="${m.name}, ${m.specialty}, рейтинг ${m.rating}";setOnClickListener{selectedId=m.id;navigate("master:detail")}}
        val top=LinearLayout(activity).apply{orientation=LinearLayout.HORIZONTAL}
        top.addView(text(m.name,17f,true),LinearLayout.LayoutParams(0,dp(32),1f))
        top.addView(text("★ ${m.rating}",15f,true,Color.rgb(231,151,20)))
        card.addView(top)
        card.addView(text(m.specialty+if(m.verified)" · Личность проверена" else " · Проверка не завершена",13f,false,if(m.verified)Color.rgb(46,132,82) else Color.GRAY))
        card.addView(text("${m.experience} лет опыта · ${m.jobs} выполненных работ · ${m.reviews.size} отзыва",12.5f,false,Color.GRAY).apply{setPadding(0,dp(5),0,0)})
        val price=LinearLayout(activity).apply{orientation=LinearLayout.HORIZONTAL;gravity=Gravity.CENTER_VERTICAL;setPadding(0,dp(10),0,0)}
        price.addView(text(m.price,16f,true,blue),LinearLayout.LayoutParams(0,dp(34),1f));price.addView(text("Подробнее  ›",13f,true,blue));card.addView(price)
        body.addView(card,LinearLayout.LayoutParams(-1,-2).apply{leftMargin=dp(14);rightMargin=dp(14);topMargin=dp(5);bottomMargin=dp(5)})
    }
    private fun current()=masters.first{it.id==selectedId}
    private fun detail(body:LinearLayout){
        val m=current();heading(body,m.name);note(body,m.specialty+" · ★ ${m.rating} · ${m.jobs} работ")
        info(body,"Стоимость работ",m.price);info(body,"Выезд / диагностика",m.visit);info(body,"Опыт","${m.experience} лет");info(body,"Проверка",if(m.verified)"Личность подтверждена" else "Не завершена")
        heading(body,"О мастере");note(body,m.about)
        heading(body,"Отзывы")
        m.reviews.forEach{r->
            val box=LinearLayout(activity).apply{orientation=LinearLayout.VERTICAL;setPadding(dp(16),dp(10),dp(16),dp(10));setBackgroundColor(Color.WHITE)}
            box.addView(text("${r.author} · ★ ${r.rating} · ${r.date}",13.5f,true));box.addView(text(r.text,13f,false,Color.DKGRAY));body.addView(box);divider(body)
        }
        button(body,"Оформить заявку"){navigate("master:request")}
        note(body,"Окончательную стоимость мастер должен подтвердить после описания задачи или диагностики.")
    }
    private fun info(body:LinearLayout,key:String,value:String){
        val row=LinearLayout(activity).apply{orientation=LinearLayout.HORIZONTAL;setPadding(dp(16),dp(10),dp(16),dp(10))}
        row.addView(text(key,13.5f),LinearLayout.LayoutParams(0,-2,1f));row.addView(text(value,13.5f,true).apply{gravity=Gravity.END},LinearLayout.LayoutParams(0,-2,1f));body.addView(row);divider(body)
    }
    private fun field(body:LinearLayout,caption:String,hint:String,multi:Boolean=false):EditText{
        body.addView(text(caption,13f,true).apply{setPadding(dp(17),dp(8),dp(17),dp(4))})
        return EditText(activity).apply{this.hint=hint;textSize=14.5f;inputType=InputType.TYPE_CLASS_TEXT or if(multi)InputType.TYPE_TEXT_FLAG_MULTI_LINE else InputType.TYPE_TEXT_FLAG_CAP_SENTENCES;setSingleLine(!multi);gravity=if(multi)Gravity.TOP else Gravity.CENTER_VERTICAL;background=Style.bg(Color.WHITE,7f,line);setPadding(dp(12),dp(8),dp(12),dp(8));body.addView(this,LinearLayout.LayoutParams(-1,dp(if(multi)100 else 50)).apply{leftMargin=dp(16);rightMargin=dp(16);bottomMargin=dp(6)})}
    }
    private fun request(body:LinearLayout){
        val m=current();heading(body,"Заявка мастеру ${m.name}");note(body,"Ориентир: ${m.price}. Итоговая цена появится только после подтверждения мастером.")
        val home=selectedHome();info(body,"Объект",home?:"Объект не выбран")
        val work=field(body,"Что нужно сделать","Например, заменить смеситель")
        val details=field(body,"Описание неисправности","Что произошло, где находится прибор, что уже проверяли",true)
        val time=field(body,"Желаемое время","Например, завтра после 18:00")
        val contact=field(body,"Телефон для связи","+375 …")
        val urgency=Spinner(activity).apply{adapter=ArrayAdapter(activity,android.R.layout.simple_spinner_dropdown_item,listOf("Обычная заявка","Срочно сегодня","Нужна консультация"))}
        body.addView(text("Срочность",13f,true).apply{setPadding(dp(17),dp(8),dp(17),dp(3))});body.addView(urgency,LinearLayout.LayoutParams(-1,dp(50)).apply{leftMargin=dp(16);rightMargin=dp(16)})
        val share=CheckBox(activity).apply{text="Разрешить мастеру доступ к паспорту выбранного объекта после принятия заявки";textSize=13f;setPadding(dp(12),dp(8),dp(12),dp(3))}
        val history=CheckBox(activity).apply{text="Также показать историю ремонтов и обслуживания";textSize=13f;isEnabled=home!=null;setPadding(dp(12),0,dp(12),dp(8))}
        share.isEnabled=home!=null;body.addView(share);body.addView(history)
        button(body,"Отправить демо-заявку"){
            if(work.text.toString().trim().length<4){work.error="Опишите работу";return@button}
            if(contact.text.toString().filter{it.isDigit()}.length<7){contact.error="Укажите телефон";return@button}
            val items=runCatching{JSONArray(prefs.getString("requests","[]"))}.getOrDefault(JSONArray())
            items.put(JSONObject().put("id",UUID.randomUUID().toString()).put("masterId",m.id).put("master",m.name)
                .put("work",work.text.toString().trim()).put("details",details.text.toString().trim()).put("time",time.text.toString().trim())
                .put("contact",contact.text.toString().trim()).put("urgency",urgency.selectedItem.toString()).put("home",home?:"")
                .put("sharePassport",share.isChecked).put("shareHistory",history.isChecked&&share.isChecked).put("status","Отправлена").put("created",System.currentTimeMillis()))
            prefs.edit().putString("requests",items.toString()).apply();Toast.makeText(activity,"Демо-заявка сохранена",Toast.LENGTH_LONG).show();navigate("master:requests")
        }
        note(body,"Заявка хранится только на этом устройстве и реальному мастеру не отправляется.")
    }
    private fun requests(body:LinearLayout){
        heading(body,"Мои заявки");val items=runCatching{JSONArray(prefs.getString("requests","[]"))}.getOrDefault(JSONArray())
        if(items.length()==0){note(body,"Заявок пока нет.");button(body,"Выбрать мастера"){navigate("master:hub")};return}
        for(i in items.length()-1 downTo 0){val o=items.optJSONObject(i)?:continue
            val card=LinearLayout(activity).apply{orientation=LinearLayout.VERTICAL;setPadding(dp(15),dp(12),dp(15),dp(12));background=Style.bg(Color.WHITE,8f,line)}
            card.addView(text(o.optString("work"),15f,true));card.addView(text(o.optString("master")+" · "+o.optString("status"),13f,true,blue));card.addView(text(date.format(Date(o.optLong("created"))),12.5f,false,Color.GRAY))
            val access=when{!o.optBoolean("sharePassport")->"Паспорт не передаётся";o.optBoolean("shareHistory")->"После принятия: паспорт и история обслуживания";else->"После принятия: только паспорт объекта"}
            card.addView(text(access,12.5f,false,Color.GRAY).apply{setPadding(0,dp(5),0,0)});body.addView(card,LinearLayout.LayoutParams(-1,-2).apply{leftMargin=dp(14);rightMargin=dp(14);topMargin=dp(5);bottomMargin=dp(5)})
        }
    }
}
