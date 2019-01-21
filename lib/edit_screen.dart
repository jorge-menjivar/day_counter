import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'utils/common_funcs.dart';

// Utils
import 'package:fluttertoast/fluttertoast.dart';

// Storage
import 'package:sqflite/sqflite.dart';
import 'utils/counter_database.dart';
import 'utils/flags_database.dart';
import 'utils/gap_average_database.dart';
import 'utils/schedules_database.dart';

class EditScreen extends StatefulWidget {
  final String name;
  final int value, initial, last;
  final bool f, s;
  EditScreen({
    @required this.name,
    @required this.value,
    @required this.initial,
    @required this.last,
    @required this.f,
    @required this.s
  });

  @override
  createState() => EditState(pName: name, pValue: value, pInitial: initial, pLast: last, f: f, s: s);
}

class EditState extends State<EditScreen> {
  final String pName;
  final int pValue, pInitial, pLast;
  bool f, s;
  EditState({
    @required this.pName, 
    @required this.pValue,
    @required this.pInitial,
    @required this.pLast,
    @required this.f,
    @required this.s
  });

  final TextEditingController _controllerName = new TextEditingController();
  final _nameFieldKey = GlobalKey<FormFieldState>();

  var queryResult;
  Database db;
  CounterDatabase _counterDatabase = new CounterDatabase();
  FlagsDatabase _flagsDatabase = new FlagsDatabase();
  GapAverageDatabase _gapAverageDatabase = new GapAverageDatabase();
  SchedulesDatabase _schedulesDatabase = SchedulesDatabase();
  
  int initialDate;
  String _modifiedReadable;
  
  CommonFunctions common = CommonFunctions();
  
  @override
  void initState(){
    super.initState();
    _initDb();
    initialDate = pInitial;
    var initial = DateTime.fromMillisecondsSinceEpoch(pInitial);
    String month;
    switch (initial.month) {
      case 1: month = "January"; break;
      case 2: month = "February"; break;
      case 3: month = "March"; break;
      case 4: month = "April"; break;
      case 5: month = "May"; break;
      case 6: month = "June"; break;
      case 7: month = "July"; break;
      case 8: month = "August"; break;
      case 9: month = "September"; break;
      case 10: month = "October"; break;
      case 11: month = "November"; break;
      case 12: month = "December"; break;
    }
    _modifiedReadable = "$month ${initial.day}, ${initial.year}";
    _controllerName.text = pName;
  }

    @override
  void dispose() {
    super.dispose();
  }

  /// Initialize Database
  void _initDb() async {
    _counterDatabase.getDb().then((res) async{
      db = res;
      var result = await _counterDatabase.getQuery(db);
      this.setState(() => queryResult = result);
    });
  }
  
  /// Save the changes to database and close screen
  void _updateCounter(String name) async{
    await _counterDatabase.getCounterQuery(db, name).then((result) async {
      if (result.length == 0 || pName == name) {
        var initial = DateTime.fromMillisecondsSinceEpoch(initialDate);
        int difference = DateTime.now().difference(initial).inDays;

        if (name == pName) {
          await _counterDatabase.updateCounterAndInitial(db, name, difference, initialDate, pLast);
          await _counterDatabase.updateCounterSettings(db, name, f, s);
          await _flagsDatabase.getDb(name).then((v) {
            _flagsDatabase.deleteBefore(v, initialDate);
          });
        }

        else {
          _counterDatabase.deleteCounter(db, pName);
          _counterDatabase.addToDb(db, name, difference, initialDate, pLast, f, s);
          _flagsDatabase.renameDatabase(pName, name);
          _gapAverageDatabase.renameDatabase(pName, name);
          _schedulesDatabase.renameDatabase(pName, name);
        }
        
        Navigator.pop(context);
      }
      else {
        Fluttertoast.showToast(
          msg: "Another counter with the same name already exists",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIos: 2,
          backgroundColor: Colors.transparent,
          textColor: Colors.white,
        );
      }
    });
  }
  
  
  Future <void> _modifyDate(DateTime v) async {
    initialDate = v.millisecondsSinceEpoch;
    String month;
    switch (v.month) {
      case 1: month = "January"; break;
      case 2: month = "February"; break;
      case 3: month = "March"; break;
      case 4: month = "April"; break;
      case 5: month = "May"; break;
      case 6: month = "June"; break;
      case 7: month = "July"; break;
      case 8: month = "August"; break;
      case 9: month = "September"; break;
      case 10: month = "October"; break;
      case 11: month = "November"; break;
      case 12: month = "December"; break;
    }

    setState(() {_modifiedReadable = "$month ${v.day}, ${v.year}";});
    return;
  }
  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text(
          "Editing Counter $pName",
          textAlign: TextAlign.center,
          style: TextStyle(
            letterSpacing: .7,
            fontWeight: FontWeight.w600,
            color: Colors.white
          ),
        ),
        elevation: (Platform.isAndroid) ? 4 : 0,
      ),
      // Surrounded in ListView so that if it overflows while in landscape mode then the user can scroll
      body: ListView(
        // Physics to prevent scrolling when not needed
        physics: ClampingScrollPhysics(),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16.0),
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new TextFormField(
                  key: _nameFieldKey,
                  controller: _controllerName,
                  keyboardType: TextInputType.text,
                  autocorrect: false,
                  autofocus: false,
                  autovalidate: true,
                  decoration: new InputDecoration(
                    labelText: "Counter Name",
                    border: const OutlineInputBorder()
                  ),
                  validator: (text) {
                      if ( text.length < 1)
                        return 'Name must be at least 1 character long.';
                  }
                ),
                new SizedBox(
                  height: 32.0,
                ),
                new ListTile(
                  leading: Icon(
                    Icons.access_time,
                    color: Colors.black87,
                  ),
                  title: new Text(
                    "Optional: Date you started",
                  ),
                ),
                new ListTile(
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new Text(
                        _modifiedReadable,
                        style: TextStyle(
                          // If switch is on display enabled
                          color: (initialDate != pInitial) ? Colors.black87 : Colors.black45,
                          fontSize: 30,
                          fontWeight: FontWeight.w400,
                        )
                      ),
                    ],
                  ),
                  onTap: () => showDatePicker(
                    initialDate: new DateTime.fromMillisecondsSinceEpoch(pInitial),
                    firstDate: new DateTime.now().subtract(new Duration(days: 5000)),
                    lastDate: new DateTime.now(),
                    context: context,
                  ).then((v) async {
                      if (v != null)
                        await _modifyDate(v);
                    })
                ),
                
                // --------------------------------------- Counter Settings -----------------------------------
                new ListTile(
                  leading: Icon(
                    Icons.flag,
                    color: Colors.red
                  ),
                  title: Text (
                    "Allow Red Flags"
                  ),
                  trailing:
                  (Platform.isAndroid)
                  ? Switch(
                    value: f,
                    onChanged: (v) {
                      f = v;
                      setState(() {});
                    }
                  )
                  : CupertinoSwitch(
                    value: f,
                    onChanged: (v) {
                      f = v;
                      setState(() {});
                    }
                  ),
                ),
                new SizedBox(
                  height: 48.0,
                ),
                new ListTile(
                  leading: Icon(
                    Icons.calendar_view_day,
                    color: Colors.red
                  ),
                  title: Text (
                    "Allow Cheat Days Calendar"
                  ),
                  subtitle: Text(
                    "Use with caution. Still under development, can break app."
                  ),
                  trailing:
                  (Platform.isAndroid)
                  ? Switch(
                    value: s,
                    onChanged: (v) {
                      s = v;
                      setState(() {});
                    }
                  )
                  : CupertinoSwitch(
                    value: s,
                    onChanged: (v) {
                      s = v;
                      setState(() {});
                    }
                  ),
                ),
                new SizedBox(
                  height: 48.0,
                ),
                
                
                
                // ----------------------------------------- Buttons -----------------------------------------
                (Platform.isAndroid)
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    OutlineButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25)),
                      ),
                      child: new Text(
                        "RESTART",
                        style: TextStyle(
                          fontSize: 14.0,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                          color: Colors.red
                        )
                      ),
                      onPressed: () async {
                        common.showRestartDialog(context, db, pName).then((v) {
                          if(v) {
                            var now = DateTime.now();
                            var today = DateTime(now.year, now.month, now.day);
                            initialDate = today.millisecondsSinceEpoch;
                            _updateCounter(pName);
                            common.deleteFlagsDatabase(pName);
                            _schedulesDatabase.deleteDb(pName);
                            _gapAverageDatabase.deleteDb(pName);
                          }
                        });
                      },
                      borderSide: BorderSide(
                        color: Colors.red,
                        style: BorderStyle.solid,
                      ),
                      textColor: Colors.red,
                    ),
                    new SizedBox(
                      width: 20,
                    ),
                    OutlineButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25)),
                      ),
                      child: new Text(
                        "DELETE",
                        style: TextStyle(
                          fontSize: 14.0,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                          color: Colors.red
                        )
                      ),
                      onPressed: () {
                        common.showDeleteDialog(context, db, pName).then((v) {
                          if(v)
                          Navigator.of(context).pop();
                        });
                      },
                      borderSide: BorderSide(
                        color: Colors.red,
                        style: BorderStyle.solid,
                      ),
                      textColor: Colors.red,
                    ),
                    new SizedBox(
                      width: 20,
                    ),
                    RaisedButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25)),
                      ),
                      child: new Text(
                        "SAVE",
                        style: TextStyle(
                          fontSize: 14.0,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                          color: Colors.white
                        )
                      ),
                      onPressed: (){
                        if (_nameFieldKey.currentState.validate()){
                          _updateCounter(_controllerName.text.toString());
                        }
                      },
                      color: Colors.green,
                      textColor: Colors.white,
                    )
                  ]
                )
                : Column(
                  children: <Widget>[
                    CupertinoButton(
                      child: new Text("SAVE"),
                      onPressed: (){
                        if (_nameFieldKey.currentState.validate()){
                          _updateCounter(_controllerName.text.toString());
                        }
                      },
                      color: Colors.green,
                    ),
                    CupertinoButton(
                      child: new Text(
                        "RESTART",
                        style: TextStyle(
                          color: Colors.red
                        ),
                      ),
                      onPressed: () async {
                        common.showRestartDialog(context, db, pName).then((v) {
                          if(v) {
                            var now = DateTime.now();
                            var today = DateTime(now.year, now.month, now.day);
                            initialDate = today.millisecondsSinceEpoch;
                            _updateCounter(pName);
                            common.deleteFlagsDatabase(pName);
                          }
                        });
                      },
                    ),
                    CupertinoButton(
                      child: new Text(
                        "DELETE",
                        style: TextStyle(
                          color: Colors.red
                        ),
                      ),
                      onPressed: () {
                        common.showDeleteDialog(context, db, pName).then((v) {
                          if(v)
                          Navigator.of(context).pop();
                        });
                      },
                    ),
                    new SizedBox(
                      height: 10,
                    ),
                  ],
                )
              ],
            )
          )
        ],
      ),
    );
  }
}