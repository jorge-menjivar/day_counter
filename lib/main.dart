
import 'edit_screen.dart';
import 'add_counter_screen.dart';
import 'dart:ui';


import 'package:home_screen_widgets/home_screen_widgets.dart';
import 'widget_config_screen.dart';

// Utils
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  HomeScreenState() {
    _widgetHandler();
  }

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

  static const platform = const MethodChannel(
    'com.prospectusoft.daycounter');

  @override
  void initState(){
    super.initState();
    _sendReadyRequest();
    _initDb();
  }

    @override
  void dispose() {
    super.dispose();
  }

  Future<Null> _sendReadyRequest() async {
    await platform.invokeMethod('ready');
  }

  // Receiving info from widget
  void _widgetHandler() {
    HomeScreenWidgets homeScreenWidgets = const HomeScreenWidgets();
    homeScreenWidgets.initialize((String method, String arguments) {
      if (method == 'launch') {
        print('THIS IS A LAUNCHER METHOD');
        print(arguments);
        Navigator.push(context, MaterialPageRoute(builder:(context) => WidgetConfigScreen()));
      }
    });
  }

  // Initialize database
  void _initDb() async {
    counterDatabase.getDb().then((res) async{
      db = res;
      queryResult = await counterDatabase.getQuery(db);
      tileCount = (queryResult.length * 2) + 1;
      this.setState(() => queryResult);
    });
  }

  // Transfer user to Add Counter screen
  void _addCounter() async{
    Navigator.push(context, MaterialPageRoute(builder:
      (context) => AddCounterScreen())
    ).then((v) async {
      queryResult = await counterDatabase.getQuery(db);
      tileCount = (queryResult.length * 2) + 1;
      this.setState(() => queryResult);
    });
  }

  // Transfer user to Edit Counter screen
  void _editCounter(String name, String value, String last) {
    Navigator.push(context, MaterialPageRoute(builder:
      (context) => EditScreen(name: name, value: value, last: last))
    ).then((v) async {
      queryResult = await counterDatabase.getQuery(db);
      tileCount = (queryResult.length * 2) + 1;
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
        bgcolor: "#e74c3c",
        textcolor: '#ffffff'
      );

      // Update Screen
      queryResult = await counterDatabase.getQuery(db);
      tileCount = (queryResult.length * 2) + 1;
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
      key: _scaffoldKey,
      appBar: new AppBar(
        automaticallyImplyLeading: false,
        title: new Text("Day Counter", textAlign: TextAlign.center,),
        elevation: 4.0,
      ),
      backgroundColor: Colors.white.withOpacity(.97),
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
              icon: Icon(Icons.forum),
              color: Colors.white,
              highlightColor: Colors.green,
              onPressed:() {}
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
                  ListTile(
                    leading: new Icon(
                      Icons.settings,
                      color: Colors.black54,
                    ),
                    title: Text(
                      'Settings',
                      textAlign: TextAlign.left,
                      style: _drawerFont,
                    ), 
                    // TODO go to settings
                    //onTap: () => Navigator.pop(context);,
                  ),
                  Divider(),
                  ListTile(
                    leading: new Icon(
                      Icons.folder,
                      color: Colors.black54,
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
    // Dismiossable so we can swipe it left to delete
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
      child: ListTile(
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
        onLongPress: () {
          // Send to Edit Screen
          _editCounter(name, value, last);
        },
        // Try to add days to this counter
        onTap: () => _incrementCounter(name, value, last)
      ),
    );
  }
}