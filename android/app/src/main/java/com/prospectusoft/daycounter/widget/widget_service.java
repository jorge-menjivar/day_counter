package com.prospectusoft.daycounter.widget;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.content.Intent;
import android.widget.RemoteViews;

import com.prospectusoft.daycounter.R;

public class widget_service extends AppWidgetProvider {

  
  @Override
  public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
    
    for (int widgetId : appWidgetIds) {
  
      String number = "7";
  
      RemoteViews remoteViews = new RemoteViews(context.getPackageName(), R.layout.widget_layout);
      remoteViews.setTextViewText(R.id.widget_days, number);
  
      Intent intent2 = new Intent(context, ConfigActivity.class);
      PendingIntent pendingIntent = PendingIntent.getActivity(context, 1, intent2, 0);
      
      remoteViews.setOnClickPendingIntent(R.id.widget_days, pendingIntent);
  
      appWidgetManager.updateAppWidget(widgetId, remoteViews);
    }
  }
  
}

