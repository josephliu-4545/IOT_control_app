package com.example.iot_control_app

import android.content.Context
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val shortcutChannelName = "iot_control_app/volume_shortcut"
    private val longPressDurationMs = 700L
    private val handler = Handler(Looper.getMainLooper())
    private var shortcutChannel: MethodChannel? = null
    private var volumeUpPressed = false
    private var longPressTriggered = false

    private val longPressAction = Runnable {
        if (!volumeUpPressed) return@Runnable
        longPressTriggered = true
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        shortcutChannel?.invokeMethod(
            "activateAssistant",
            mapOf(
                "currentVolume" to audioManager.getStreamVolume(AudioManager.STREAM_MUSIC),
                "maxVolume" to audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC),
            ),
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        shortcutChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            shortcutChannelName,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method == "getMediaVolume") {
                    val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    result.success(audioManager.getStreamVolume(AudioManager.STREAM_MUSIC))
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.keyCode != KeyEvent.KEYCODE_VOLUME_UP) {
            return super.dispatchKeyEvent(event)
        }

        when (event.action) {
            KeyEvent.ACTION_DOWN -> {
                if (event.repeatCount == 0) {
                    volumeUpPressed = true
                    longPressTriggered = false
                    handler.postDelayed(longPressAction, longPressDurationMs)
                }
                return true
            }

            KeyEvent.ACTION_UP -> {
                volumeUpPressed = false
                handler.removeCallbacks(longPressAction)
                if (!longPressTriggered) {
                    val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    audioManager.adjustStreamVolume(
                        AudioManager.STREAM_MUSIC,
                        AudioManager.ADJUST_RAISE,
                        AudioManager.FLAG_SHOW_UI,
                    )
                }
                longPressTriggered = false
                return true
            }
        }

        return super.dispatchKeyEvent(event)
    }

    override fun onDestroy() {
        handler.removeCallbacks(longPressAction)
        shortcutChannel = null
        super.onDestroy()
    }
}
