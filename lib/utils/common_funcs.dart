import 'dart:ui';
import 'dart:io';

// Utils
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Storage
import 'package:sqflite/sqflite.dart';
import 'counter_database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'flags_database.dart';
import 'gap_average_database.dart';
import 'schedules_database.dart';

class CommonFunctions {
  
  final storage = new FlutterSecureStorage();
  
  CounterDatabase _counterDatabase = CounterDatabase();
  FlagsDatabase _flagsDatabase = FlagsDatabase();
  GapAverageDatabase _gapAverageDatabase = GapAverageDatabase();
  SchedulesDatabase _schedulesDatabase = SchedulesDatabase();
  
  
  /// Initialize notification system
  Future<void> setUpNotifications() async {
    // Reading the saved time for daily reminder.
    String timeString = await storage.read(key: "reminderTime");

    // Reading the switch for REMINDER
    String reminderString = await storage.read(key: "reminder");
    
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid = new AndroidInitializationSettings('ic_noti');
    
    var initializationSettingsIOS = new IOSInitializationSettings();
    
    var initializationSettings = new InitializationSettings(initializationSettingsAndroid, initializationSettingsIOS);
    
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
    
    // Canceling all the previously setup notifications.
    await flutterLocalNotificationsPlugin.cancelAll();
      
      // If the reminders are enabled or default
    if (reminderString == 'true' || reminderString == null) {
      
      var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        '1', 'Daily Reminder', 'Daily reminder to keep you on track',
        importance: Importance.High,
        priority: Priority.High,
        color: Colors.green
      );
      
      var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
      
      var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
      
      // If time has been set, otherwise use default
      var reminderTime;
      if (timeString != null) {
        reminderTime = TimeOfDay(
          hour: int.parse(timeString.split(":")[0]),
          minute: int.parse(timeString.split(":")[1]),
        );
      }
      var time;
      (timeString == null) ? time = new Time(21, 0, 0) : time = new Time(reminderTime.hour, reminderTime.minute, 0);
      
      await flutterLocalNotificationsPlugin.showDailyAtTime(
        0,
        'Did you succeed today?',
        'Save your progress in the app',
        time,
        platformChannelSpecifics
      );
    }
  }
  
  Future<void> addCheatFlagToDb (DateTime dateTime, String name, int initial) async {
    // The initial date of the counter
    DateTime initDate = DateTime.fromMillisecondsSinceEpoch(initial);
    
    int date = dateTime.millisecondsSinceEpoch;
    
    // Setting the millisecondsSinceEpoch to the beginning of the day of today.
    var today = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day
    );
    
    int initDif = today.difference(initDate).inDays;
    
    int curDif = today.difference(dateTime).inDays;
    
    // Making sure the flag date is after initial date and before today's date
    if (curDif >= 0 && curDif < initDif) {
      var cheatFlagsDb = await _flagsDatabase.getDb(name);
      var cheatQuery = await _flagsDatabase.getCheatFlagQuery(cheatFlagsDb, date);
      var nonCheatQuery = await _flagsDatabase.getFlagQuery(cheatFlagsDb, date);
      
      // If does not exist
      if (cheatQuery.length == 0 && nonCheatQuery.length == 0) {
        _flagsDatabase.addToDb(cheatFlagsDb, date, 1);
      }
      
      else {
        _flagsDatabase.deleteFlag(cheatFlagsDb, date);
      }
    }
    // Print toast if flag is invalid
    else {
      Fluttertoast.showToast(
        msg: "Flag cannot exist before the start of the counter",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 2,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
  
  
  /// Adds flag with the given date to the database. Returns whether all Schedules should be rebuilt.
  Future<bool> addRedFlagToDb (DateTime dateTime, String name, int initial) async{
    assert (dateTime != null);
    bool rebuild = true;
    // The initial date of the counter
    DateTime initDate = DateTime.fromMillisecondsSinceEpoch(initial);
    
    // The date passed from the date picker
    int date = dateTime.millisecondsSinceEpoch;
    
    // Setting the millisecondsSinceEpoch to the beginning of the day of today.
    var today = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day
    );
    
    // Setting the millisecondsSinceEpoch to the beginning of the day if the flag is for today.
    if (DateTime.now().difference(dateTime).inDays == 0) {
      // If the flag is for today. It is not necessary to rebuild the whole database. Only today, which is done automatically.
      rebuild = false;
      var d = DateTime(
        dateTime.year, dateTime.month, dateTime.day
      );
      date = d.millisecondsSinceEpoch;
    }
    
    int initDif = today.difference(initDate).inDays;
    
    int curDif = today.difference(dateTime).inDays;
    
    // Making sure the flag date is after initial date and before today's date
    if (curDif >= 0 && curDif < initDif) {
      // Making sure flag does not already exists
      await _flagsDatabase.getDb(name).then((db) async {
        await _flagsDatabase.getFlagQuery(db, date).then((q) async {
          if (q.length == 0){
            await _flagsDatabase.addToDb(db, date, 0);
          }

          else {
            Fluttertoast.showToast(
              msg: "Flag already exists",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIos: 2,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
          }
        });
        db.close();
      });
    }
    // Print toast if flag is invalid
    else {
      Fluttertoast.showToast(
        msg: "Date is invalid",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 2,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
    return rebuild;
  }
  
  
  
  /// Calculate if days should be added to the given counter [name]
  Future<void> incrementCounter(Database db, String name, int value, int last) async{
    DateTime _last = DateTime.fromMillisecondsSinceEpoch(last);
    int counter = value;
    var now = DateTime.now();
    var today = DateTime(now.year, now.month, now.day);
    
    // The library DateTime automatically calculates the day difference for us.
    int newDays = today.difference(_last).inDays;
    print(newDays);
    if (newDays <= 0){
      Fluttertoast.showToast(
        msg: "Come back tomorrow",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 2,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }
    else {
      counter += newDays;
      Fluttertoast.showToast(
        msg: "$newDays added!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 2,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
    
    // Saving update to device
    var todayEpoch = today.millisecondsSinceEpoch;
    await _counterDatabase.updateCounter(db, name, counter, todayEpoch);
    
    print("last = ${DateTime.fromMillisecondsSinceEpoch(todayEpoch).hour}");
  }
  
  
  /// Delete this counter[name] from the database
  Future<void> deleteCounter(Database db, String name) async{
    _counterDatabase.deleteCounter(db, name).then((v) async {
      await _flagsDatabase.deleteDb(name);
      await _gapAverageDatabase.deleteDb(name);
      await _schedulesDatabase.deleteDb(name);
      Fluttertoast.showToast(
        msg: "$name deleted!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIos: 2,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    });
  }
  
  /// Delete the given[name] flag database
  Future<void> deleteFlagsDatabase(String name) async{
    await _flagsDatabase.deleteDb(name);
  }
  
  
  /// Shows the an alert asking the user if delete should really be done
  Future<bool> showDeleteDialog(BuildContext context, Database db, String name) async{
    
    bool choice = false;
    
    // Await for the dialog to be dismissed before returning
    (Platform.isAndroid)
    ? await showDialog<bool>(
      context: context,
      barrierDismissible: true, // user can type outside box to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Do you really want to delete $name?'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text("I\'m sure"),
              onPressed: () {
                deleteCounter(db, name);
                Navigator.of(context).pop();
                choice = true;
              },
            ),
          ]
        );
      }
    )
    : await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Are you sure?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Do you really want to delete $name?'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text("I\'m sure"),
              onPressed: () {
                deleteCounter(db, name);
                Navigator.of(context).pop();
                choice = true;
              },
            ),
          ]
        );
      }
    );
    return choice;
  }
  
  
  /// Shows the an alert asking the user if restart should really be done
  Future<bool> showRestartDialog(BuildContext context, Database db, String name) async{
    
    bool choice = false;
    
    // Await for the dialog to be dismissed before returning
    (Platform.isAndroid)
    ? await showDialog<bool>(
      context: context,
      barrierDismissible: true, // user can type outside box to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Do you really want to restart $name?'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text("I\'m sure"),
              onPressed: () {
                Navigator.of(context).pop();
                choice = true;
              },
            ),
          ]
        );
      }
    )
    : await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Are you sure?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Do you really want to restart $name?'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text("I\'m sure"),
              onPressed: () {
                Navigator.of(context).pop();
                choice = true;
              },
            ),
          ]
        );
      }
    );
    return choice;
  }
  
}