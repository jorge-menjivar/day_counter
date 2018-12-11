package com.prospectusoft.daycounter

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import io.flutter.app.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant
import android.widget.RemoteViews

import com.prospectusoft.daycounter.widget.widget_service
import com.prospectusoft.homescreenwidgets.HomeScreenWidgetsPlugin
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  companion object {
    @JvmStatic
    var methodString = ""
    @JvmStatic
    var argumentsString = ""
    const val CHANNEL = "com.prospectusoft.daycounter"
  }
  
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    
    GeneratedPluginRegistrant.registerWith(this)
    
    MethodChannel(flutterView, CHANNEL).setMethodCallHandler { call, result ->
      if (call.method == "ready") {
        if (methodString != "" && argumentsString != "") {
          val intent1 = Intent(this, HomeScreenWidgetsPlugin.ConfigHandlerActivity::class.java)
          intent1.putExtra("method", methodString)
          intent1.putExtra("arguments", argumentsString)
          this.startActivity(intent1)
          methodString = ""
          argumentsString = ""
        }
        result.success(true)
      } else {
        result.notImplemented()
      }
    }
  }
  
  override fun onResume() {
    super.onResume()
    val name = ComponentName(this@MainActivity, widget_service::class.java)
    val appWidgetManager = AppWidgetManager.getInstance(this@MainActivity)
    appWidgetManager.updateAppWidget(name, updateUI())
  }
  
  fun updateUI(): RemoteViews {
    val remoteViews = RemoteViews(this.packageName, R.layout.widget_layout)
    remoteViews.setTextViewText(R.id.widget_days, "7")
    
    return remoteViews
  }
  
}
