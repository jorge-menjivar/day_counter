import 'dart:async';

import 'package:flutter/material.dart';

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
  final TextEditingController _controllerValue = new TextEditingController();
  final _nameFieldKey = GlobalKey<FormFieldState>();
  final _valueFieldKey = GlobalKey<FormFieldState>();

  bool _firstTry = true;

  var queryResult;
  Database db;
  CounterDatabase counterDatabase = new CounterDatabase();


  @override
  void initState(){
    super.initState();
    _initDb();
  }

    @override
  void dispose() {
    super.dispose();
  }

  void _initDb() async {
    counterDatabase.getDb()
    .then((lisDb) async{
      db = lisDb;
      var result = await counterDatabase.getQuery(db);
      this.setState(() => queryResult = result);
    });
  }

  void _createCounter(String name, String value) async{
    await counterDatabase.getCounterQuery(db, name).then((result) async {
      if (result.length == 0) {
        int year = DateTime.now().year;
        int month = DateTime.now().month;
        int day = DateTime.now().day;
        var last = "$year-$month-$day";

        if (value == "")
          value = "0";

        
        // So it does not look like 01, instead 1
        int v = int.parse(value);

        await counterDatabase.addToDb(db, name, v.toString(), last);
        Navigator.pop(context);
      }
      else {
        Fluttertoast.showToast(
          msg: "Another counter with the same name already exists",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIos: 2,
          bgcolor: "#e74c3c",
          textcolor: '#ffffff'
        );
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text("New Counter"),
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
                      if (_firstTry == false && text.length < 1)
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
                    hintText: "Optional: Default is 0",
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
                  child: new Text("ADD COUNTER"),
                  onPressed: (){
                    _firstTry = false;
                    if (_nameFieldKey.currentState.validate() && _valueFieldKey.currentState.validate()){
                      Scaffold
                      .of(context)
                      .showSnackBar(
                        SnackBar(
                          content: Text('Saving Data'),
                          duration: new Duration(seconds: 4)
                        )
                      );
                      _createCounter(_controllerName.text.toString(), _controllerValue.text.toString());
                    }
                  }
                ),
              ],
            )
          );
        },
      )
    );
  }
}