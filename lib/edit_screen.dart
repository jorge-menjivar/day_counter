import 'dart:async';

import 'package:flutter/material.dart';

// Utils
import 'package:fluttertoast/fluttertoast.dart';

// Storage
import 'package:sqflite/sqflite.dart';
import 'utils/counter_database.dart';


class EditScreen extends StatefulWidget {
  final String name, value, last;
  EditScreen({this.name,  this.value, this.last});

  @override
  createState() => EditState(pName: name, pValue: value, pLast: last);
}

class EditState extends State<EditScreen> {
  final String pName, pValue, pLast;
  EditState({this.pName,  this.pValue, this.pLast});

  final TextEditingController _controllerName = new TextEditingController();
  final TextEditingController _controllerValue = new TextEditingController();
  final _nameFieldKey = GlobalKey<FormFieldState>();
  final _valueFieldKey = GlobalKey<FormFieldState>();

  var queryResult;
  Database db;
  CounterDatabase counterDatabase = new CounterDatabase();


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
    counterDatabase.getDb()
    .then((res) async{
      db = res;
    });
  }

  // Save the changes to database and close screen
  void _updateCounter(String name, String value) async{
    // So it does not look like 01, instead 1
    int v = int.parse(value);
    await counterDatabase.getCounterQuery(db, name).then((result) async {
      if (result.length == 0 || pName == name) {
        if (name == pName){
          await counterDatabase.updateCounter(db, name, v.toString(), pLast);
        }
        else {
          counterDatabase.deleteCounter(db, pName);
          counterDatabase.addToDb(db, name, v.toString(), pLast);
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
                new TextFormField(
                  key: _valueFieldKey,
                  controller: _controllerValue,
                  keyboardType: TextInputType.number,
                  autocorrect: false,
                  autofocus: true,
                  autovalidate: true,
                  decoration: new InputDecoration(
                    labelText: "Initial number of days",
                    ),
                  validator: (text) {
                    if (text.contains(new RegExp(r'\D')))
                      return 'Only numbers';
                  },
                ),
                new Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                  ],
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
                new OutlineButton(
                  child: new Text("DELETE"),
                  onPressed: _deleteCounter,
                  borderSide: BorderSide(
                    color: Colors.red,
                    style: BorderStyle.solid,
                  ),
                  textColor: Colors.red,
                )
              ],
            )
          );
        },
      )
    );
  }
}