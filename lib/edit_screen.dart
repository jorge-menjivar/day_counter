import 'dart:async';

import 'package:flutter/material.dart';

// Utils
import 'package:fluttertoast/fluttertoast.dart';

// Storage
import 'package:sqflite/sqflite.dart';
import 'utils/counter_database.dart';


class EditScreen extends StatefulWidget {
  final String name, value, initial, last;
  EditScreen({
    @required this.name,
    @required this.value,
    @required this.initial,
    @required this.last
  });

  @override
  createState() => EditState(pName: name, pValue: value, pLast: last);
}

class EditState extends State<EditScreen> {
  final String pName, pValue, pInitial, pLast;
  EditState({this.pName,  this.pValue, this.pInitial, this.pLast});

  final TextEditingController _controllerName = new TextEditingController();
  final TextEditingController _controllerValue = new TextEditingController();
  final _nameFieldKey = GlobalKey<FormFieldState>();
  final _valueFieldKey = GlobalKey<FormFieldState>();

  var queryResult;
  Database db;
  CounterDatabase counterDatabase = new CounterDatabase();


  String modifiedDate;
  String modifiedRedable;


  @override
  void initState(){
    super.initState();
    _initDb();
    _controllerName.text = pName;
    _controllerValue.text = pValue;
  }

    @override
  void dispose() {
    super.dispose();
  }

  // Initizialize Database
  void _initDb() async {

    //TODO make sure that you update the last date when you update or restart so user cannot add days right after such action
    counterDatabase.getDb()
    .then((res) async{
      db = res;
    });

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
    modifiedRedable = "$month ${now.day}, ${now.year}";
  }

  // Save the changes to database and close screen
  void _updateCounter(String name, String value) async{
    // So it does not look like 01, instead 1
    int v = int.parse(value);
    await counterDatabase.getCounterQuery(db, name).then((result) async {
      if (result.length == 0 || pName == name) {
        if (name == pName){
          if (modifiedDate != null){
            var lastFormatted = DateTime.fromMillisecondsSinceEpoch(int.parse(modifiedDate));
            var v = DateTime.now().difference(lastFormatted).inDays;
            await counterDatabase.updateCounter(db, name, modifiedDate, pLast);
          }
          else {
            await counterDatabase.updateCounter(db, name, v.toString(), pLast);
          }
        }
        else {
          counterDatabase.deleteCounter(db, pName);
          counterDatabase.addToDb(db, name, v.toString(), modifiedDate, pLast);
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

  // Delete this counter from the database and close screen
  void _deleteCounter() async{
    counterDatabase.deleteCounter(db, pName).then((v) async {

      Fluttertoast.showToast(
        msg: "$pName deleted!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIos: 2,
        backgroundColor: Colors.transparent,
        textColor: Colors.white,
      );

      Navigator.pop(context);
    });
  }


  Future <void> _modifyDate(DateTime v) async {
    modifiedDate = v.millisecondsSinceEpoch.toString();


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

    setState(() {modifiedRedable = "$month ${v.day}, ${v.year}";});
    return;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text("Editing Counter '$pName'", textAlign: TextAlign.center),
        elevation: 4.0,
      ),
      body: new Builder(
        builder: (BuildContext context) {
          return Container(
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
                        modifiedRedable,
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
                    firstDate: new DateTime.now().subtract(new Duration(days: 3000)),
                    lastDate: new DateTime.now().add(new Duration(days: 3000)),
                    context: context,
                  ).then((v) async => await _modifyDate(v))
                ),
                new SizedBox(
                  height: 48.0,
                ),
                new RaisedButton(
                  child: new Text("SAVE"),
                  onPressed: (){
                    if (_nameFieldKey.currentState.validate() && _valueFieldKey.currentState.validate()){
                      Scaffold
                      .of(context)
                      .showSnackBar(
                        SnackBar(
                          content: Text('Saving Data'),
                          duration: new Duration(seconds: 4)
                        )
                      );
                      _updateCounter(_controllerName.text.toString(), _controllerValue.text.toString());
                    }
                  }
                ),
                new SizedBox(
                  height: 30,
                ),
                new Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new OutlineButton(
                      child: new Text("RESTART"),
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          barrierDismissible: true, // user can type outside box to dismiss
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Are you sure?'),
                              content: SingleChildScrollView(
                                child: ListBody(
                                  children: <Widget>[
                                    Text('Do you really want to restart \'$pName\' ?'),
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
                                    _updateCounter(pName, "0");
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ]
                            );
                          }
                        );
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
                    new OutlineButton(
                      child: new Text("DELETE"),
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          barrierDismissible: true, // user can type outside box to dismiss
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Are you sure?'),
                              content: SingleChildScrollView(
                                child: ListBody(
                                  children: <Widget>[
                                    Text('Do you really want to delete \'$pName\' ?'),
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
                                    _deleteCounter();
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ]
                            );
                          }
                        );
                      },
                      borderSide: BorderSide(
                        color: Colors.red,
                        style: BorderStyle.solid,
                      ),
                      textColor: Colors.red,
                    ),
                  ],
                ),
              ],
            )
          );
        },
      )
    );
  }
}