package io.flutter.plugins;

import io.flutter.plugin.common.PluginRegistry;
import io.github.ponnamkarthik.toast.fluttertoast.FluttertoastPlugin;
import com.prospectusoft.homescreenwidgets.HomeScreenWidgetsPlugin;
import io.flutter.plugins.pathprovider.PathProviderPlugin;
import io.flutter.plugins.quickactions.QuickActionsPlugin;
import com.tekartik.sqflite.SqflitePlugin;

/**
 * Generated file. Do not edit.
 */
public final class GeneratedPluginRegistrant {
  public static void registerWith(PluginRegistry registry) {
    if (alreadyRegisteredWith(registry)) {
      return;
    }
    FluttertoastPlugin.registerWith(registry.registrarFor("io.github.ponnamkarthik.toast.fluttertoast.FluttertoastPlugin"));
    HomeScreenWidgetsPlugin.registerWith(registry.registrarFor("com.prospectusoft.homescreenwidgets.HomeScreenWidgetsPlugin"));
    PathProviderPlugin.registerWith(registry.registrarFor("io.flutter.plugins.pathprovider.PathProviderPlugin"));
    QuickActionsPlugin.registerWith(registry.registrarFor("io.flutter.plugins.quickactions.QuickActionsPlugin"));
    SqflitePlugin.registerWith(registry.registrarFor("com.tekartik.sqflite.SqflitePlugin"));
  }

  private static boolean alreadyRegisteredWith(PluginRegistry registry) {
    final String key = GeneratedPluginRegistrant.class.getCanonicalName();
    if (registry.hasPlugin(key)) {
      return true;
    }
    registry.registrarFor(key);
    return false;
  }
}
