package com.example.safit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "distress_channel"
    private lateinit var methodChannel: MethodChannel
    private val DISTRESS_ACTION = "com.example.safit.DISTRESS_SIGNAL"

    private val distressReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == DISTRESS_ACTION) {
                // Forward to Flutter
                methodChannel.invokeMethod("triggerDistress", null)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val intent = Intent(this, PowerButtonService::class.java)
        startService(intent)

        // Register broadcast receiver
        val filter = IntentFilter(DISTRESS_ACTION)
        registerReceiver(distressReceiver, filter)
    }

    override fun onDestroy() {
        unregisterReceiver(distressReceiver)
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel.setMethodCallHandler { call, result ->
            if (call.method == "triggerDistress") {
                // Handle the call if necessary
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}
