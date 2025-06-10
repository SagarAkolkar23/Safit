package com.example.safit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val TAG = "MainActivity"
    private val CHANNEL = "distress_channel"
    private val DISTRESS_ACTION = "com.example.safit.DISTRESS_SIGNAL"

    private lateinit var methodChannel: MethodChannel
    private lateinit var distressReceiver: BroadcastReceiver

    // ─────────────────────────────────────────────────────────────
    // Activity - life-cycle
    // ─────────────────────────────────────────────────────────────
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Start PowerButtonService (foreground) once the activity boots.
        val svc = Intent(this, PowerButtonService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(svc)
        } else {
            startService(svc)
        }
        Log.d(TAG, "PowerButtonService started")

        // Register a receiver for the custom distress broadcast
        val filter = IntentFilter(DISTRESS_ACTION)
        distressReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                Log.d(TAG, "Received $DISTRESS_ACTION broadcast → calling Flutter")
                methodChannel.invokeMethod("triggerDistress", null)
            }
        }

        // Android 12+ requires flag specification; below handles all versions
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(distressReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            registerReceiver(distressReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(distressReceiver, filter)
        }
    }

    override fun onDestroy() {
        unregisterReceiver(distressReceiver)
        super.onDestroy()
    }

    // ─────────────────────────────────────────────────────────────
    // Flutter-engine configuration
    // ─────────────────────────────────────────────────────────────
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        methodChannel.setMethodCallHandler { call, result ->
            // UI side doesn’t need to handle anything special for now
            if (call.method == "triggerDistress") {
                Log.d(TAG, "Flutter called triggerDistress from UI")
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        Log.d(TAG, "MethodChannel \"$CHANNEL\" ready")
    }
}
