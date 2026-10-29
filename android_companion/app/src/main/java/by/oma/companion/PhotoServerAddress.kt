package by.oma.companion

import java.net.URI

/**
 * Allows HTTPS photo-search services, and HTTP only on private LAN IPv4
 * addresses for the debug APK. No arbitrary HTTP websites or URL credentials.
 */
internal object PhotoServerAddress {
    fun normalize(raw: String): String {
        val candidate = raw.trim().trimEnd('/')
        require(candidate.isNotEmpty()) { "Введите адрес нейропоиска на ПК" }
        val url = try { URI(candidate) } catch (_: Exception) {
            throw IllegalArgumentException("Неверный адрес сервера")
        }
        val scheme = url.scheme?.lowercase()
        val hostname = url.host?.lowercase()
        require(scheme == "https" || scheme == "http") { "Используйте HTTPS или локальный HTTP" }
        require(!hostname.isNullOrEmpty() && url.userInfo == null
            && url.rawQuery == null && url.rawFragment == null
            && (url.rawPath.isNullOrEmpty() || url.rawPath == "/")
        ) { "Укажите только адрес и порт, без пути или пароля" }
        if (scheme == "http") {
            require(isPrivateIPv4(hostname)) {
                "Обычный HTTP разрешён только для локального IP домашней сети"
            }
            require(url.port in 1..65535) { "Укажите порт сервера, например :8765" }
        }
        require(url.port <= 65535) { "Неверный номер порта" }
        return "${scheme}://${hostname}${if (url.port >= 0) ":${url.port}" else ""}"
    }

    private fun isPrivateIPv4(hostname: String): Boolean {
        val octets = hostname.split('.')
        if (octets.size != 4) return false
        val values = octets.map {
            if (it.isEmpty() || it.length > 3 || it.any { ch -> !ch.isDigit() }) return false
            it.toIntOrNull()?.takeIf { n -> n in 0..255 } ?: return false
        }
        val a = values[0]
        val b = values[1]
        return a == 10 || (a == 172 && b in 16..31) ||
            (a == 192 && b == 168) || a == 127
    }
}
