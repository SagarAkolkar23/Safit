package com.example.safit

import android.app.*
import android.content.*
import android.media.*
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.util.Log

class PowerButtonService : Service() {

    companion object {
        private const val TAG = "PowerButtonService"
        private const val CHANNEL_ID = "power_button_channel"

        private const val PRESS_THRESHOLD = 2      // double-press
        private const val INTERVAL_MS = 2_000      // 2 second window
        private const val DISTRESS_ACTION = "com.example.safit.DISTRESS_SIGNAL"
    }

    private var pressCount = 0
    private var lastPress = 0L

    // -------------------------------------------------------------------------
    // BroadcastReceiver – counts SCREEN_ON / SCREEN_OFF events
    // -------------------------------------------------------------------------
    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(c: Context?, i: Intent?) {
            val action = i?.action ?: return
            val now = System.currentTimeMillis()

            if (action == Intent.ACTION_SCREEN_OFF || action == Intent.ACTION_SCREEN_ON) {
                pressCount = if (now - lastPress < INTERVAL_MS) pressCount + 1 else 1
                lastPress  = now
                Log.d(TAG, "count=$pressCount action=$action")

                if (pressCount == PRESS_THRESHOLD) {
                    pressCount = 0
                    playAlertSound()
                    sendDistressToFlutter()       // <-- NEW
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // Service lifecycle
    // -------------------------------------------------------------------------
    override fun onCreate() {
        super.onCreate()

        registerReceiver(
            screenReceiver,
            IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
            }
        )

        startForeground(1, buildSilentNotification())
        Log.d(TAG, "Service started & receiver registered")
    }

    override fun onDestroy() {
        unregisterReceiver(screenReceiver)
        Log.d(TAG, "Service destroyed")
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // -------------------------------------------------------------------------
    // Foreground-service notification (silent)
    // -------------------------------------------------------------------------
    private fun buildSilentNotification(): Notification {
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Power-Button Listener",
                    NotificationManager.IMPORTANCE_MIN
                )
            )
        }
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("Listening for power-button shortcut…")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setOngoing(true)
            .build()
    }

    // -------------------------------------------------------------------------
    // Play custom sound from res/raw/alert_sound.mp3
    // -------------------------------------------------------------------------
    private fun playAlertSound() {
        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager

        val focusGranted =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val req = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                    .setOnAudioFocusChangeListener { }
                    .build()
                audioManager.requestAudioFocus(req)
            } else {
                audioManager.requestAudioFocus(
                    null,
                    AudioManager.STREAM_ALARM,
                    AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
                )
            } == AudioManager.AUDIOFOCUS_REQUEST_GRANTED

        if (!focusGranted) {
            Log.e(TAG, "Audio focus NOT granted")
            return
        }

        try {
            val player = MediaPlayer.create(this, R.raw.alert_sound)
            player.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
            player.setOnCompletionListener {
                it.release()
                audioManager.abandonAudioFocus(null)
            }
            player.start()
            Log.d(TAG, "Custom alert_sound.mp3 playing")
        } catch (e: Exception) {
            Log.e(TAG, "Custom sound failed, falling back", e)
            // fallback ringtone if custom fails
            try {
                val uri: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                RingtoneManager.getRingtone(applicationContext, uri).apply {
                    audioAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .build()
                    play()
                }
            } catch (ex: Exception) {
                Log.e(TAG, "Fallback ringtone failed", ex)
            }
        }
    }

    // -------------------------------------------------------------------------
    // Send broadcast back to Flutter
    // -------------------------------------------------------------------------
    private fun sendDistressToFlutter() {
        val intent = Intent(DISTRESS_ACTION)
        sendBroadcast(intent)
        Log.d(TAG, "Distress broadcast sent to Flutter")
    }
}
