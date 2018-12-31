import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class TermsScreen extends StatefulWidget {
  
  TermsScreen();
  
  @override
  createState() => TermsState();
}

class TermsState extends State<TermsScreen> {
  TermsState();
  
  
  String data;
  
  TextStyle _bodyStyle;
  TextStyle _headerStyle;
  
  @override
  void initState(){
    super.initState();
    _getFileData("assets/res/terms.txt");
    _headerStyle = TextStyle(
      fontSize: 14.0,
      letterSpacing: 1,
      fontWeight: FontWeight.w600,
      color: Colors.black54
    );
    
    _bodyStyle = TextStyle(
      fontSize: 16,
      letterSpacing: .7,
      fontWeight: FontWeight.w600,
      color: Colors.black.withOpacity(.75)
    );
  }

    @override
  void dispose() {
    super.dispose();
  }
  
  Future<void> _getFileData(String path) async {
    data = await rootBundle.loadString(path);
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text(
          "Terms and Conditions",
          textAlign: TextAlign.center,
          style: TextStyle(
            letterSpacing: .7,
            fontWeight: FontWeight.w600,
            color: Colors.white
          ),
        ),
        elevation: (Platform.isAndroid) ? 4 : 0,
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              data,
              style: _bodyStyle,
            ),
          )
        ],
      ),
    );
  }
}