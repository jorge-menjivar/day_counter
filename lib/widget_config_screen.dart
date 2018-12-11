import 'dart:async';

import 'package:flutter/material.dart';

// Utils
import 'package:fluttertoast/fluttertoast.dart';



class WidgetConfigScreen extends StatefulWidget {
  WidgetConfigScreen();

  @override
  createState() => ConfigState();
}

class ConfigState extends State<WidgetConfigScreen> {
  ConfigState();

  final TextEditingController _controllerName = new TextEditingController();
  final TextEditingController _controllerValue = new TextEditingController();
  final _nameFieldKey = GlobalKey<FormFieldState>();
  final _valueFieldKey = GlobalKey<FormFieldState>();


  @override
  void initState(){
    super.initState();
    _controllerName.text = "Widget";
    _controllerValue.text = "0";
  }

    @override
  void dispose() {
    super.dispose();
  }

  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text("Set Up Widget"),
        elevation: 4.0,
      ),
      body: new Builder(
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.all(16.0),
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new TextFormField(
                  key: _nameFieldKey,
                  controller: _controllerName,
                  keyboardType: TextInputType.text,
                  autocorrect: false,
                  autofocus: true,
                  autovalidate: true,
                  decoration: new InputDecoration(
                    labelText: "Counter Name",
                  ),
                  validator: (text) {
                      if ( text.length < 1)
                        return 'Name must be at least 1 character long.';
                  }
                ),
                new SizedBox(
                  height: 32.0,
                ),
                new TextFormField(
                  key: _valueFieldKey,
                  controller: _controllerValue,
                  keyboardType: TextInputType.number,
                  autocorrect: false,
                  autofocus: true,
                  autovalidate: true,
                  decoration: new InputDecoration(
                    labelText: "Initial number of days",
                    ),
                  validator: (text) {
                    if (text.contains(new RegExp(r'\D')))
                      return 'Only numbers';
                  },
                ),
                new Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                  ],
                ),
                new SizedBox(
                  height: 48.0,
                ),
                new RaisedButton(
                  child: new Text("SAVE"),
                  onPressed: () {},
                ),
                new OutlineButton(
                  child: new Text("DELETE"),
                  onPressed: () {},
                )
              ],
            )
          );
        },
      )
    );
  }
}