package by.oma.companion

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

/** Backend API is a DEMO server without real authentication. Do not send real customer data. */
class Api(private val context: Context) {
    private val executor = Executors.newSingleThreadExecutor()
    private val preferences = context.getSharedPreferences("companion", Context.MODE_PRIVATE)
    var baseUrl: String
        get() = preferences.getString("backend_url", "https://oma-be-85l2.onrender.com")!!.trimEnd('/')
        set(value) { preferences.edit().putString("backend_url", value.trim().trimEnd('/')).apply() }

    /** Make HTTP requests off the UI thread, then deliver results to the main thread. */
    fun request(
        method: String,
        path: String,
        payload: JSONObject? = null,
        contractorId: Int? = null,
        callback: (Result<String>) -> Unit
    ) {
        executor.execute {
            val result = runCatching { exchange(method, path, payload, contractorId) }
            android.os.Handler(context.mainLooper).post { callback(result) }
        }
    }

    private fun exchange(method: String, path: String, body: JSONObject?, contractorId: Int?): String {
        val host = baseUrl
        require(host.startsWith("https://")) { "Для демо-сервера нужен HTTPS URL" }
        val conn = URL("$host/api/v1$path").openConnection() as HttpURLConnection
        try {
            conn.requestMethod = method
            conn.connectTimeout = 8000
            conn.readTimeout = 12000
            conn.setRequestProperty("Accept", "application/json")
            if (contractorId != null) conn.setRequestProperty("X-Contractor-Id", contractorId.toString())
            if (body != null) {
                conn.doOutput = true
                conn.setRequestProperty("Content-Type", "application/json; charset=utf-8")
                conn.outputStream.use { it.write(body.toString().toByteArray(Charsets.UTF_8)) }
            }
            val status = conn.responseCode
            val text = (if (status in 200..299) conn.inputStream else conn.errorStream)
                ?.bufferedReader(Charsets.UTF_8)?.use { it.readText() }.orEmpty()
            check(status in 200..299) { "HTTP $status — ${text.take(300)}" }
            return text
        } finally { conn.disconnect() }
    }

    fun close() = executor.shutdownNow()
    companion object {
        fun array(text: String): JSONArray = JSONArray(text)
        fun entries(array: JSONArray): List<JSONObject> =
            (0 until array.length()).mapNotNull { array.optJSONObject(it) }
    }
}
