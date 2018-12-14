import 'dart:async';

import 'package:flutter/material.dart';

// Utils
import 'package:fluttertoast/fluttertoast.dart';

// Storage
import 'package:sqflite/sqflite.dart';
import 'utils/counter_database.dart';


class WidgetConfigScreen extends StatefulWidget {
  WidgetConfigScreen();

  @override
  createState() => ConfigState();
}

class ConfigState extends State<WidgetConfigScreen> with WidgetsBindingObserver{
  ConfigState();

  var queryResult;
  Database db;
  CounterDatabase counterDatabase = new CounterDatabase();

  final TextStyle _biggerFont = const TextStyle(
    fontSize: 24.0,
    color: Colors.black54
  );
  final TextStyle _drawerFont = const TextStyle(
    fontSize: 18.0,
    color: Colors.black54
  );
  final TextStyle _valueStyle = const TextStyle(
    fontSize: 30.0,
    color: Colors.green,
  );

  int tileCount = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();


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
    counterDatabase.getDb().then((res) async{
      db = res;
      queryResult = await counterDatabase.getQuery(db);
      tileCount = (queryResult.length * 2) + 1;
      this.setState(() => queryResult);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        automaticallyImplyLeading: false,
        title: new Text("Day Counter", textAlign: TextAlign.center,),
        elevation: 4.0,
      ),
      backgroundColor: Colors.white.withOpacity(.97),
      body: _buildCounterTitles(),
    );
  }

  Widget _buildCounterTitles() {
    return ListView.builder(
      itemCount: tileCount,
      // For even rows, the function adds a ListTile row for the word pairing.
      // For odd rows, the function adds a Divider widget to visually
      itemBuilder: (context, i){
        if (i.isOdd) return Divider();
        int index = i ~/ 2;
        if (queryResult != null && queryResult.length> 0 && index < queryResult.length){
          var row = queryResult[index];
          return _buildRow(row['name'], row['value'], row['last']);
        }
        return null;
      }
    );
  }


  Widget _buildRow(String name, String value, String last) {
    // Dismissible so we can swipe it left to delete
    return ListTile(
      contentPadding: const EdgeInsets.all(12.0),
      title: Text(
        name,
        textAlign: TextAlign.left,
        style: _biggerFont,
      ),
      trailing: new Text(
        value,
        textAlign: TextAlign.right,
        style: _valueStyle,
      ), 
      // Set up this counter to display on the widget
      onTap: () {}
    );
  }
}