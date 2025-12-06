package com.shadow.universe

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

class UniverseAudioServiceActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        android.util.Log.e("UniverseAudio", "========== YtDlpPlugin Registration ==========")
        System.out.println("UNIVERSE: Registering YtDlpPlugin in AudioServiceActivity")
        flutterEngine.plugins.add(YtDlpPlugin())
        android.util.Log.e("UniverseAudio", "YtDlpPlugin registered successfully")
        System.out.println("UNIVERSE: YtDlpPlugin registration complete")
        android.util.Log.e("UniverseAudio", "==========================================")
    }
}
