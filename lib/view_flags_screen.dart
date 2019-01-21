import 'dart:ui';
import 'dart:io';


// Utils
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// Storage
import 'package:sqflite/sqflite.dart';
import 'utils/flags_database.dart';


class FlagsScreen extends StatefulWidget {
  final String name;
  FlagsScreen({
    @required this.name
  });

  @override
  createState() => FlagsState(pName: name);
}

class FlagsState extends State<FlagsScreen> with WidgetsBindingObserver{
  final String pName;
  FlagsState({
    @required this.pName
  });
  
  var queryResult;
  Database db;
  FlagsDatabase flagsDatabase = FlagsDatabase();

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


  /// Initialize database
  void _initDb() async {
    flagsDatabase.getDb(pName).then((res) async{
      db = res;
      queryResult = await flagsDatabase.getAll(db);
      tileCount = (queryResult.length * 2) + 1;
      this.setState(() => queryResult);
    });
  }
  
  Future<void> _deleteFlag(int date) async{
    await flagsDatabase.deleteFlag(db, date).then((v) async {
      Fluttertoast.showToast(
        msg: "Flag deleted",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 2,
        backgroundColor: Colors.transparent,
        textColor: Colors.white,
      );
      queryResult = await flagsDatabase.getAll(db);
      tileCount = (queryResult.length * 2) + 1;
      setState(() => queryResult);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        key: _scaffoldKey,
        title: new Text(
          "Flags in $pName",
          textAlign: TextAlign.center,
          style: TextStyle(
            letterSpacing: .7,
            fontWeight: FontWeight.w600,
            color: Colors.white
          ),
        ),
        elevation: (Platform.isAndroid) ? 4 : 0,
      ),
      body: _buildCounterTitles(),
        
    );
  }

  Widget _buildCounterTitles() {
    return ListView.builder(
      itemCount: tileCount,

      // Getting values from query of counters in database
      itemBuilder: (context, i){
        if (i.isOdd) return Divider();
        int index = i ~/ 2;
        if (queryResult != null && queryResult.length> 0 && index < queryResult.length){
          var row = queryResult[index];

          var date = row['date'];
          bool cheat;
          
          var cheatInt = row['cheat'];
          
          cheatInt == 0 ? cheat = false : cheat = true;
          
          return _buildRow(date, cheat);
        }

        // If no flags yet
        if (queryResult.length == 0) {
          return ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            title: Text(
              "No flags... yet",
              textAlign: TextAlign.center,
            ),
          );
        }

        
        return null;
      }
    );
  }
  
  Widget _buildRow(int date, bool cheat) {
    
    var dateEpoch = DateTime.fromMillisecondsSinceEpoch(date);
    String month;
    switch (dateEpoch.month) {
      case 1: month = "January"; break;
      case 2: month = "February"; break;
      case 3: month = "March"; break;
      case 4: month = "April"; break;
      case 5: month = "May"; break;
      case 6: month = "June"; break;
      case 7: month = "July"; break;
      case 8: month = "August"; break;
      case 9: month = "September"; break;
      case 10: month = "October"; break;
      case 11: month = "November"; break;
      case 12: month = "December"; break;
    }
    String readableDate = "$month ${dateEpoch.day}, ${dateEpoch.year}";
    
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      leading: IconButton(
        icon: Icon(
          Icons.flag,
          color: cheat ? Colors.black : Colors.red,
        ),
        onPressed: () => _deleteFlag(date),
      ),
      title: Text(
        readableDate,
        textAlign: TextAlign.left,
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.delete_forever,
          color: Colors.red,
        ),
        onPressed: () => _deleteFlag(date),
      )
    );
  }
}