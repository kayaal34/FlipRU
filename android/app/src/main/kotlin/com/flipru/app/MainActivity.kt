package com.flipru.app

import android.content.ActivityNotFoundException
import android.content.Intent
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.flipru.app/tts",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                // Seslendirme dili kurulu degilse kullaniciyi sistemin ses
                // indirme ekranina goturuyoruz; tarif etmek yerine oraya
                // birakmak tek dokunusluk fark yaratiyor.
                "installVoiceData" -> result.success(openTtsSettings())
                else -> result.notImplemented()
            }
        }
    }

    private fun openTtsSettings(): Boolean {
        val candidates = listOf(
            Intent(TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA),
            Intent("com.android.settings.TTS_SETTINGS"),
        )
        for (intent in candidates) {
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            try {
                startActivity(intent)
                return true
            } catch (_: ActivityNotFoundException) {
                // Sonraki adaya gec.
            }
        }
        return false
    }
}
