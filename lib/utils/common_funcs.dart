import 'dart:ui';
import 'dart:io';

// Utils
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_view/pin_code_view.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'algorithms.dart';
import 'package:flutter/cupertino.dart';

// Storage
import 'package:sqflite/sqflite.dart';
import 'counter_database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'flags_database.dart';

class CommonFunctions {
  
  CounterDatabase counterDatabase = CounterDatabase();
  FlagsDatabase flagsDatabase = FlagsDatabase();
  
  /// Adds flag with the given date to the database.
  Future<void> addRedFlagToDb (DateTime dateTime, String name, String initial) async{
    
    assert (dateTime != null);
    // The initial date of the counter
    DateTime initDate = DateTime.fromMillisecondsSinceEpoch(int.parse(initial));
    
    // The date passed from the date picker
    String date = dateTime.millisecondsSinceEpoch.toString();
    
    // Setting the millisecondsSinceEpoch to the beginning of the day of today.
    var today = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day
    );
    
    // Setting the millisecondsSinceEpoch to the beginning of the day if the flag is for today.
    if (DateTime.now().difference(dateTime).inDays == 0) {
      var d = DateTime(
        dateTime.year, dateTime.month, dateTime.day
      );
      date = d.millisecondsSinceEpoch.toString();
    }
    
    int initDif = today.difference(initDate).inDays;
    
    int curDif = today.difference(dateTime).inDays;
    
    // Making sure the flag date is after initial date and before today's date
    if (curDif >= 0 && curDif < initDif) {
      
      // Making sure flag does not already exists
      await flagsDatabase.getDb(name).then((db) async {
        await flagsDatabase.getFlagQuery(db, date).then((q) async {
          if (q.length == 0){
            await flagsDatabase.addToDb(db, date);
          }

          else {
            Fluttertoast.showToast(
              msg: "Flag already exists",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIos: 2,
              backgroundColor: Colors.transparent,
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
        backgroundColor: Colors.transparent,
        textColor: Colors.white,
      );
    }
    return;
  }
  
  
  /// Calculate if days should be added to the given counter [name]
  Future<void> incrementCounter(Database db, String name, String valueString, String lastString) async{
    
    DateTime _last = DateTime.fromMillisecondsSinceEpoch(int.parse(lastString));
    int _counter = int.parse(valueString);
    var _today = DateTime.now();

    // The library DateTime automatically calculates the day difference for us.
    int newDays = _today.difference(_last).inDays;
    print(newDays);
    if (newDays <= 0){
      Fluttertoast.showToast(
        msg: "Come back tomorrow",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 2,
        backgroundColor: Colors.transparent,
        textColor: Colors.white,
      );
      return;
    }
    else {
      _counter += newDays;
      Fluttertoast.showToast(
        msg: "$newDays added!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 2,
        backgroundColor: Colors.transparent,
        textColor: Colors.white,
      );
    }
    
    // Saving update to device
    var todayEpoch = DateTime.now().millisecondsSinceEpoch;
    await counterDatabase.updateCounter(db, name, _counter.toString(), todayEpoch.toString());
  }
  
  
  /// Delete this counter[name] from the database
  Future<void> deleteCounter(Database db, String name) async{
    counterDatabase.deleteCounter(db, name).then((v) async {
      await flagsDatabase.deleteDb(name);
      Fluttertoast.showToast(
        msg: "$name deleted!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIos: 2,
        backgroundColor: Colors.transparent,
        textColor: Colors.white,
      );
    });
  }
  
  /// Delete the given[name] flag database
  Future<void> deleteFlagsDatabase(String name) async{
    await flagsDatabase.deleteDb(name);
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