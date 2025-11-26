package com.shadow.blackhole

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

class BlackHoleAudioServiceActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        android.util.Log.e("BlackHoleAudio", "========== YtDlpPlugin Registration ==========")
        System.out.println("BLACKHOLE: Registering YtDlpPlugin in AudioServiceActivity")
        flutterEngine.plugins.add(YtDlpPlugin())
        android.util.Log.e("BlackHoleAudio", "YtDlpPlugin registered successfully")
        System.out.println("BLACKHOLE: YtDlpPlugin registration complete")
        android.util.Log.e("BlackHoleAudio", "==========================================")
    }
}
