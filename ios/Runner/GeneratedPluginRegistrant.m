//
//  Generated file. Do not edit.
//

#import "GeneratedPluginRegistrant.h"
#import <fluttertoast/FluttertoastPlugin.h>
#import <home_screen_widgets/HomeScreenWidgetsPlugin.h>
#import <path_provider/PathProviderPlugin.h>
#import <quick_actions/QuickActionsPlugin.h>
#import <sqflite/SqflitePlugin.h>

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [FluttertoastPlugin registerWithRegistrar:[registry registrarForPlugin:@"FluttertoastPlugin"]];
  [HomeScreenWidgetsPlugin registerWithRegistrar:[registry registrarForPlugin:@"HomeScreenWidgetsPlugin"]];
  [FLTPathProviderPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTPathProviderPlugin"]];
  [FLTQuickActionsPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTQuickActionsPlugin"]];
  [SqflitePlugin registerWithRegistrar:[registry registrarForPlugin:@"SqflitePlugin"]];
}

@end
