import 'dart:ui';
import 'dart:io';

import 'settings_screen.dart';
import 'view_flags_screen.dart';
import 'add_counter_screen.dart';
import 'edit_screen.dart';
import 'view_more.dart';
import 'terms.dart';
import 'credits.dart';
import 'guide_screen.dart';

// Utils
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:pin_code_view/pin_code_view.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'utils/algorithms.dart';
import 'utils/common_funcs.dart';
import 'package:flutter/services.dart';

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
      title: 'Animo',
      theme: new ThemeData(
        primarySwatch: Colors.green,
        canvasColor: Colors.white,
        accentColor: Colors.green,
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
  bool _firstTime = true;
  String pin;
  final storage = new FlutterSecureStorage();

  TextStyle _drawerFont;

  int tileCount = 0;
 
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  
  bool _countersLoaded = false;

  // TODO change settings in android manifest to allow backups

  @override
  void initState(){
    super.initState();
    SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp
    ]);
    WidgetsBinding.instance.addObserver(this);
    _checkFirstTime();
    _loadPin();
    common.setUpNotifications();
    _initDb();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    common.setUpNotifications();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  /// Checks if the user needs to go through the guide or not
  void _checkFirstTime() async{
    String boolString;
    boolString = await storage.read(key: "firstTime");
    
    // If there is no value stored in phone because it is first time.
    if (boolString == null) {
      await Navigator.push(context, MaterialPageRoute(builder:(context) => GuideScreen()));
      
      // Updating value meaning that the user went through the guide.
      storage.write(key: "firstTime", value: "false");
    }
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
    await counterDatabase.getDb().then((res) async{
      db = res;
      queryResult = await counterDatabase.getQuery(db);
      tileCount = queryResult.length;
      await _getData();
      _countersLoaded = true;
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
      await _updateCounters();
    });
  }
  
  /// Transfer user to Edit Counter screen
  void _editCounter(String name, String value, String initial, String last, bool f, bool s) {
    Navigator.push(context, MaterialPageRoute(builder:
      (context) => EditScreen(name: name, value: value, initial: initial, last: last, f: f, s: s))
    ).then((v) async {
      await _updateCounters();
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
  
  
  void _showBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Container(
              child: new Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  new ListTile(
                    title: Text(
                      'Animo',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 20.0,
                        letterSpacing: .8,
                        fontWeight: FontWeight.w600,
                        color: Colors.white
                      )
                    ),
                  )
                ]
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.teal,
                    Colors.green
                  ]
                )
              ),
            ),
            new Container(
              color: Colors.white,
              child: new Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  new ListTile(
                    leading: new Icon(
                      Icons.settings,
                      color: Colors.black.withOpacity(.75)
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
                  new ListTile(
                    leading: new Icon(
                      Icons.help,
                      color: Colors.black.withOpacity(.75)
                    ),
                    title: Text(
                      'Guide',
                      textAlign: TextAlign.left,
                      style: _drawerFont,
                    ), 
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder:(context) => GuideScreen()));
                    },
                  ),
                  /* new ListTile(
                    leading: new Icon(
                      Icons.monetization_on,
                      color:Colors.black.withOpacity(.75)
                    ),
                    title: Text(
                      'Donate',
                      textAlign: TextAlign.left,
                      style: _drawerFont,
                    ), 
                  ),
                  new ListTile(
                    leading: new Icon(
                      Icons.book,
                      color:Colors.black.withOpacity(.75)
                    ),
                    title: Text(
                      'Help and Q&A',
                      textAlign: TextAlign.left,
                      style: _drawerFont,
                    ), 
                  ),*/
                  new ListTile(
                    leading: new Icon(
                      Icons.info,
                      color:Colors.black.withOpacity(.75)
                    ),
                    title: Text(
                      'Credits',
                      textAlign: TextAlign.left,
                      style: _drawerFont,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder:(context) => CreditsScreen()));
                    },
                  ),
                  new ListTile(
                    leading: new Icon(
                      Icons.folder,
                      color:Colors.black.withOpacity(.75)
                    ),
                    title: Text(
                      'Terms and Conditions',
                      textAlign: TextAlign.left,
                      style: _drawerFont,
                    ), 
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder:(context) => TermsScreen()));
                    },
                  ),
                ]
              ),
            ),
          ],
        );
    });
  }
  
  /// Transfers user to the ViewMore Ssreen
  void _showViewMore(String name) async {
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
    _drawerFont = TextStyle(
      fontSize: 15.0,
      letterSpacing: .8,
      fontWeight: FontWeight.w600,
      color: Colors.black.withOpacity(.75)
    );
    
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
          keyTextStyle: TextStyle(
            fontSize: 30,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
            color: Colors.white
          ),
          obscurePin: true,
          codeLength: 4,
          onCodeEntered: (code) {
            //callback after full code has been entered
            if (code.toString() == pin) { //PIN has been successfully entered
              setState(() {secured = false;});
            }
          },
        ),
      );
    }
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: (Platform.isAndroid) ? Colors.white.withAlpha(240) : Colors.white.withAlpha(240),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              color: Colors.black.withOpacity(.75),
              tooltip: 'Open drawer',
              icon: Icon(Icons.menu),
              onPressed: () {
                _showBottomSheet();
              },
            ),
            (tileCount != 0)
            ? IconButton(
              color: Colors.black.withOpacity(.75),
              tooltip: 'Increment all counters',
              icon: Icon(Icons.update),
              onPressed:() {
                final snackBar = SnackBar(
                  content: Text(
                    'Trying to increment all counters'
                  ),
                  duration: Duration(
                    seconds: 2
                  ),
                );
                _scaffoldKey.currentState.showSnackBar(snackBar);
                _incrementAll();
              },
            )
            : SizedBox()
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton.extended(
        elevation: (Platform.isAndroid) ? 4 : 0,
        tooltip: 'Add new counter to the screen',
        icon: new Icon(
          Icons.add,
        ),
        onPressed: _addCounter,
        label: Text(
          "Add counter",
          style: TextStyle(
            fontSize: 16.0,
            letterSpacing: .8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              title: new Text(
                "Animo",
                style: TextStyle(
                  letterSpacing: .7,
                  fontWeight: FontWeight.w600,
                  color: Colors.white
                ),
              ),
              elevation: (Platform.isAndroid) ? 4 : 0,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                centerTitle: true,
              ),
            ),
          ];
        },
        body: RefreshIndicator( // When the user drags to refresh all counters
          child: _buildCounters(),
          onRefresh: () {
            final snackBar = SnackBar(
              content: Text(
                'Trying to increment all counters'
              ),
              duration: Duration(
                seconds: 2
              ),
            );
            _scaffoldKey.currentState.showSnackBar(snackBar);
            return _incrementAll();
          }
        ),
      )
    );
  }

  Widget _buildCounters() {
    // If the counters are being loaded still
    if (!_countersLoaded) {
      return Center (
        child: CircularProgressIndicator(),
      );
    }
    if (tileCount == 0) {
      return Center (
        child: Text(
          "ADD A COUNTER TO GET STARTED",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            letterSpacing: .8,
            fontWeight: FontWeight.w700,
            color: Colors.green
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: tileCount,
      // Getting values from query of counters in database
      itemBuilder: (context, i){
        if (queryResult != null && queryResult.length> 0 && i < queryResult.length){
          var row = queryResult[i];
          
          // Converting the setting switches from integers to booleans
          bool f = (row['fSwitch'] == 1) ? true : false;
          bool s = (row['sSwitch'] == 1) ? true : false;
          
          return _buildCard(i, row['name'], row['value'], row['initial'], row['last'], f, s);
        }
        return null;
      }
    );
  }
  
  Widget _buildCard(int i, String name, String value, String initial, String last, bool f, bool s) {
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
    
    return Card(
      color: (Platform.isAndroid) ? Colors.white : Colors.white,
      elevation: (Platform.isAndroid) ? 1 : 0,
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
                    fontSize: 34.0,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue
                  )
                ),
                subtitle: new Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.0,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(.75)
                  )
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.fromLTRB(0, 16, 4, 8),
                trailing: PopupMenuButton(
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
                      case 'edit': _editCounter(name, value, initial, last, f, s); break;
                      case 'delete': {
                        common.showDeleteDialog(context, db, name).then((v) {
                          if (v)
                            _updateCounters(); 
                        });
                        break;
                      }
                    }
                  }),
              )
            ],
          ),
          
          // ------------------------------ Line Chart ----------------------------------------------
          (f)
          ? Container(
            color: Colors.black.withAlpha(5),
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
          )
          : SizedBox(),
          
          
          // -------------------------------- Schedule -----------------------------------------
          //TODO
          (s)
          ? ListTile(
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
          )
          : SizedBox(),
            
          // --------------------------------- Action buttons in the card --------------------------
          ButtonTheme.bar(
            alignedDropdown: true,
            child: ListTile(
              leading: (f || s)
              ? (Platform.isAndroid)
                ? FlatButton(
                  child: const Text(
                    'VIEW MORE',
                    style: TextStyle(
                      fontSize: 14.0,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                      color: Colors.green
                    )
                  ),
                  onPressed: () { 
                    _showViewMore(name);
                  },
                )
                : CupertinoButton (
                  child: const Text(
                    'VIEW MORE',
                    style: TextStyle(
                      fontSize: 14.0,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                      color: Colors.green
                    )
                  ),
                  onPressed: () {
                    _showViewMore(name);
                  },
                )
              : Text(
                "Keep going!",
                style: TextStyle(
                  fontSize: 14.0,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                  color: Colors.green
                )
              ),
              trailing: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  (f)
                  ? IconButton(
                    icon: Icon(
                      Icons.outlined_flag,
                      color: Colors.red
                    ),
                    iconSize: 30,
                    onPressed: () {
                      (value != "0") 
                      ? showDatePicker(
                        initialDate: new DateTime.now(),
                        firstDate: new DateTime.fromMillisecondsSinceEpoch(int.parse(initial)).add(new Duration(days: 1)),
                        lastDate: new DateTime.now(),
                        context: context,
                      ).then((v) async {
                        if (v != null) {
                           await common.addRedFlagToDb(v, name, initial);
                          _getData();
                        }
                      }) 
                      : Fluttertoast.showToast(
                        msg: "You need at least one day",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIos: 2,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                    },
                  )
                  : SizedBox(),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: Colors.blue
                    ),
                    iconSize: 30,
                    onPressed: () async {
                      final snackBar = SnackBar(
                        content: Text(
                          'Trying to increment $name'
                        ),
                        duration: Duration(
                          seconds: 2
                        ),
                      );
                      _scaffoldKey.currentState.showSnackBar(snackBar);
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