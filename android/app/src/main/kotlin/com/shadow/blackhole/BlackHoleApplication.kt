package com.shadow.blackhole

import io.flutter.app.FlutterApplication

class BlackHoleApplication : FlutterApplication() {
    companion object {
        // Custom User-Agent for YouTube streams
        const val USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }
    
    override fun onCreate() {
        super.onCreate()
        // Set default User-Agent for all HTTP requests made by ExoPlayer
        System.setProperty("http.agent", USER_AGENT)
    }
}
