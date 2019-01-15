import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// Utils
import 'package:fluttertoast/fluttertoast.dart';

// Storage
import 'package:sqflite/sqflite.dart';
import 'utils/counter_database.dart';


class AddCounterScreen extends StatefulWidget {
  AddCounterScreen();

  @override
  createState() => AddCounterState();
}

class AddCounterState extends State<AddCounterScreen> {
  AddCounterState();

  final TextEditingController _controllerName = new TextEditingController();
  final _nameFieldKey = GlobalKey<FormFieldState>();

  bool _firstTry = true;

  var queryResult;
  Database db;
  CounterDatabase counterDatabase = new CounterDatabase();

  int modifiedDate;
  String modifiedReadable;
  
  bool f = true;
  bool s = false;

  @override
  void initState(){
    super.initState();
    _initDb();
    var now = DateTime.now();
    String month;
    switch (now.month) {
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
    modifiedReadable = "$month ${now.day}, ${now.year}";
  }

    @override
  void dispose() {
    super.dispose();
  }

  // Initizialize Database
  void _initDb() async {
    counterDatabase.getDb()
    .then((lisDb) async{
      db = lisDb;
      var result = await counterDatabase.getQuery(db);
      this.setState(() => queryResult = result);
    });
  }

  // Addind a new counter to database and closing screen
  void _createCounter(String name) async{
    await counterDatabase.getCounterQuery(db, name).then((result) async {
      if (result.length == 0) {
        var now = DateTime.now();
        
        // Reformatting the date so that it starts at midnight. Rather than at time now.
        var today = DateTime(now.year, now.month, now.day);
        var last = today.millisecondsSinceEpoch;
        var initial = last;

        // If the date has been modified and is not set to today. Otherwise we use the default code
        if (modifiedDate != null && DateTime.fromMillisecondsSinceEpoch(modifiedDate) != today){
          var lastFormatted = DateTime.fromMillisecondsSinceEpoch(modifiedDate);
          var v = DateTime.now().difference(lastFormatted).inDays;
          await counterDatabase.addToDb(db, name, v, modifiedDate, last, f, s);
          print("initial = ${DateTime.fromMillisecondsSinceEpoch(modifiedDate).hour}");
          print("last = ${DateTime.fromMillisecondsSinceEpoch(last).hour}");
        }
        else {
          await counterDatabase.addToDb(db, name, 0, initial, last, f, s);
          print("initial = ${DateTime.fromMillisecondsSinceEpoch(initial).hour}");
          print("last = ${DateTime.fromMillisecondsSinceEpoch(last).hour}");
        }
        Navigator.pop(context);
      }
      else {
        Fluttertoast.showToast(
          msg: "Another counter with the same name already exists",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIos: 2,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    });
  }

  Future <void> _modifyDate(DateTime v) async {
    modifiedDate = v.millisecondsSinceEpoch;

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

    setState(() {modifiedReadable = "$month ${v.day}, ${v.year}";});
    return;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text(
          "New Counter",
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
                  autofocus: true,
                  autovalidate: true,
                  decoration: new InputDecoration(
                    labelText: "Counter Name",
                    border: const OutlineInputBorder()
                  ),
                  validator: (text) {
                    if (_firstTry == false && text.length < 1)
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
                        modifiedReadable,
                        style: TextStyle(
                          // If switch is on display enabled
                          color: (modifiedDate != null) ? Colors.black87 : Colors.black45,
                          fontSize: 30,
                          fontWeight: FontWeight.w400,
                        )
                      ),
                    ],
                  ),
                  onTap: () => showDatePicker(
                    initialDate: new DateTime.now(),
                    firstDate: new DateTime.now().subtract(new Duration(days: 5000)),
                    lastDate: new DateTime.now(),
                    context: context,
                  ).then((v) async {
                    if (v != null){
                      await _modifyDate(v);
                    }
                  })
                ),
                
                // --------------------------------------- Counter Settngs -----------------------------------
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
                
                
                // ------------------------------------ Buttons -------------------------------------------
                (Platform.isAndroid)
                ? new RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                  ),
                  child: new Text(
                    "ADD COUNTER",
                    style: TextStyle(
                      fontSize: 14.0,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                      color: Colors.white
                    )
                  ),
                  color: Colors.green,
                  onPressed: (){
                    _firstTry = false;
                    if (_nameFieldKey.currentState.validate()){
                      _createCounter(_controllerName.text.toString());
                    }
                  }
                )
                : CupertinoButton(
                  child: new Text("ADD COUNTER"),
                  color: Colors.green,
                  onPressed: (){
                    _firstTry = false;
                    if (_nameFieldKey.currentState.validate()){
                      _createCounter(_controllerName.text.toString());
                    }
                  }
                ),
              ],
            )
          )
        ],
      ),
    );
  }
}