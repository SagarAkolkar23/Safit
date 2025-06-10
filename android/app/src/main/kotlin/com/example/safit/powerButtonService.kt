package com.example.safit

import android.app.*
import android.content.*
import android.media.*
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.hardware.camera2.CameraManager
import kotlinx.coroutines.*

class PowerButtonService : Service() {

    companion object {
        private const val TAG = "PowerButtonService"
        private const val CHANNEL_ID = "power_button_channel"

        private const val PRESS_THRESHOLD = 2      // double-press
        private const val INTERVAL_MS = 2_000      // 2 second window
        private const val DISTRESS_ACTION = "com.example.safit.DISTRESS_SIGNAL"
        private const val STOP_ACTION = "com.example.safit.STOP_ALERT"
    }

    private var pressCount = 0
    private var lastPress = 0L

    private var strobeJob: Job? = null
    private var mediaPlayer: MediaPlayer? = null

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
                    startFlashStrobe()
                    updateNotificationWithStopButton()
                    sendDistressToFlutter()
                }
            }
        }
    }

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
        stopFlashStrobe()
        stopSound()
        Log.d(TAG, "Service destroyed")
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == STOP_ACTION) {
            stopAlert()
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    // -------------------------------------------------------------------------
    // Silent foreground-service notification
    // -------------------------------------------------------------------------
    private fun buildSilentNotification(): Notification {
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Power-Button Listener",
                    NotificationManager.IMPORTANCE_LOW
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
    // Notification with Stop Button
    // -------------------------------------------------------------------------
    private fun updateNotificationWithStopButton() {
        val stopIntent = Intent(this, PowerButtonService::class.java).apply {
            action = STOP_ACTION
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("Distress alert active")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Stop",
                stopPendingIntent
            )
            .setOngoing(true)
            .build()

        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(1, notification)
    }

    // -------------------------------------------------------------------------
    // Play alert sound
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
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer.create(this, R.raw.alert_sound)
            mediaPlayer?.apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                setOnCompletionListener {
                    it.release()
                    mediaPlayer = null
                    audioManager.abandonAudioFocus(null)
                }
                start()
                Log.d(TAG, "Custom alert_sound.mp3 playing")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Custom sound failed, falling back", e)
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

    private fun stopSound() {
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
    }

    // -------------------------------------------------------------------------
    // Send broadcast back to Flutter
    // -------------------------------------------------------------------------
    private fun sendDistressToFlutter() {
        val intent = Intent(DISTRESS_ACTION)
        sendBroadcast(intent)
        Log.d(TAG, "Distress broadcast sent to Flutter")
    }

    // -------------------------------------------------------------------------
    // Flash-light strobe logic
    // -------------------------------------------------------------------------
    private fun startFlashStrobe() {
        val camMgr = getSystemService(CAMERA_SERVICE) as CameraManager
        val cameraId = camMgr.cameraIdList.firstOrNull { id ->
            camMgr.getCameraCharacteristics(id)
                .get(android.hardware.camera2.CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
        } ?: run {
            Log.w(TAG, "No flash available on this device")
            return
        }

        strobeJob?.cancel()
        strobeJob = CoroutineScope(Dispatchers.Default).launch {
            var on = false
            try {
                while (isActive) {
                    camMgr.setTorchMode(cameraId, on)
                    on = !on
                    delay(200)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Strobe failed", e)
            } finally {
                try { camMgr.setTorchMode(cameraId, false) } catch (_: Exception) {}
            }
        }
    }

    private fun stopFlashStrobe() {
        strobeJob?.cancel()
        strobeJob = null
    }

    private fun stopAlert() {
        stopFlashStrobe()
        stopSound()
        updateNotificationToSilent()
    }

    private fun updateNotificationToSilent() {
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        val notification = buildSilentNotification()
        nm.notify(1, notification)
    }
}
