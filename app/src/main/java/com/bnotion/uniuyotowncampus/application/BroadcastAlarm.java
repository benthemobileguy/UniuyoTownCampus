package com.bnotion.uniuyotowncampus.application;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;
import android.util.Log;

import androidx.core.app.NotificationCompat;

import com.bnotion.uniuyotowncampus.R;
import com.bnotion.uniuyotowncampus.SearchActivity;

public class BroadcastAlarm extends BroadcastReceiver {
    String NOTIFICATION_CHANNEL_ID = "My Channel";
    @Override
    public void onReceive(Context context, Intent intent) {
        Log.d("RECEIVE", "rgrtgr");
        NotificationManager notificationManager  = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O){
            CharSequence NOTIFICATION_CHANNEL_NAME= "ListenIn";
            NotificationChannel notificationChannel = new NotificationChannel(NOTIFICATION_CHANNEL_ID, NOTIFICATION_CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH);
            notificationChannel.setDescription("ListenIn");
            notificationChannel.enableLights(true);
            notificationChannel.setLightColor(Color.BLUE);
            notificationChannel.setVibrationPattern(new long[]{0, 1000, 500, 1000});
            notificationChannel.enableVibration(true);
            notificationManager.createNotificationChannel(notificationChannel);
        }
        Uri alarm = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
        Intent intent1 = new Intent(context, SearchActivity.class);
        intent1.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        PendingIntent pendingIntent = PendingIntent.getActivity(context, 100, intent1, PendingIntent.FLAG_UPDATE_CURRENT);
        NotificationCompat.Builder notification= new NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID);
        notification.setContentIntent(pendingIntent)
                .setSmallIcon(R.drawable.ic_bell)
                .setContentTitle("Unioyo Town Campus")
                .setContentText("Tap to access scheduled location")
                .setSound(alarm)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setTicker("listenIn")
                .setVibrate(new long[] {1000, 1000})
                .setLargeIcon(BitmapFactory.decodeResource(context.getResources(), R.mipmap.ic_launcher))
                .setAutoCancel(true)
                .build();
        if (intent.getAction().equals("MY_NOTIFICATION_MESSAGE")) {
            notificationManager.notify(1, notification.build());
        }
    }
}
