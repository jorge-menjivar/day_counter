import 'dart:ui';

import 'view_flags_screen.dart';
import 'edit_screen.dart';
import 'utils/common_funcs.dart';


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
  MoreScreen({
    @required this.name
  });

  @override
  createState() => MoreState(pName: name);
}

class MoreState extends State<MoreScreen> with WidgetsBindingObserver{
  String pName;
  String pValue = "";
  String pInitial = "";
  String pLast = "";
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
  CommonFunctions common = CommonFunctions();
  
  var dataList = List<ProgressByDate>();
  
  


  @override
  void initState(){
    super.initState();
    _initDb();
  }
  
  @override
  void dispose() {
    db.close();
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
  
  /// Updates all the values of the current counter
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
      res.close();
    });
    setState(() {});
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
                common.deleteCounter(db, pName);
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
                        ).then((v) async {
                          common.addRedFlagToDb(v, pName, pValue);
                          _updateCounter();
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
                        await common.incrementCounter(db, pName, pValue, pLast);
                        _updateCounter();
                      }
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