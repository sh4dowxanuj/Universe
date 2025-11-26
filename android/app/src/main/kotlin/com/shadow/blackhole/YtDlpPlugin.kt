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

    // Cached Python objects for performance
    private var pythonInstance: Python? = null
    private var ytdlpModule: PyObject? = null
    private var jsonModule: PyObject? = null
    private var builtins: PyObject? = null

    // Pre-configured YoutubeDL instances
    private var audioExtractor: PyObject? = null
    private var infoExtractor: PyObject? = null
    private var searchExtractor: PyObject? = null

    // Cached configuration dictionaries
    private var audioOptions: PyObject? = null
    private var infoOptions: PyObject? = null
    private var searchOptions: PyObject? = null

    // Performance metrics
    private var totalCalls = 0
    private var cacheHits = 0

    // Centralized Python initialization with caching
    private fun ensurePythonStarted(context: Context) {
        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(context))
            Log.i(TAG, "Python runtime initialized")
        }

        // Initialize cached objects if not already done
        if (pythonInstance == null) {
            pythonInstance = Python.getInstance()
            ytdlpModule = pythonInstance!!.getModule("yt_dlp")
            jsonModule = pythonInstance!!.getModule("json")
            builtins = pythonInstance!!.getBuiltins()

            // Pre-create configuration dictionaries
            createConfigDictionaries()

            // Pre-create YoutubeDL instances
            createExtractors()

            Log.i(TAG, "Python objects cached for performance")
        }
    }

    // Create optimized configuration dictionaries
    private fun createConfigDictionaries() {
        // Audio extraction config - optimized for speed
        audioOptions = builtins!!.callAttr("dict")
        audioOptions!!.callAttr("__setitem__", "quiet", true)
        audioOptions!!.callAttr("__setitem__", "no_warnings", true)
        audioOptions!!.callAttr("__setitem__", "skip_download", true)
        audioOptions!!.callAttr("__setitem__", "format", "bestaudio[ext=m4a]/bestaudio[ext=mp3]/bestaudio")
        audioOptions!!.callAttr("__setitem__", "extract_flat", false)
        audioOptions!!.callAttr("__setitem__", "noplaylist", true)
        audioOptions!!.callAttr("__setitem__", "socket_timeout", 10)
        audioOptions!!.callAttr("__setitem__", "retries", 1)

        // Info extraction config
        infoOptions = builtins!!.callAttr("dict")
        infoOptions!!.callAttr("__setitem__", "quiet", true)
        infoOptions!!.callAttr("__setitem__", "no_warnings", true)
        infoOptions!!.callAttr("__setitem__", "skip_download", true)
        infoOptions!!.callAttr("__setitem__", "extract_flat", true)
        infoOptions!!.callAttr("__setitem__", "noplaylist", true)
        infoOptions!!.callAttr("__setitem__", "socket_timeout", 10)
        infoOptions!!.callAttr("__setitem__", "retries", 1)

        // Search config
        searchOptions = builtins!!.callAttr("dict")
        searchOptions!!.callAttr("__setitem__", "quiet", true)
        searchOptions!!.callAttr("__setitem__", "no_warnings", true)
        searchOptions!!.callAttr("__setitem__", "skip_download", true)
        searchOptions!!.callAttr("__setitem__", "extract_flat", true)
        searchOptions!!.callAttr("__setitem__", "noplaylist", true)
        searchOptions!!.callAttr("__setitem__", "socket_timeout", 10)
        searchOptions!!.callAttr("__setitem__", "retries", 1)
    }

    // Create pre-configured YoutubeDL instances
    private fun createExtractors() {
        try {
            audioExtractor = ytdlpModule!!.callAttr("YoutubeDL", audioOptions)
            infoExtractor = ytdlpModule!!.callAttr("YoutubeDL", infoOptions)
            searchExtractor = ytdlpModule!!.callAttr("YoutubeDL", searchOptions)
            Log.i(TAG, "YoutubeDL extractors created and cached")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create extractors", e)
            throw e
        }
    }

    // Optimized PyObject to Map conversion using cached JSON module
    private fun pyToMap(pyObj: PyObject): Map<String, Any?> {
        val jsonStr = jsonModule!!.callAttr("dumps", pyObj).toString()
        return Gson().fromJson(jsonStr, Map::class.java) as Map<String, Any?>
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: io.flutter.plugin.common.PluginRegistry.Registrar) {
            val channel = MethodChannel(registrar.messenger(), "ytdlp_channel")
            val plugin = YtDlpPlugin()
            channel.setMethodCallHandler(plugin)
            plugin.ensurePythonStarted(registrar.context())
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ytdlp_channel")
        channel.setMethodCallHandler(this)
        ensurePythonStarted(flutterPluginBinding.applicationContext)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        Log.d(TAG, "Method call: ${call.method}")
        when (call.method) {
            "getAudioStream" -> {
                val videoId = call.argument<String>("videoId")
                val quality = call.argument<String>("quality") ?: "High"
                if (videoId == null) {
                    result.error("INVALID_ARGUMENT", "videoId is required", null)
                    return
                }
                getAudioStream(videoId, quality, result)
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
            "getPerformanceStats" -> {
                result.success(getPerformanceStats())
            }
            else -> result.notImplemented()
        }
    }

    private fun getPerformanceStats(): Map<String, Any> {
        return mapOf(
            "totalCalls" to totalCalls,
            "cacheHits" to cacheHits,
            "pythonInitialized" to (pythonInstance != null),
            "extractorsReady" to (audioExtractor != null && infoExtractor != null && searchExtractor != null)
        )
    }

    private fun getAudioStream(videoId: String, quality: String, result: Result) {
        Log.d(TAG, "Getting audio stream for: $videoId (quality: $quality)")
        scope.launch {
            try {
                val startTime = System.currentTimeMillis()
                val audioData = withContext(Dispatchers.IO) {
                    executeYtDlp(videoId, quality)
                }
                val duration = System.currentTimeMillis() - startTime
                Log.i(TAG, "Successfully extracted audio for $videoId in ${duration}ms")
                result.success(audioData)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to get audio stream for $videoId: ${e.message}", e)
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

    private fun executeYtDlp(videoId: String, quality: String = "High"): Map<String, Any?> {
        totalCalls++
        Log.d(TAG, "YTDLP: Extracting audio for $videoId (quality: $quality, call #$totalCalls)")

        val info = audioExtractor!!.callAttr("extract_info", "https://www.youtube.com/watch?v=$videoId", false)
            ?: throw Exception("Failed to extract info")

        val infoMap = pyToMap(info)
        val formats = infoMap["formats"] as? List<*> ?: throw Exception("No formats found")

        // Quality-aware format selection
        val targetBitrate = when (quality.lowercase()) {
            "low" -> 128  // Target ~128 kbps for low quality
            "medium" -> 160  // Target ~160 kbps for medium quality
            "high" -> 256  // Target ~256+ kbps for high quality
            else -> 256
        }

        var bestFormat: Map<String, Any?>? = null
        var bestScore = 0

        formats.forEach { item ->
            val f = item as? Map<String, Any?> ?: return@forEach
            val acodec = f["acodec"]?.toString()?.lowercase()
            val vcodec = f["vcodec"]?.toString()?.lowercase()
            val ext = f["ext"]?.toString()?.lowercase()
            val abr = (f["abr"] as? Number)?.toInt() ?: 0
            val url = f["url"]?.toString()

            // Only consider audio-only formats
            if (acodec != null && acodec != "none" && (vcodec == null || vcodec == "none") && url != null) {
                // Score based on quality preference and proximity to target bitrate
                var score = when (quality.lowercase()) {
                    "low" -> if (abr <= 128) 1000 - (128 - abr) else 0  // Prefer <= 128kbps
                    "medium" -> if (abr in 129..192) 1000 - kotlin.math.abs(160 - abr) else 0  // Prefer ~160kbps
                    "high" -> abr  // Prefer highest bitrate
                    else -> abr
                }

                // Bonus for preferred formats
                if (ext == "m4a") score += 100
                else if (ext == "mp3") score += 50

                if (score > bestScore) {
                    bestScore = score
                    bestFormat = f
                }
            }
        }

        if (bestFormat == null) throw Exception("No suitable audio format found")

        val title = infoMap["title"]?.toString() ?: ""
        val duration = (infoMap["duration"] as? Number)?.toInt() ?: (infoMap["duration"] as? Double)?.toInt() ?: 0
        val thumbnail = infoMap["thumbnail"]?.toString() ?: ""
        val uploader = infoMap["uploader"]?.toString() ?: ""
        val bitrate = (bestFormat!!["abr"] as? Number)?.toInt() ?: (bestFormat!!["tbr"] as? Number)?.toInt() ?: 128

        Log.d(TAG, "Selected format: ${bitrate}kbps for quality: $quality")
        return mapOf(
            "url" to bestFormat!!["url"],
            "title" to title,
            "duration" to duration,
            "thumbnail" to thumbnail,
            "uploader" to uploader,
            "bitrate" to bitrate
        )
    }

    private fun executeYtDlpInfo(videoId: String): Map<String, Any?> {
        Log.d(TAG, "YTDLP: Getting info for $videoId")

        val info = infoExtractor!!.callAttr("extract_info", "https://www.youtube.com/watch?v=$videoId", false)
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
        Log.d(TAG, "YTDLP: Searching for '$query' (max $maxResults results)")

        val searchExpr = "ytsearch$maxResults:$query"
        val result = searchExtractor!!.callAttr("extract_info", searchExpr, false)
            ?: throw Exception("Search failed")

        val resultMap = pyToMap(result)
        val entries = resultMap["entries"] as? List<*> ?: return emptyList()

        return entries.mapNotNull { item ->
            val e = item as? Map<String, Any?> ?: return@mapNotNull null
            mapOf(
                "id" to (e["id"]?.toString() ?: ""),
                "title" to (e["title"]?.toString() ?: ""),
                "duration" to ((e["duration"] as? Number)?.toInt() ?: (e["duration"] as? Double)?.toInt() ?: 0),
                "thumbnail" to (e["thumbnail"]?.toString() ?: ""),
                "uploader" to (e["uploader"]?.toString() ?: ""),
                "view_count" to ((e["view_count"] as? Number)?.toInt() ?: (e["view_count"] as? Double)?.toInt() ?: 0)
            )
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
