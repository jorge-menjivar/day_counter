import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'main.dart';

// Utils
import 'package:charts_flutter/flutter.dart' as charts;


class GuideScreen extends StatefulWidget {
  
  GuideScreen();

  @override
  createState() => GuideState();
}

class GuideState extends State<GuideScreen> {
  GuideState();
  
  
  TextStyle _bodyStyle;
  TextStyle _bodyStyleHighlighted;
  
  int _pageNumber = 1;
  final int end = 9;
  
  bool f = true;
  bool s = false;
  
  @override
  void initState(){
    super.initState();
    _bodyStyle = TextStyle(
      fontSize: 18,
      letterSpacing: .8,
      fontWeight: FontWeight.w600,
      color: Colors.black.withOpacity(.70)
    );
    _bodyStyleHighlighted = TextStyle(
      fontSize: 16,
      letterSpacing: .7,
      fontWeight: FontWeight.w700,
      color: Colors.green
    );
  }

    @override
  void dispose() {
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: (Platform.isAndroid) ? Colors.white.withAlpha(240) : Colors.white.withAlpha(240),
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        color: Colors.white,
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            (_pageNumber != 1) 
            ? Container (
              padding: EdgeInsets.fromLTRB(35, 0, 0, 0),
              child: IconButton(
                iconSize: 45,
                icon: Text(
                  "BACK",
                  style: TextStyle(
                    fontSize: 14.0,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                    color: Colors.green
                  )
                ),
                onPressed: () {
                  if (_pageNumber > 1) {
                    _pageNumber--;
                    setState(() {});
                  } 
                },
              ),
            )
            : SizedBox(),
            Container(
              padding: EdgeInsets.fromLTRB(0, 0, 35, 0),
              child: IconButton(
                iconSize: 45,
                icon: Text(
                  "NEXT",
                  style: TextStyle(
                    fontSize: 14.0,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                    color: Colors.green
                  )
                ),
                onPressed: () {
                  _pageNumber++;
                  
                  // Continue if end is not reached. Otherwise exit.
                  (_pageNumber == end)
                  ? Navigator.of(context).pop()
                  : setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "GUIDE",
          style: TextStyle(
            fontSize: 20,
            letterSpacing: .7,
            fontWeight: FontWeight.w600,
            color: Colors.white
          ),
        ),
        elevation: (Platform.isAndroid) ? 4 : 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        physics: ClampingScrollPhysics(),
        children: <Widget>[
          _buildInstructions(),
          // Ignoring any touch input on the display card
          IgnorePointer(
            child: _buildCard(),
            ignoring: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInstructions() {
    switch (_pageNumber) {
      case 1: {
        return Container (
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: <Widget>[
              Text(
                "\nWELCOME TO ANIMO\n",
                style: TextStyle(
                  fontSize: 19,
                  letterSpacing: .7,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                "Animo is made for the people.\n\n",
                style: _bodyStyle,
                textAlign: TextAlign.center,
              ),
              Text(
                "Animo is meant to help. You just have to be willing.\n\n",
                style: _bodyStyle,
                textAlign: TextAlign.center,
              ),
              Text(
                "Animo has no ads. "
                "Any money made through donations will be used to bring Animo to more people.\n\n",
                style: _bodyStyle,
                textAlign: TextAlign.center,
              ),
              Divider(),
              Text(
                "Please take a moment to go through this guide. It will help you understand how Animo works.\n",
                style: _bodyStyleHighlighted,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      case 2: {
        return Container (
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Text(
            "This is a counter card.\n\n"
            "It shows the most necessary information.",
            style: _bodyStyle,
            textAlign: TextAlign.center,
          ),
        );
      }
      case 3: {
        return Container (
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Text(
            "In this card, the name of the counter is 'No Pizza 🍕' and it has 35 days",
            style: _bodyStyle,
            textAlign: TextAlign.center,
          ),
        );
      }
      case 4: {
        return Container (
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: <Widget>[
              Text(
                "The Add Days Button:\n",
                style: _bodyStyle,
                textAlign: TextAlign.center,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
              Text(
                "\nWhen pressed, Animo will try to add the days since the last time you updated the counter.\n",
                style: _bodyStyle,
                textAlign: TextAlign.center,
              ),
              Divider(),
              Text(
                "A day is always counted by date. That means you can add a new day after midnight.",
                style: _bodyStyleHighlighted,
                textAlign: TextAlign.center,
              ),
            ],
          )
        ); 
      }
      case 5: {
        return Container (
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: <Widget>[
              Text(
                "The Red Flag Button: \n",
                style: _bodyStyle,
                textAlign: TextAlign.center,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                child: Icon(
                  Icons.outlined_flag,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              Text(
                "\nPressing it will let you add a Red Flag to any day that you did not accomplish your goal.\n",
                style: _bodyStyle,
                textAlign: TextAlign.center,
              ),
              Divider(),
              Text(
                "It is up to you to define what merits a Red Flag.\n"
                "It could be taking a bite of the pizza or eating the whole slice.",
                style: _bodyStyleHighlighted,
                textAlign: TextAlign.center,
              ),
            ],
          )
        );
      }
      case 6: {
        return Container (
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: <Widget>[
              Text(
                "The chart helps you keep track of your progress.\n",
                style: _bodyStyle,
                textAlign: TextAlign.center,
              ),
              Text(
                "The blue line represents consecutive days of achieving your goal.",
                style: _bodyStyle,
                textAlign: TextAlign.center,
              ),
            ],
          )
        );
      }
      case 7: {
        return Container (
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: <Widget>[
              Text(
                "The red line represents the days you missed your goal.\n",
                style: _bodyStyle,
                textAlign: TextAlign.center,
              ),
              Divider(),
              Text(
                "The chart penalizes you heavily if you miss your goals often.",
                style: _bodyStyleHighlighted,
                textAlign: TextAlign.center,
              ),
            ],
          )
        );
      }
      case 8: {
        return Container (
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: <Widget>[
              Text(
                "That's it!\n\n"
                "Now you know the basics of Animo!\n",
                style: _bodyStyle,
                textAlign: TextAlign.center,
              ),
              Divider(),
              Text(
                "You can come back to this guide at any time.",
                style: _bodyStyleHighlighted,
                textAlign: TextAlign.center,
              ),
            ],
          )
        );
      }
    }
    return null;
  }
  
  Widget _buildCard() {
    // In case flags have not been loaded yet
    
    var data = [
        new ProgressByDate(day: 1, progress: 1, color: Colors.blue),
        new ProgressByDate(day: 5, progress: 5, color: Colors.red),
        new ProgressByDate(day: 6, progress: 4, color: Colors.blue),
        new ProgressByDate(day: 24, progress: 22, color: Colors.red),
        new ProgressByDate(day: 25, progress: 18, color: Colors.blue),
        new ProgressByDate(day: 35, progress: 28, color: Colors.blue),
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
    
    return (_pageNumber != 1) 
    ? Card (
      color: (Platform.isAndroid) ? Colors.white : Colors.white,
      elevation: (Platform.isAndroid) ? 1 : 0,
      margin: const EdgeInsets.fromLTRB(30, 15, 30, 15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // ----------------------------- Title of card --------------------------------
          Container(
            child: Stack(
              children: <Widget>[ 
                ListTile (
                  contentPadding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                  title: Text(
                    "35",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34.0,
                      letterSpacing: .8,
                      fontWeight: FontWeight.w600,
                      color: (_pageNumber == 2 || _pageNumber == 3 || _pageNumber == 8) ? Colors.blue
                      : Colors.black.withAlpha(20)
                    )
                  ),
                  subtitle: new Text(
                    "No Pizza 🍕",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.0,
                      letterSpacing: .8,
                      fontWeight: FontWeight.w600,
                      color: (_pageNumber == 2 || _pageNumber == 3 || _pageNumber == 8) ? Colors.black.withOpacity(.75) 
                      : Colors.black.withAlpha(20)
                    )
                  ),
                )
              ],
            ),
          ),
          
          // ------------------------------ Line Chart ----------------------------------------------
          (f && _pageNumber == 2 || _pageNumber == 6 || _pageNumber == 7 || _pageNumber == 8)
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
          : SizedBox(
              height: 120,
              child: Container(
                color: Colors.black.withAlpha(5),
              ),
            ),
          
          
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
              leading: (Platform.isAndroid)
              ? FlatButton(
                child: Text(
                  'VIEW MORE',
                  style: TextStyle(
                    fontSize: 14.0,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                    color: (_pageNumber == 2 || _pageNumber == 8) ? Colors.green 
                    : Colors.black.withAlpha(20)
                  )
                ),
                onPressed: () {},
              )
              : CupertinoButton (
                child: Text(
                  'VIEW MORE',
                  style: TextStyle(
                    fontSize: 14.0,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                    color: (_pageNumber == 2 || _pageNumber == 8) ? Colors.green 
                    : Colors.black.withAlpha(20)
                  )
                ),
                onPressed: () {},
              ),
              trailing: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  (f)
                  ? IconButton(
                    icon: Icon(
                      Icons.outlined_flag,
                      color: (_pageNumber == 2 || _pageNumber == 5 || _pageNumber == 8) ? Colors.red 
                      : Colors.black.withAlpha(20)
                    ),
                    iconSize: 30,
                    onPressed: () {},
                  )
                  : SizedBox(),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: (_pageNumber == 2 || _pageNumber == 4 || _pageNumber == 8) ? Colors.blue 
                      : Colors.black.withAlpha(20)
                    ),
                    iconSize: 30,
                    onPressed: () async {}
                  ),
                ]
              ),
            ),
          ),
        ]
      )
    )
    : SizedBox();
  }
}