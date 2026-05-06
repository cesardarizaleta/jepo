package com.example.jepo

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.content.Intent
import android.os.Bundle
import android.view.WindowManager

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.example.jepo/foreground"
    private val PRE_ALERT_EXTRA = "SHOW_PRE_ALERT"
    private val PRE_ALERT_SECONDS_EXTRA = "PRE_ALERT_SECONDS"

    private var methodChannel: MethodChannel? = null
    private var pendingPreAlertSeconds: Int? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "bringToForeground" -> {
                    bringToForeground()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // If this Activity was launched from a fullScreenIntent notification,
        // notify Flutter immediately once the engine is ready.
        pendingPreAlertSeconds?.let { seconds ->
            pendingPreAlertSeconds = null
            methodChannel!!.invokeMethod("showPreAlert", mapOf("seconds" to seconds))
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        wakeUpScreen()
        handlePreAlertIntent(intent)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        wakeUpScreen()
        handlePreAlertIntent(intent)
    }

    private fun wakeUpScreen() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
    }

    private fun handlePreAlertIntent(intent: Intent?) {
        if (intent?.getBooleanExtra(PRE_ALERT_EXTRA, false) == true) {
            val seconds = intent.getIntExtra(PRE_ALERT_SECONDS_EXTRA, 5)
            val channel = methodChannel
            if (channel != null) {
                // Flutter engine already ready — invoke directly
                channel.invokeMethod("showPreAlert", mapOf("seconds" to seconds))
            } else {
                // Engine not ready yet — store and send once engine initializes
                pendingPreAlertSeconds = seconds
            }
        }
    }

    private fun bringToForeground() {
        wakeUpScreen()
        val intent = Intent(this, MainActivity::class.java)
        intent.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
            Intent.FLAG_ACTIVITY_SINGLE_TOP
        )
        startActivity(intent)
    }
}
