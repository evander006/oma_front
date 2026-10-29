package by.oma.companion

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class PhotoServerAddressTest {
    @Test fun acceptsPrivateLanDemoPort() {
        assertEquals("http://192.168.1.42:8765",
            PhotoServerAddress.normalize(" http://192.168.1.42:8765/ "))
        assertEquals("http://10.1.2.3:8765",
            PhotoServerAddress.normalize("http://10.1.2.3:8765"))
        assertEquals("http://172.16.2.3:8765",
            PhotoServerAddress.normalize("http://172.16.2.3:8765"))
    }

    @Test fun allowsExistingHttpsServices() {
        assertEquals("https://oma-be-85l2.onrender.com",
            PhotoServerAddress.normalize("https://oma-be-85l2.onrender.com/"))
    }

    @Test fun refusesPublicUnencryptedRequests() {
        listOf(
            "http://8.8.8.8:8765", "http://example.com:8765",
            "http://192.168.1.200:8765/other", "http://192.168.1.200:8765?token=hi",
            "http://localhost:8765", "http://172.32.1.2:8765",
            "ftp://192.168.1.2", "http://user:pass@192.168.1.2:8765"
        ).forEach { uri ->
            assertThrows(uri, IllegalArgumentException::class.java) {
                PhotoServerAddress.normalize(uri)
            }
        }
    }
}
