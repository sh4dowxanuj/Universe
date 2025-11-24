package com.shadow.blackhole

import android.content.Context
import android.util.Log
import com.chaquo.python.PyObject
import com.google.gson.Gson
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

    // Centralized Python initialization
    private fun ensurePythonStarted(context: Context) {
        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(context))
            Log.e(TAG, "Python initialized")
        }
    }

    // Helper to convert PyObject to Map<String, Any?> via JSON
    private fun pyToMap(pyObj: PyObject): Map<String, Any?> {
        val python = Python.getInstance()
        val jsonLib = python.getModule("json")
        val jsonStr = jsonLib.callAttr("dumps", pyObj).toString()
        return Gson().fromJson(jsonStr, Map::class.java) as Map<String, Any?>
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: io.flutter.plugin.common.PluginRegistry.Registrar) {
            System.out.println("YTDLP: registerWith (old API) called")
            val channel = MethodChannel(registrar.messenger(), "ytdlp_channel")
            val plugin = YtDlpPlugin()
            channel.setMethodCallHandler(plugin)
            System.out.println("YTDLP: Old API registration complete")
            android.util.Log.e("YtDlpPlugin", "YTDLP: Channel registered via old API")
            plugin.ensurePythonStarted(registrar.context())
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        System.out.println("YTDLP: onAttachedToEngine called")
        android.util.Log.e(TAG, "YTDLP: Creating method channel")
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ytdlp_channel")
        channel.setMethodCallHandler(this)
        System.out.println("YTDLP: Method channel 'ytdlp_channel' registered")
        android.util.Log.e(TAG, "YTDLP: Channel registration complete")

        // Initialize Python if not already initialized
        ensurePythonStarted(flutterPluginBinding.applicationContext)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        System.out.println("YTDLP: Method call received: ${call.method}")
        android.util.Log.e(TAG, "YTDLP: Processing method: ${call.method}")
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
        System.out.println("YTDLP: getAudioStream called for: $videoId")
        Log.e(TAG, "YTDLP: Starting yt-dlp for $videoId")
        scope.launch {
            try {
                val audioData = withContext(Dispatchers.IO) {
                    executeYtDlp(videoId)
                }
                System.out.println("YTDLP: SUCCESS - Got stream URL for $videoId")
                result.success(audioData)
            } catch (e: Exception) {
                Log.e(TAG, "YTDLP: ERROR for $videoId: ${e.message}", e)
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
                @Suppress("UNCHECKED_CAST")
                val javaMap = (info as? PyObject)?.toJava(Map::class.java) as? Map<String, Any?>
                    ?: info as? Map<String, Any?>
                if (javaMap != null) {
                    result.success(javaMap)
                } else {
                    result.error("PYTHON_ERROR", "Failed to convert result to Map", null)
                }
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
                // Convert list of PyObject maps to list of Java maps if needed
                val javaList = when (results) {
                    is List<*> -> results.map {
                        (it as? PyObject)?.toJava(Map::class.java) as? Map<String, Any?> ?: it
                    }
                    else -> results
                }
                result.success(javaList)
            } catch (e: Exception) {
                Log.e(TAG, "Error searching videos", e)
                result.error("PYTHON_ERROR", e.message, null)
            }
        }
    }

    private fun executeYtDlp(videoId: String): Map<String, Any?> {
        android.util.Log.e(TAG, "YTDLP: Starting yt-dlp for $videoId (JSON conversion mode)")
        val python = Python.getInstance()
        val ytdlp = python.getModule("yt_dlp")

        val pyDict = python.getBuiltins().callAttr("dict")
        pyDict.callAttr("__setitem__", "quiet", true)
        pyDict.callAttr("__setitem__", "skip_download", true)
        pyDict.callAttr("__setitem__", "format", "bestaudio")
        pyDict.callAttr("__setitem__", "extract_flat", false)
        pyDict.callAttr("__setitem__", "noplaylist", true)

        val ydl = ytdlp.callAttr("YoutubeDL", pyDict)
        val info = ydl.callAttr("extract_info", "https://www.youtube.com/watch?v=$videoId", false)
            ?: throw Exception("Failed to extract info")

        val infoMap = pyToMap(info)
        val formats = infoMap["formats"] as? List<*> ?: throw Exception("No formats found")

        var bestAudioUrl: String? = null
        var bestBitrate = 0
        val title = infoMap["title"]?.toString() ?: ""
        val duration = (infoMap["duration"] as? Number)?.toInt() ?: (infoMap["duration"] as? Double)?.toInt() ?: 0
        val thumbnail = infoMap["thumbnail"]?.toString() ?: ""
        val uploader = infoMap["uploader"]?.toString() ?: ""

        formats.forEach { item ->
            val f = item as? Map<String, Any?> ?: return@forEach
            val acodec = f["acodec"]?.toString()?.lowercase()
            val vcodec = f["vcodec"]?.toString()?.lowercase()

            if (acodec != null && acodec != "none" && (vcodec == null || vcodec == "none")) {
                val abr = (f["abr"] as? Number)?.toInt()
                    ?: (f["tbr"] as? Number)?.toInt()
                    ?: 0
                val urlStr = f["url"]?.toString()
                Log.d(TAG, "Evaluating format: abr=$abr, url=$urlStr")
                if (urlStr != null && abr >= bestBitrate) {
                    bestBitrate = abr
                    bestAudioUrl = urlStr
                }
            }
        }

        return mapOf(
            "url" to (bestAudioUrl ?: throw Exception("No audio stream found")),
            "title" to title,
            "duration" to duration,
            "thumbnail" to thumbnail,
            "uploader" to uploader,
            "bitrate" to bestBitrate
        )
    }

    private fun executeYtDlpInfo(videoId: String): Map<String, Any?> {
        val python = Python.getInstance()
        val ytdlp = python.getModule("yt_dlp")

        val pyDict = python.getBuiltins().callAttr("dict")
        pyDict.callAttr("__setitem__", "quiet", true)
        pyDict.callAttr("__setitem__", "skip_download", true)
        pyDict.callAttr("__setitem__", "format", "bestaudio")
        pyDict.callAttr("__setitem__", "extract_flat", false)
        pyDict.callAttr("__setitem__", "noplaylist", true)

        val ydl = ytdlp.callAttr("YoutubeDL", pyDict)
        val info = ydl.callAttr("extract_info", "https://www.youtube.com/watch?v=$videoId", false)
            ?: throw Exception("Failed to extract info")

        val infoMap = pyToMap(info)

        return mapOf(
            "id" to (infoMap["id"]?.toString() ?: videoId),
            "title" to (infoMap["title"]?.toString() ?: ""),
            "duration" to ((infoMap["duration"] as? Number)?.toInt() ?: (infoMap["duration"] as? Double)?.toInt() ?: 0),
            "thumbnail" to (infoMap["thumbnail"]?.toString() ?: ""),
            "uploader" to (infoMap["uploader"]?.toString() ?: ""),
            "view_count" to ((infoMap["view_count"] as? Number)?.toInt() ?: (infoMap["view_count"] as? Double)?.toInt() ?: 0),
            "description" to (infoMap["description"]?.toString() ?: "")
        )
    }

    private fun executeYtDlpSearch(query: String, maxResults: Int): List<Map<String, Any?>> {
        val python = Python.getInstance()
        val ytdlp = python.getModule("yt_dlp")

        val pyDict = python.getBuiltins().callAttr("dict")
        pyDict.callAttr("__setitem__", "quiet", true)
        pyDict.callAttr("__setitem__", "skip_download", true)
        pyDict.callAttr("__setitem__", "format", "bestaudio")
        pyDict.callAttr("__setitem__", "extract_flat", false)
        pyDict.callAttr("__setitem__", "noplaylist", true)

        val ydl = ytdlp.callAttr("YoutubeDL", pyDict)
        val searchExpr = "ytsearch$maxResults:$query"
        val result = ydl.callAttr("extract_info", searchExpr, false) ?: throw Exception("Search failed")

        val resultMap = pyToMap(result)
        val entries = resultMap["entries"] as? List<*> ?: return emptyList()
        val out = mutableListOf<Map<String, Any?>>()

        entries.forEach { item ->
            val e = item as? Map<String, Any?> ?: return@forEach
            val id = e["id"]?.toString() ?: ""
            val title = e["title"]?.toString() ?: ""
            val duration = (e["duration"] as? Number)?.toInt() ?: (e["duration"] as? Double)?.toInt() ?: 0
            val thumbnail = e["thumbnail"]?.toString() ?: ""
            val uploader = e["uploader"]?.toString() ?: ""
            val viewCount = (e["view_count"] as? Number)?.toInt() ?: (e["view_count"] as? Double)?.toInt() ?: 0
            out.add(
                mapOf(
                    "id" to id,
                    "title" to title,
                    "duration" to duration,
                    "thumbnail" to thumbnail,
                    "uploader" to uploader,
                    "view_count" to viewCount
                )
            )
        }

        return out
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
