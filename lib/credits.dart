import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// Utils
import 'package:url_launcher/url_launcher.dart';

class CreditsScreen extends StatefulWidget {
  
  CreditsScreen();

  @override
  createState() => CreditState();
}

class CreditState extends State<CreditsScreen> {
  CreditState();
  
  
  TextStyle _bodyStyle;
  TextStyle _headerStyle;
  
  @override
  void initState(){
    super.initState();
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
  
  
  Future<void> _openUrl() async{
    const url = 'https://play.google.com/store/apps/details?id=ar.teovogel.yip&hl';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text(
          "Credits",
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
          new ListTile(
            leading: new Text(
              "DEVELOPERS",
              style: _headerStyle,
            ),
          ),
          new ListTile(
            title: new Text(
              "Jorge Menjivar",
              style: _bodyStyle,
            ),
            subtitle: new Text(
              "Main Developer"
            ),
          ),
          SizedBox(height: 40),
          new ListTile(
            leading: new Text(
              "INSPIRATION",
              style: _headerStyle,
            ),
          ),
          new ListTile(
            leading: Icon(
              Icons.android,
              color: Colors.green,
            ),
            title: new Text(
              "Year in Pixels",
              style: TextStyle(
                fontSize: 16,
                letterSpacing: .7,
                fontWeight: FontWeight.w600,
                color: Colors.pink
              ),
            ),
            subtitle: new Text(
              "by Teo Vogel"
            ),
            onTap: () => _openUrl(),
          ),
          new ListTile(
            title: new Text(
              "Special thanks to Teo Vogel and all the people who contributed to the making of the app 'Year in Pixels'.\n"
              "The app inspired me to add features like daily reminders and a PIN to this app.",
              style: _bodyStyle,
            ),
          ),
        ],
      ),
    );
  }
}