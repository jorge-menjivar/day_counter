package com.prospectusoft.daycounter.widget

import android.content.Intent
import android.os.Bundle
import com.prospectusoft.daycounter.MainActivity
import io.flutter.app.FlutterActivity

class ConfigActivity : FlutterActivity() {
  
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    MainActivity.methodString = "launch"
    MainActivity.argumentsString = "widget_config"
    val intent = Intent(this, MainActivity::class.java)
    this.startActivity(intent)
    finish()
  }
}
