package com.bnotion.uniuyotowncampus.application

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.Color
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import com.bnotion.uniuyotowncampus.R
import com.bnotion.uniuyotowncampus.SearchActivity

class BroadcastAlarm : BroadcastReceiver() {

    companion object {
        private const val NOTIFICATION_CHANNEL_ID = "UniuyoTownCampus"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelName = "UniuyoTownCampus Notifications"
            val notificationChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                channelName,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Campus navigation reminders"
                enableLights(true)
                lightColor = Color.BLUE
                vibrationPattern = longArrayOf(0, 1000, 500, 1000)
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(notificationChannel)
        }

        val alarm = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val intent1 = Intent(context, SearchActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            100,
            intent1,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
            .setContentIntent(pendingIntent)
            .setSmallIcon(R.drawable.ic_bell)
            .setContentTitle("Uniuyo Town Campus")
            .setContentText("Tap to access scheduled location")
            .setSound(alarm)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setTicker("UniuyoTownCampus")
            .setVibrate(longArrayOf(1000, 1000))
            .setLargeIcon(BitmapFactory.decodeResource(context.resources, R.mipmap.ic_launcher))
            .setAutoCancel(true)
            .build()

        if (intent.action == "MY_NOTIFICATION_MESSAGE") {
            notificationManager.notify(1, notification)
        }
    }
}
