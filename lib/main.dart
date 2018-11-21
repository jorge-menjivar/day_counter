import 'dart:async';

import 'package:flutter/material.dart';
import 'edit_screen.dart';
import 'add_counter_screen.dart';

// Utils
import 'package:fluttertoast/fluttertoast.dart';

// Storage
import 'package:sqflite/sqflite.dart';
import 'utils/counter_database.dart';

void main(){
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Day Counter',
      theme: new ThemeData(
        primarySwatch: Colors.green,
      ),
      home: new HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  HomeScreen();
  @override
  createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver{
  HomeScreenState();

  var queryResult;
  Database db;
  CounterDatabase counterDatabase = new CounterDatabase();

  final _biggerFont = const TextStyle(fontSize: 18.0);
  final _valueStyle = const TextStyle(
    fontSize: 24.0,
    color: Colors.green);

  @override
  void initState(){
    super.initState();
    // Initializing Database
    _initDb();
  }

    @override
  void dispose() {
    super.dispose();
  }

  // Initialize database
  void _initDb() async {
    counterDatabase.getDb().then((res) async{
      db = res;
      queryResult = await counterDatabase.getQuery(db);
      this.setState(() => queryResult);
    });
  }

  // Transfer user to Add Counter screen
  void _addCounter() async{
    Navigator.push(context, MaterialPageRoute(builder:
      (context) => AddCounterScreen())
    ).then((v) async {
      queryResult = await counterDatabase.getQuery(db);
      this.setState(() => queryResult);
    });
  }

  // Transfer user to Edit Counter screen
  void _editCounter(String name, String value, String last) {
    Navigator.push(context, MaterialPageRoute(builder:
      (context) => EditScreen(name: name, value: value, last: last))
    ).then((v) async {
      queryResult = await counterDatabase.getQuery(db);
      this.setState(() => queryResult);
    });
  }

  // The main method where the math to calculate if days should be added is done.
  void _incrementCounter(String name, String valueString, String lastString) async{
    DateTime _last = DateTime.parse(lastString);
    int _counter = int.parse(valueString);

    int year = DateTime.now().year;
    int month = DateTime.now().month;
    int day = DateTime.now().day;
    var _today = DateTime.parse("$year-$month-$day");

    // The library DateTime automatically calculates the day difference for us.
    int newDays = _today.difference(_last).inDays;
    print(newDays);
    if (newDays <= 0){
      Fluttertoast.showToast(
        msg: "Come back tomorrow",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIos: 2,
        bgcolor: "#e74c3c",
        textcolor: '#ffffff'
      );
      return;
    }
    else {
      _counter += newDays;
      Fluttertoast.showToast(
        msg: "$newDays added!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIos: 2,
        bgcolor: "#e74c3c",
        textcolor: '#ffffff'
      );
    }

    // Saving update to device
    await counterDatabase.updateCounter(db, name, _counter.toString(), _today.toString()).then((r) async {

      // Updating screen
      var result = await counterDatabase.getQuery(db);
      this.setState(() => queryResult = result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text("Day Counter"),
        elevation: 4.0,
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.lightBlue,
        shape: new CircularNotchedRectangle(), 
        notchMargin: 4.0,
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(icon: Icon(Icons.menu), onPressed: () {},),
            IconButton(icon: Icon(Icons.forum), onPressed:() {}),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add More Days',
        child: new Icon(Icons.add),
        onPressed: _addCounter,
      ),
      body: _buildCounterTitles(),
    );
  }

  Widget _buildCounterTitles() {
    return ListView.builder(
      itemCount: (queryResult.length * 2) + 1,
      padding: const EdgeInsets.all(16.0),

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
    return ListTile(
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
      onLongPress: () {
        // Send to Edit Screen
        _editCounter(name, value, last);
      },
      // Try to add days to this counter
      onTap: () => _incrementCounter(name, value, last)
    );
  }
}