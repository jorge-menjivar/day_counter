

import 'dart:ui';

import 'settings_screen.dart';
import 'view_flags_screen.dart';
import 'add_counter_screen.dart';
import 'edit_screen.dart';
import 'view_more.dart';

// Utils
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_view/pin_code_view.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'utils/algorithms.dart';
import 'utils/common_funcs.dart';

// Storage
import 'package:sqflite/sqflite.dart';
import 'utils/counter_database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'utils/flags_database.dart';

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
        canvasColor: Colors.white,
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
  
  Algorithms _algorithms = Algorithms();
  CommonFunctions common = CommonFunctions();
  
  var queryResult;
  Database db;
  CounterDatabase counterDatabase = new CounterDatabase();
  FlagsDatabase flagsDatabase = new FlagsDatabase();
  var dataLists = List<List<ProgressByDate>>();

  // If app is pin protected
  bool secured = false;
  String pin;
  final storage = new FlutterSecureStorage();

  final TextStyle _biggerFont = const TextStyle(
    fontSize: 24.0,
    color: Colors.black87
  );
  final TextStyle _drawerFont = const TextStyle(
    fontSize: 17.0,
    color: Colors.black87
    );
  final TextStyle _valueStyle = const TextStyle(
    fontSize: 36.0,
    color: Colors.blue,
  );

  int tileCount = 0;
 
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();


  @override
  void initState(){
    super.initState();
    _loadPin();
    _initDb();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  

  /// Load Pin from secure storage
  void _loadPin() async{
    pin = await storage.read(key: "pin");
    if (pin != null && pin != "") {
      secured = true;
    }
  }



  /// Initialize database
  void _initDb() async {
    counterDatabase.getDb().then((res) async{
      db = res;
      queryResult = await counterDatabase.getQuery(db);
      tileCount = queryResult.length;
      await _getData();
      setState(() => queryResult);
    });
  }


  /// Gets the data to display on the chart for all counters.
  Future<void> _getData() async {
    int size = queryResult.length;
    for (int i = 0; i < size; i++) {
      var row = queryResult[i];
      String name = row['name'];
      String initial = row['initial'];
      await flagsDatabase.getDb(name).then((res) async {
        await flagsDatabase.getQuery(res).then((queryR) async {
          // Algorithm
          var data = _algorithms.getDataList(queryR, initial);
          
          // If the data is not yet part of the list then initialize it
          if (i >= dataLists.length){
            dataLists.add(data); 
          }
          // Otherwise just set its value to the appropriate place in the list
          else {
            dataLists[i] = data;
          }
          
        });
        res.close();
      });
    }
    setState(() {});
  }
  
  /// Transfer user to Add Counter screen
  void _addCounter() async{
    Navigator.push(context, MaterialPageRoute(builder:
      (context) => AddCounterScreen())
    ).then((v) async {
      queryResult = await counterDatabase.getQuery(db);
      tileCount = queryResult.length;
      _getData();
    });
  }
  
  /// Transfer user to Edit Counter screen
  void _editCounter(String name, String value, String initial, String last) {
    Navigator.push(context, MaterialPageRoute(builder:
      (context) => EditScreen(name: name, value: value, initial: initial, last: last))
    ).then((v) async {
      queryResult = await counterDatabase.getQuery(db);
      tileCount = queryResult.length;
      this.setState(() => queryResult);
    });
  }


  
  /// Updates the Counters so that they display current values
  Future<void> _updateCounters() async {
    queryResult = await counterDatabase.getQuery(db);
    tileCount = queryResult.length;
    await _getData();
    setState(() => queryResult);
  }
  
  
  
  /// Tries to add days to all the counters and then displays their new values
  Future<int> _incrementAll() async {
    if (queryResult != null) {
      for (int i = 0; i < queryResult.length; i++) {
        var row = queryResult[i];
        common.incrementCounter(db, row['name'], row['value'], row['last']);
      }
      await _updateCounters();
      await _getData();
      setState(() {});
    }
    return 0;
  }
  
  
  void _showDeleteDialog(String name) {
    showDialog<void>(
      context: context,
      barrierDismissible: true, // user can type outside box to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Do you really want to delete \'$name\' ?'),
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
                common.deleteCounter(db, name);
                _updateCounters();
                Navigator.of(context).pop();
              },
            ),
          ]
        );
      }
    );
  }
  
  
  void _showViewMore(int i, String name, String value, String initial, String last, var chart) async {
    await Navigator.push(context, MaterialPageRoute(builder: 
      (context) => MoreScreen(name: name)));
    _updateCounters();
  }
  
  
  /// Navigate to View Flags screen and update widgets once it pops
  Future<void> _showFlags(String name) async{
    await Navigator.push(context, MaterialPageRoute(builder: (context) => FlagsScreen(name: name,)));
    _getData();
  }


  @override
  Widget build(BuildContext context) {
    if (secured) {
      return Scaffold(
        body: PinCode(
          title: Text(
            "Enter Pin",
            style: TextStyle(
                color: Colors.white, fontSize: 25.0, fontWeight: FontWeight.bold),
          ),
          subTitle: Text(
            "Welcome back",
            style: TextStyle(color: Colors.white),
          ),
          obscurePin: false,
          codeLength: 4,
          onCodeEntered: (code) {
            //callback after full code has been entered
            if (code.toString() == pin) { //PIN has been succesfully entered
              setState(() {secured = false;});
            }
          },
        ),
      );
    }
    return Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        automaticallyImplyLeading: false,
        title: new Text("Day Counter", textAlign: TextAlign.center,),
        elevation: 4.0,
      ),
      backgroundColor: Colors.white.withAlpha(230),
      bottomNavigationBar: BottomAppBar(
        
        color: Colors.lightBlue,
        shape: new CircularNotchedRectangle(), 
        notchMargin: 4.0,
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.menu),
              color: Colors.white,
              highlightColor: Colors.green,
              onPressed: () {
                _scaffoldKey.currentState.openDrawer();
              },
            ),
            IconButton(
              icon: Icon(Icons.settings),
              color: Colors.white,
              highlightColor: Colors.green,
              onPressed:() => Navigator.push(context, MaterialPageRoute(builder:(context) => SettingsScreen()))),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add More Days',
        child: new Icon(Icons.add),
        onPressed: _addCounter,
      ),
      drawer: new Drawer(
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: <Widget>[
            new Container(
              child: DrawerHeader(
                child: Text(
                  'Day Counter',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.green
                ),
              ),
            ),
            new Container(
              child: new Column(
                children: <Widget>[
                  new ListTile(
                    leading: new Icon(
                      Icons.settings,
                      color: Colors.black87,
                    ),
                    title: Text(
                      'Settings',
                      textAlign: TextAlign.left,
                      style: _drawerFont,
                    ), 
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder:(context) => SettingsScreen()));
                    },
                  ),
                  Divider(),
                  new ListTile(
                    leading: new Icon(
                      Icons.folder,
                      color: Colors.black87,
                    ),
                    title: Text(
                      'Terms of Use and Privacy',
                      textAlign: TextAlign.left,
                      style: _drawerFont,
                    ), 
                    // TODO go to privacy
                    //onTap: () => Navigator.pop(context);,
                  ),
                ]
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator( // When the user drags to refresh all counters
        child: _buildCounters(),
        onRefresh: () {
          return _incrementAll();
        },
      ) 
    );
  }

  Widget _buildCounters() {
    return ListView.builder(
      itemCount: tileCount,
      // Getting values from query of counters in database
      itemBuilder: (context, i){
        if (queryResult != null && queryResult.length> 0 && i < queryResult.length){
          var row = queryResult[i];
          return _buildCard(i, row['name'], row['value'], row['initial'], row['last']);
        }
        return null;
      }
    );
  }
  
  Widget _buildCard(int i, String name, String value, String initial, String last) {
    // In case flags have not been loaded yet
    var dataBackup;
    if (i >= dataLists.length) {
       dataBackup = [
        new ProgressByDate(day: 0, progress: 0, color: Colors.blue),
      ];
    }

    // Defining the data that corresponds to what on the chart
    var series = [
      new charts.Series<ProgressByDate, num>(
        id: 'Progress',
        domainFn: (ProgressByDate progressData, _) => progressData.day,
        measureFn: (ProgressByDate progressData, _) =>progressData.progress,
        colorFn: (ProgressByDate progressData, _) => progressData.color,
        data: (i < dataLists.length) ? dataLists[i] : dataBackup,
      ),
    ];
    
    // The line chart used in the cards
    var chart = new charts.LineChart(
      series,
      animate: true,
    );
    
    // Dismissible so we can swipe it left to delete
    return Card(
      elevation: 4,
      margin: const EdgeInsets.fromLTRB(30, 15, 30, 15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // ----------------------------- Title of card --------------------------------
          Stack(
            children: <Widget>[ 
              ListTile(
                contentPadding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                title: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 40,
                    fontWeight: FontWeight.bold
                  ),
                ),
                subtitle: new Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18
                  ),
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.fromLTRB(0, 16, 4, 8),
                trailing: PopupMenuButton(
                  icon: Icon(
                    Icons.more_vert
                  ),
                  itemBuilder: (v) => <PopupMenuItem<String>>[
                        new PopupMenuItem<String>(
                            child: ListTile(
                              leading: Icon(
                                Icons.flag,
                                color: Colors.red
                              ),
                              title: Text(
                                "View Red Flags"
                              ),
                            ),
                            value: 'red'),
                        new PopupMenuItem<String>(
                            child: ListTile(
                              leading: Icon(
                                Icons.edit,
                              ),
                              title: Text(
                                "Edit"
                              ),
                            ),
                            value: 'edit'),
                        new PopupMenuItem<String>(
                            child: ListTile(
                              leading: Icon(
                                Icons.delete_forever,
                                color: Colors.red
                              ),
                              title: Text(
                                "Delete"
                              ),
                            ),
                            value: 'delete'),
                      ],
                  onSelected: (v) {
                    switch (v) {
                      case 'red': _showFlags(name); break;
                      case 'edit': _editCounter(name, value, initial, last); break;
                      case 'delete': _showDeleteDialog(name); break;
                    }
                  }),
              )
            ],
          ),
          
          // ------------------------------ Line Chart ----------------------------------------------
          Container(
            color: Colors.black.withAlpha(15),
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 8, 8, 8),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return new SizedBox(
                    height: 120.0,
                    width: constraints.maxWidth,
                    child: chart,
                  );
                }
              )
            ) 
          ),
          
          
          //TODO
          (name != " ") ? ListTile(
              contentPadding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
              title: Text(
                "Cheat Days will go here",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold
                ),
              ),
            ) : null,

          // --------------------------------- Action buttons in the card --------------------------
          ButtonTheme.bar(
            alignedDropdown: true,
            child: ListTile(
              leading: FlatButton(
                child: const Text('VIEW MORE'),
                onPressed: () { 
                  _showViewMore(i, name, value, initial, last, chart);
                },
              ),
              trailing: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: Icon(
                      Icons.flag,
                      color: Colors.red
                    ),
                    iconSize: 30,
                    onPressed: () {
                      showDatePicker(
                        initialDate: new DateTime.now(),
                        firstDate: new DateTime.now().subtract(new Duration(days: 3000)),
                        lastDate: new DateTime.now().add(new Duration(days: 3000)),
                        context: context,
                      ).then((v) async {
                        await common.addRedFlagToDb(v, name, initial);
                        _getData();
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle,
                      color: Colors.blue
                    ),
                    iconSize: 35,
                    onPressed: () async {
                      await common.incrementCounter(db, name, value, last);
                      _updateCounters();
                    }
                  ),
                ]
              ),
            ),
          ),
        ]
      )
    );
  }
}

/// Used to set up the line charts
class ProgressByDate {
  int day;
  double progress;
  charts.Color color;
  
  ProgressByDate({this.day, this.progress, Color color}) {
    this.color = new charts.Color(r: color.red, g: color.green, b: color.blue, a: color.alpha);
  }
}