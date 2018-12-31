package com.prospectusoft.daycounter

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings.Global.getString
import android.support.v4.app.NotificationCompat
import android.support.v4.app.NotificationManagerCompat
import android.support.v4.content.ContextCompat.getSystemService
import android.support.v4.content.ContextCompat.getSystemService



class NotificationService : BroadcastReceiver() {
  
  override fun onReceive(context: Context, intent: Intent?) {
  
    
    // Create the NotificationChannel, but only on API 26+ because
    // the NotificationChannel class is new and not in the support library
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val name = "Reminders"
      val descriptionText = "Daily Reminder"
      val importance = NotificationManager.IMPORTANCE_DEFAULT
      val channel = NotificationChannel("dc", name, importance).apply {
        description = descriptionText
      }
      // Register the channel with the system
    
      val notificationManager: NotificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
      notificationManager.createNotificationChannel(channel)
    }
  
    // Create an explicit intent for an Activity in your app
    val intent = Intent(context, MainActivity::class.java).apply {
      flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
    }
    
    val pendingIntent: PendingIntent = PendingIntent.getActivity(context, 0, intent, 0)
  
    val mBuilder = NotificationCompat.Builder(context, "dc")
        .setSmallIcon(R.drawable.navigation_empty_icon)
        .setContentTitle("My notification")
        .setContentText("Hello World!")
        .setPriority(NotificationCompat.PRIORITY_DEFAULT)
        // Set the intent that will fire when the user taps the notification
        .setContentIntent(pendingIntent)
        .setAutoCancel(true)
  
    with(NotificationManagerCompat.from(context)) {
      // notificationId is a unique int for each notification that you must define
      notify(1, mBuilder.build())
    }
  }
  
  
}
