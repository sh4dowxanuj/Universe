package com.shadow.blackhole

import android.util.Log
import com.chaquo.python.PyObject
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class YtDlpPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val scope = CoroutineScope(Dispatchers.Main)
    private val TAG = "YtDlpPlugin"

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ytdlp_channel")
        channel.setMethodCallHandler(this)

        // Initialize Python if not already initialized
        if (!Python.isStarted()) {
            AndroidPlatform.start(flutterPluginBinding.applicationContext)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getAudioStream" -> {
                val videoId = call.argument<String>("videoId")
                if (videoId == null) {
                    result.error("INVALID_ARGUMENT", "videoId is required", null)
                    return
                }
                getAudioStream(videoId, result)
            }
            "getVideoInfo" -> {
                val videoId = call.argument<String>("videoId")
                if (videoId == null) {
                    result.error("INVALID_ARGUMENT", "videoId is required", null)
                    return
                }
                getVideoInfo(videoId, result)
            }
            "searchVideos" -> {
                val query = call.argument<String>("query")
                val maxResults = call.argument<Int>("maxResults") ?: 10
                if (query == null) {
                    result.error("INVALID_ARGUMENT", "query is required", null)
                    return
                }
                searchVideos(query, maxResults, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun getAudioStream(videoId: String, result: Result) {
        scope.launch {
            try {
                val audioData = withContext(Dispatchers.IO) {
                    executeYtDlp(videoId)
                }
                result.success(audioData)
            } catch (e: Exception) {
                Log.e(TAG, "Error getting audio stream", e)
                result.error("PYTHON_ERROR", e.message, null)
            }
        }
    }

    private fun getVideoInfo(videoId: String, result: Result) {
        scope.launch {
            try {
                val info = withContext(Dispatchers.IO) {
                    executeYtDlpInfo(videoId)
                }
                result.success(info)
            } catch (e: Exception) {
                Log.e(TAG, "Error getting video info", e)
                result.error("PYTHON_ERROR", e.message, null)
            }
        }
    }

    private fun searchVideos(query: String, maxResults: Int, result: Result) {
        scope.launch {
            try {
                val results = withContext(Dispatchers.IO) {
                    executeYtDlpSearch(query, maxResults)
                }
                result.success(results)
            } catch (e: Exception) {
                Log.e(TAG, "Error searching videos", e)
                result.error("PYTHON_ERROR", e.message, null)
            }
        }
    }

    private fun executeYtDlp(videoId: String): Map<String, Any?> {
        val py = Python.getInstance()
        val ytdlp = py.getModule("yt_dlp")

        val ydl_opts = py.builtins().callAttr(
            "dict",
            mapOf(
                "format" to "bestaudio[ext=m4a]/bestaudio",
                "quiet" to true,
                "no_warnings" to true,
                "extract_flat" to false
            )
        )

        val YoutubeDL = ytdlp.get("YoutubeDL")
        val ydl = YoutubeDL?.call(ydl_opts)

        val url = "https://www.youtube.com/watch?v=$videoId"
        val info = ydl?.callAttr("extract_info", url, false)

        if (info == null) {
            throw Exception("Failed to extract info")
        }

        val formats = info.get("formats")?.asList()
        var bestAudioUrl: String? = null
        var bestBitrate = 0

        // Find best audio format
        formats?.forEach { formatObj ->
            val format = formatObj as? PyObject
            val vcodec = format?.get("vcodec")?.toString()
            val acodec = format?.get("acodec")?.toString()
            val abr = format?.get("abr")?.toInt() ?: 0
            val url = format?.get("url")?.toString()

            if ((vcodec == "none" || vcodec == null) && acodec != "none" && acodec != null && abr > bestBitrate && url != null) {
                bestAudioUrl = url
                bestBitrate = abr
            }
        }

        return mapOf(
            "url" to (bestAudioUrl ?: throw Exception("No audio stream found")),
            "title" to (info.get("title")?.toString() ?: ""),
            "duration" to (info.get("duration")?.toInt() ?: 0),
            "thumbnail" to (info.get("thumbnail")?.toString() ?: ""),
            "uploader" to (info.get("uploader")?.toString() ?: ""),
            "bitrate" to bestBitrate
        )
    }

    private fun executeYtDlpInfo(videoId: String): Map<String, Any?> {
        val py = Python.getInstance()
        val ytdlp = py.getModule("yt_dlp")

        val ydl_opts = py.builtins().callAttr(
            "dict",
            mapOf(
                "quiet" to true,
                "no_warnings" to true,
                "extract_flat" to true
            )
        )

        val YoutubeDL = ytdlp.get("YoutubeDL")
        val ydl = YoutubeDL?.call(ydl_opts)

        val url = "https://www.youtube.com/watch?v=$videoId"
        val info = ydl?.callAttr("extract_info", url, false)

        if (info == null) {
            throw Exception("Failed to extract info")
        }

        return mapOf(
            "id" to (info.get("id")?.toString() ?: videoId),
            "title" to (info.get("title")?.toString() ?: ""),
            "duration" to (info.get("duration")?.toInt() ?: 0),
            "thumbnail" to (info.get("thumbnail")?.toString() ?: ""),
            "uploader" to (info.get("uploader")?.toString() ?: ""),
            "view_count" to (info.get("view_count")?.toInt() ?: 0),
            "description" to (info.get("description")?.toString() ?: "")
        )
    }

    private fun executeYtDlpSearch(query: String, maxResults: Int): List<Map<String, Any?>> {
        val py = Python.getInstance()
        val ytdlp = py.getModule("yt_dlp")

        val ydl_opts = py.builtins().callAttr(
            "dict",
            mapOf(
                "quiet" to true,
                "no_warnings" to true,
                "extract_flat" to true
            )
        )

        val YoutubeDL = ytdlp.get("YoutubeDL")
        val ydl = YoutubeDL?.call(ydl_opts)

        val searchUrl = "ytsearch$maxResults:$query"
        val result = ydl?.callAttr("extract_info", searchUrl, false)

        if (result == null) {
            throw Exception("Search failed")
        }

        val entries = result.get("entries")?.asList()
        val results = mutableListOf<Map<String, Any?>>()

        entries?.forEach { entryObj ->
            val entry = entryObj as? PyObject
            if (entry != null) {
                results.add(
                    mapOf(
                        "id" to (entry.get("id")?.toString() ?: ""),
                        "title" to (entry.get("title")?.toString() ?: ""),
                        "duration" to (entry.get("duration")?.toInt() ?: 0),
                        "thumbnail" to (entry.get("thumbnail")?.toString() ?: ""),
                        "uploader" to (entry.get("uploader")?.toString() ?: ""),
                        "view_count" to (entry.get("view_count")?.toInt() ?: 0)
                    )
                )
            }
        }

        return results
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
