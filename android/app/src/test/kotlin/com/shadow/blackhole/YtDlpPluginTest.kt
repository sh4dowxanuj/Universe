package com.shadow.universe

import org.junit.Test
import org.junit.Assert.*

class YtDlpPluginTest {
    
    @Test
    fun testFormatSelectionLogic() {
        // Mock yt-dlp response formats
        val formats = listOf(
            mapOf(
                "vcodec" to "avc1.4d401f",
                "acodec" to "mp4a.40.2",
                "abr" to 128,
                "url" to "https://video-with-audio.com"
            ),
            mapOf(
                "vcodec" to "none",
                "acodec" to "mp4a.40.2",
                "abr" to 128,
                "url" to "https://audio-128.com"
            ),
            mapOf(
                "vcodec" to "none",
                "acodec" to "opus",
                "abr" to 160,
                "url" to "https://audio-160.com"
            ),
            mapOf(
                "vcodec" to "none",
                "acodec" to "mp4a.40.2",
                "abr" to 256,
                "url" to "https://audio-256.com"
            )
        )

        // Replicate the format selection logic from executeYtDlp
        var bestAudioUrl: String? = null
        var bestBitrate = 0

        formats.forEach { formatObj ->
            val format = formatObj as Map<*, *>
            val vcodec = format["vcodec"]?.toString()
            val acodec = format["acodec"]?.toString()
            val abr = (format["abr"] as? Number)?.toInt() ?: 0
            val urlStr = format["url"]?.toString()

            if ((vcodec == "none" || vcodec == null) && acodec != "none" && acodec != null && abr > bestBitrate && urlStr != null) {
                bestAudioUrl = urlStr
                bestBitrate = abr
            }
        }

        // Should select the 256kbps audio-only format
        assertEquals("https://audio-256.com", bestAudioUrl)
        assertEquals(256, bestBitrate)
    }

    @Test
    fun testMissingFieldsHandling() {
        // Mock yt-dlp info with missing fields
        val infoMap = mapOf<String, Any>(
            "title" to "Test Song",
            "duration" to 180
            // thumbnail and uploader missing
        )

        val title = infoMap["title"]?.toString() ?: ""
        val duration = (infoMap["duration"] as? Number)?.toInt() ?: 0
        val thumbnail = infoMap["thumbnail"]?.toString() ?: ""
        val uploader = infoMap["uploader"]?.toString() ?: ""

        assertEquals("Test Song", title)
        assertEquals(180, duration)
        assertEquals("", thumbnail)
        assertEquals("", uploader)
    }

    @Test
    fun testTypeConversions() {
        // Test that type conversions work correctly
        val kotlinStyleMap = mapOf<String, Any>(
            "duration" to 123.45, // Double from Python
            "view_count" to 1000000,
            "title" to "Test"
        )

        val duration = (kotlinStyleMap["duration"] as? Number)?.toInt() ?: 0
        val viewCount = (kotlinStyleMap["view_count"] as? Number)?.toInt() ?: 0
        val title = kotlinStyleMap["title"]?.toString() ?: ""

        assertEquals(123, duration)
        assertEquals(1000000, viewCount)
        assertEquals("Test", title)
    }

    @Test
    fun testMapOfOptionsCreation() {
        // Test that mapOf creates correct structure
        val opts = mapOf(
            "format" to "bestaudio[ext=m4a]/bestaudio",
            "quiet" to true,
            "no_warnings" to true,
            "extract_flat" to false,
            "nocheckcertificate" to true
        )

        assertEquals("bestaudio[ext=m4a]/bestaudio", opts["format"])
        assertEquals(true, opts["quiet"])
        assertEquals(false, opts["extract_flat"])
    }

    @Test
    fun testNestedMapAccess() {
        // Test nested structure like yt-dlp returns
        val mockInfo = mapOf(
            "title" to "Test Song",
            "formats" to listOf(
                mapOf("url" to "audio1.m4a", "abr" to 128),
                mapOf("url" to "audio2.m4a", "abr" to 256)
            )
        )

        val formats = mockInfo["formats"] as? List<*>
        assertNotNull(formats)
        assertEquals(2, formats?.size)

        val firstFormat = formats?.get(0) as? Map<*, *>
        assertEquals("audio1.m4a", firstFormat?.get("url"))
    }
}
