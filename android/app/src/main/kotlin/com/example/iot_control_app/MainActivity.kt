package com.example.iot_control_app

import android.content.Context
import android.media.AudioManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.KeyEvent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val shortcutChannelName = "iot_control_app/volume_shortcut"
    private val cameraChannelName = "iot_control_app/local_camera"
    private val longPressDurationMs = 700L
    private val doublePressWindowMs = 650L
    private val handler = Handler(Looper.getMainLooper())
    private var shortcutChannel: MethodChannel? = null
    private var cameraChannel: MethodChannel? = null
    private val cameraExecutor = Executors.newSingleThreadExecutor()
    private var volumeUpPressed = false
    private var longPressTriggered = false
    private var analyzeOnLongPress = false
    private var lastShortPressReleasedAt = 0L

    private val longPressAction = Runnable {
        if (!volumeUpPressed) return@Runnable
        longPressTriggered = true
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        shortcutChannel?.invokeMethod(
            if (analyzeOnLongPress) "activateEnvironmentAnalysis" else "activateAssistant",
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

        cameraChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            cameraChannelName,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method != "captureJpeg") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val captureUrl = call.argument<String>("url")
                if (captureUrl.isNullOrBlank()) {
                    result.error("INVALID_URL", "Camera URL is missing", null)
                    return@setMethodCallHandler
                }

                cameraExecutor.execute {
                    try {
                        val bytes = captureCameraThroughWifi(captureUrl)
                        runOnUiThread { result.success(bytes) }
                    } catch (error: Exception) {
                        runOnUiThread {
                            result.error(
                                "CAMERA_WIFI_ERROR",
                                error.message ?: "Camera request failed",
                                null,
                            )
                        }
                    }
                }
            }
        }
    }

    private fun captureCameraThroughWifi(captureUrl: String): ByteArray {
        val connectivityManager =
            getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val wifiNetwork = connectivityManager.allNetworks.firstOrNull { network ->
            connectivityManager.getNetworkCapabilities(network)
                ?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
        } ?: throw IllegalStateException("No Wi-Fi network is connected")

        val connection = wifiNetwork.openConnection(URL(captureUrl)) as HttpURLConnection
        return try {
            connection.requestMethod = "GET"
            connection.setRequestProperty("Accept", "image/jpeg")
            connection.setRequestProperty("Connection", "close")
            connection.useCaches = false
            connection.connectTimeout = 5000
            connection.readTimeout = 5000
            connection.connect()

            if (connection.responseCode !in 200..299) {
                throw IllegalStateException(
                    "ESP32-CAM capture failed: HTTP ${connection.responseCode}",
                )
            }
            connection.inputStream.use { it.readBytes() }.also { bytes ->
                if (bytes.isEmpty()) {
                    throw IllegalStateException("ESP32-CAM returned an empty image")
                }
            }
        } finally {
            connection.disconnect()
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
                    val elapsedSinceLastPress =
                        SystemClock.elapsedRealtime() - lastShortPressReleasedAt
                    analyzeOnLongPress = elapsedSinceLastPress in 1..doublePressWindowMs
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
                    lastShortPressReleasedAt = SystemClock.elapsedRealtime()
                } else {
                    lastShortPressReleasedAt = 0L
                }
                longPressTriggered = false
                analyzeOnLongPress = false
                return true
            }
        }

        return super.dispatchKeyEvent(event)
    }

    override fun onDestroy() {
        handler.removeCallbacks(longPressAction)
        shortcutChannel = null
        cameraChannel = null
        cameraExecutor.shutdownNow()
        super.onDestroy()
    }
}
