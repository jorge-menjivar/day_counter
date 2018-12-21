import 'dart:ui';

import 'view_flags_screen.dart';
import 'edit_screen.dart';


// Utils
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'utils/algorithms.dart';
import 'package:day_counter/main.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'utils/counter_database.dart';


// Storage
import 'package:sqflite/sqflite.dart';
import 'utils/flags_database.dart';


class MoreScreen extends StatefulWidget {
  final String name;
  final String value;
  final String initial;
  final String last;
  MoreScreen({
    @required this.name,
    @required this.value,
    @required this.initial,
    @required this.last
  });

  @override
  createState() => MoreState(pName: name);
}

class MoreState extends State<MoreScreen> with WidgetsBindingObserver{
  String pName;
  String pValue;
  String pInitial;
  String pLast;
  MoreState({
    @required this.pName,
  });

  var queryResult;
  Database db;
  CounterDatabase counterDatabase = new CounterDatabase();
  FlagsDatabase flagsDatabase = FlagsDatabase();

  int tileCount = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  
  Algorithms _algorithms = Algorithms();
  
  var dataList = List<ProgressByDate>();
  
  


  @override
  void initState(){
    super.initState();
    _initDb();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  
  /// Initialize database
  void _initDb() async {
    counterDatabase.getDb().then((res) async{
      db = res;
      queryResult = await counterDatabase.getCounterQuery(db, pName).then((v) {
        if(v.length == 0){
          Navigator.pop(context);
        }
        var row = v[0];
        pName = row['name'];
        pValue = row['value'];
        pInitial = row['initial'];
        pLast = row['last'];
        
      });
      await _getData();
      setState(() => queryResult);
    });
  }
  
  /// Update Counter
  Future<void> _updateCounter() async {
    queryResult = await counterDatabase.getCounterQuery(db, pName).then((v) {
      if(v.length == 0){
        Navigator.pop(context);
      }
      var row = v[0];
      pName = row['name'];
      pValue = row['value'];
      pInitial = row['initial'];
      pLast = row['last'];
      
    });
    await _getData();
    setState(() => queryResult);
  }


  /// Gets Chart Data
  Future<void> _getData() async {
    await flagsDatabase.getDb(pName).then((res) async {
      await flagsDatabase.getQuery(res).then((queryR) async {
        
        // Algorithm
        dataList = _algorithms.getDataList(queryR, pInitial);
        
      });
    });
    setState(() {});
  }
  
  
  Future<void> _addRedFlagToDb (DateTime dateTime) async{
    assert (dateTime != null);
    
    // The initial date of the counter
    DateTime initDate = DateTime.fromMillisecondsSinceEpoch(int.parse(pInitial));

    // The date passed from the date picker
    String date = dateTime.millisecondsSinceEpoch.toString();

    // Setting the millisecondsSinceEpoch to the beginning of the day of today.
    var today = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day
    );

    // Setting the millisecondsSinceEpoch to the beginning of the day if the flag is for today.
    if (DateTime.now().difference(dateTime).inDays == 0) {
      var d = DateTime(
        dateTime.year, dateTime.month, dateTime.day
      );
      date = d.millisecondsSinceEpoch.toString();
    }

    int initDif = today.difference(initDate).inDays;
    int curDif = today.difference(dateTime).inDays;

    // Making sure the flag date is after initial date and before today's date
    if (curDif >= 0 && curDif < initDif) {

      // Making sure flag does not already exists
      await flagsDatabase.getDb(pName).then((db) async {
        await flagsDatabase.getFlagQuery(db, date).then((q) async {
          if (q.length == 0){
            await flagsDatabase.addToDb(db, date).then((v) {
              _getData();
            });
          }

          else {
            Fluttertoast.showToast(
              msg: "Flag already exists",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIos: 2,
              backgroundColor: Colors.transparent,
              textColor: Colors.white,
            );
          }
        });
      });
    }
    return;
  }
  
  /// Navigate to View Flags screen and update widgets once it pops
  Future<void> _showFlags() async{
    await Navigator.push(context, MaterialPageRoute(builder: (context) => FlagsScreen(name: pName,)));
    _getData();
  }
  
  /// Transfer user to Edit Counter screen
  void _editCounter() {
    Navigator.push(context, MaterialPageRoute(builder:
      (context) => EditScreen(name: pName, value: pValue, initial: pInitial, last: pLast))
    ).then((v) async {
      _updateCounter();
    });
  }
  
  
  void _showDeleteDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true, // user can type outside box to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Do you really want to delete $pName ?'),
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
                Navigator.of(context).pop();
                _deleteCounter(pName);
                Navigator.of(context).pop();
              },
            ),
          ]
        );
      }
    );
  }
  
  
  
  /// Delete this counter from the database
  void _deleteCounter(String name) async{
    counterDatabase.deleteCounter(db, name).then((v) async {
      await flagsDatabase.deleteDb(name);

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
  
  
  
  /// Calculate if days should be added.
  Future<void> _incrementCounter() async{

    DateTime _last = DateTime.fromMillisecondsSinceEpoch(int.parse(pLast));
    int _counter = int.parse(pValue);
    var _today = DateTime.now();

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
    var todayEpoch = DateTime.now().millisecondsSinceEpoch;
    await counterDatabase.updateCounter(db, pName, _counter.toString(), todayEpoch.toString()).then((r) async {

      // Updating screen
      var result = await counterDatabase.getQuery(db);
      queryResult = result;
      _getData();
    });
  }

  @override
  Widget build(BuildContext context) {
    
    // In case flags have not been loaded yet
    var dataBackup;
    if (dataList.length == 0) {
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
        data: (dataList.length != 0) ? dataList : dataBackup,
      ),
    ];

    // The line chart used in the cards
    var chart = new charts.LineChart(
      series,
      animate: true,
    );
    
    
    return Scaffold(
      appBar: new AppBar(
        key: _scaffoldKey,
        title: new Text("$pName", textAlign: TextAlign.center),
        elevation: 4.0,
        actions: <Widget>[
          PopupMenuButton(
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
                  case 'red': _showFlags(); break;
                  case 'edit': _editCounter(); break;
                  case 'delete': _showDeleteDialog(); break;
                }
              }),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            // ------------------------------------------ Title of Card -------------------------------
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
              title: Text(
                pValue,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 40,
                  fontWeight: FontWeight.bold
                ),
              ),
              subtitle: new Text(
                pName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18
                ),
              ),
            ),
            
            
            // --------------------------------------Line Chart---------------------------------------------
            Container(
              color: Colors.black.withAlpha(15),
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, 8, 8, 8),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return new SizedBox(
                      height: 300.0,
                      width: constraints.maxWidth,
                      child: chart,
                    );
                  }
                )
              ) 
            ),
            
            //TODO
            (pName != " ") ? ListTile(
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
                        ).then((v) async => _addRedFlagToDb(v));
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add_circle,
                        color: Colors.blue
                      ),
                      iconSize: 35,
                      onPressed: () => _incrementCounter()
                    ),
                  ]
                ),
              ),
            ),
          ],
        ),
      )
    );
  }
}