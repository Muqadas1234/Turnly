package com.example.turnly

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // High-importance channel so queue alerts appear as heads-up notifications.
        // Id must match android.notification.channelId in the backend (services/push.js).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "turnly_queue",
                "Queue updates",
                NotificationManager.IMPORTANCE_HIGH
            ).apply { description = "Token booking, turn alerts and queue updates" }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }
}