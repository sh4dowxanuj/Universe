package com.shadow.blackhole

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
        System.out.println("BLACKHOLE: ========================================")
        System.out.println("BLACKHOLE: Configuring Flutter engine")
        android.util.Log.e(TAG, "BLACKHOLE: Registering YtDlpPlugin")
        println("BLACKHOLE: Creating YtDlpPlugin instance")
        val plugin = YtDlpPlugin()
        flutterEngine.plugins.add(plugin)
        System.out.println("BLACKHOLE: YtDlpPlugin added: ${plugin.javaClass.name}")
        android.util.Log.e(TAG, "BLACKHOLE: Plugin registration complete")
        System.out.println("BLACKHOLE: ========================================")
    }
}