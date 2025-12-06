package com.shadow.universe

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.content.Intent.FLAG_ACTIVITY_NEW_TASK

class MainActivity: FlutterActivity() {
    private val TAG = "MainActivity"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        if (intent.getIntExtra("org.chromium.chrome.extra.TASK_ID", -1) == this.taskId) {
            this.finish()
            intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        System.out.println("UNIVERSE: ========================================")
        System.out.println("UNIVERSE: Configuring Flutter engine")
        android.util.Log.e(TAG, "UNIVERSE: Registering YtDlpPlugin")
        println("UNIVERSE: Creating YtDlpPlugin instance")
        val plugin = YtDlpPlugin()
        flutterEngine.plugins.add(plugin)
        System.out.println("UNIVERSE: YtDlpPlugin added: ${plugin.javaClass.name}")
        android.util.Log.e(TAG, "UNIVERSE: Plugin registration complete")
        System.out.println("UNIVERSE: ========================================")
    }
}