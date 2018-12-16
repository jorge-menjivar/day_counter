
import 'edit_screen.dart';
import 'add_counter_screen.dart';
import 'dart:ui';

import 'settings_screen.dart';

// Utils
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_view/pin_code_view.dart';
import 'package:charts_flutter/flutter.dart' as charts;

// Storage
import 'package:sqflite/sqflite.dart';
import 'utils/counter_database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  var queryResult;
  Database db;
  CounterDatabase counterDatabase = new CounterDatabase();

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
      this.setState(() => queryResult);
    });
  }


  /// Transfer user to Add Counter screen
  void _addCounter() async{
    Navigator.push(context, MaterialPageRoute(builder:
      (context) => AddCounterScreen())
    ).then((v) async {
      queryResult = await counterDatabase.getQuery(db);
      tileCount = queryResult.length;
      this.setState(() => queryResult);
    });
  }


  // Transfer user to Edit Counter screen
  void _editCounter(String name, String value, String last) {
    Navigator.push(context, MaterialPageRoute(builder:
      (context) => EditScreen(name: name, value: value, last: last))
    ).then((v) async {
      queryResult = await counterDatabase.getQuery(db);
      tileCount = queryResult.length;
      this.setState(() => queryResult);
    });
  }

  // Delete this counter from the database
  void _deleteCounter(String name) async{
    counterDatabase.deleteCounter(db, name).then((v) async {

      Fluttertoast.showToast(
        msg: "$name deleted!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIos: 2,
        backgroundColor: Colors.transparent,
        textColor: Colors.white,
      );

      // Update Screen
      queryResult = await counterDatabase.getQuery(db);
      tileCount = queryResult.length;
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
    await counterDatabase.updateCounter(db, name, _counter.toString(), _today.toString()).then((r) async {

      // Updating screen
      var result = await counterDatabase.getQuery(db);
      this.setState(() => queryResult = result);
    });
  }


  Future<int> _updateAll () async {
    if (queryResult != null) {
      for (int i = 0; i < queryResult.length; i++) {
        var row = queryResult[i];
        _incrementCounter(row['name'], row['value'], row['last']);
      }
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
                _deleteCounter(name);
                Navigator.of(context).pop();
              },
            ),
          ]
        );
      }
    );
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
              onPressed:() {
                }
              ),
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
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder:(context) => SettingsScreen())),
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
                    // TODO go to settings
                    //onTap: () => Navigator.pop(context);,
                  ),
                ]
              ),
            ),
          ],
        ),
      ),

      body: RefreshIndicator( // When the user drags to refresh all counters
        child: _buildCounterTitles(),
        onRefresh: () {
          return _updateAll();
        },
      ) 
    );
  }

  Widget _buildCounterTitles() {
    return ListView.builder(
      itemCount: tileCount,

      // Getting values from query of counters in database
      itemBuilder: (context, i){
        if (queryResult != null && queryResult.length> 0 && i < queryResult.length){
          var row = queryResult[i];
          return _buildRow(row['name'], row['value'], row['last']);
        }
        return null;
      }
    );
  }

  Widget _buildRow(String name, String value, String last) {

    // Data for line chart
    var data = [
      new ProgressByDate(day: 0, progress: 0, color: Colors.blue),
      new ProgressByDate(day: 10, progress: 10, color: Colors.green),
      new ProgressByDate(day: 11, progress: 8, color: Colors.purple),
    ];

    // Defining the data that corresponds to what on the chart
    var series = [
      new charts.Series<ProgressByDate, num>(
        id: 'Progress',
        domainFn: (ProgressByDate progressData, _) => progressData.day,
        measureFn: (ProgressByDate progressData, _) =>progressData.progress,
        colorFn: (ProgressByDate progressData, _) => progressData.color,
        data: data,
      ),
    ];

    // The line chart used in the cards
    var chart = new charts.LineChart(
      series,
      animate: true,
    );


    // Dismissible so we can swipe it left to delete
    return Dismissible(
      // Icon 'delete' and red background
      background: Container(
        padding: EdgeInsets.all(16.0),
        color: Colors.redAccent,
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
        alignment: Alignment.centerRight,
      ),
      // Each Dismissible must contain a Key. Keys allow Flutter to
      // uniquely identify Widgets.
      key: Key(name),
      direction: DismissDirection.endToStart,
      // We also need to provide a function that will tell our app
      // what to do after an item has been swiped away.
      onDismissed: (direction) {
        // Remove the item from our data source.
        _deleteCounter(name);

        // Show a snackbar! This snackbar could also contain "Undo" actions.
        Scaffold
            .of(context)
            .showSnackBar(SnackBar(content: Text("$name deleted")));
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[

            // Title of card
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
                        case 'red': break;
                        case 'edit': _editCounter(name, value, last); break;
                        case 'delete': _showDeleteDialog(name); break;
                      }
                    }),
                )
              ],
            ),
            

            // Line Chart
            Container(
              color: Colors.black.withAlpha(15),
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, 8, 8, 8),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return new SizedBox(
                      height: 150.0,
                      width: constraints.maxWidth,
                      child: chart,
                    );
                  }
                )
              ) 
            ),

            // Action buttons in the card
            ButtonTheme.bar(
              alignedDropdown: true,
              child: ListTile(
                leading: FlatButton(
                  child: const Text('VIEW MORE'),
                  onPressed: () { 
                    //TODO create a full screen dialog that shows the counter details
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
                        
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add_circle,
                        color: Colors.blue
                      ),
                      iconSize: 35,
                      onPressed: () => _incrementCounter(name, value, last)
                    ),
                  ]
                ),
              ),
            ),
          ]
        )
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