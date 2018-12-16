import 'dart:async';

import 'package:flutter/material.dart';

// Storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Utils
import 'package:pin_code_view/pin_code_view.dart';



class SettingsScreen extends StatefulWidget {
  SettingsScreen();

  @override
  createState() => SettingsState();
}

class SettingsState extends State<SettingsScreen> with WidgetsBindingObserver{
  SettingsState();
  
  // Setting variables
  TimeOfDay reminderTime;
  TimeOfDay defaultTime = new TimeOfDay(
    hour: 20,
    minute: 00,
  );
  bool reminder = true;
  bool secured = false;

  TextStyle _settingTextStyle;
  TextStyle _settingHeaderStyle;
  
  int tileCount = 0;

  // Used to store settings.
  final storage = new FlutterSecureStorage();

  @override
  void initState(){
    super.initState();
    setTextStyles();
    loadAll();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void setTextStyles() {
    _settingTextStyle = TextStyle(
      fontSize: 17.0,
      color: Colors.black87,
      fontWeight: FontWeight.w700,
    );

    _settingHeaderStyle = TextStyle(
      fontSize: 15.0,
      color: Colors.black45,
      fontWeight: FontWeight.w500,
    );
  }

  /// Reads all values from the secure storage and loads it into the local variables.
  Future <void> loadAll() async {

    // Reading the saved time for daily reminder.
    String timeString = await storage.read(key: "reminderTime");
    if (timeString != null) {
      reminderTime = TimeOfDay(
        hour: int.parse(timeString.split(":")[0]),
        minute: int.parse(timeString.split(":")[1]),
      );
    }

    // Reading the switch for REMINDER
    String reminderString = await storage.read(key: "reminder");
    reminderString == 'false' ? reminder = false : reminder = true;

    // Reading if there is a pin set
    String pin = await storage.read(key: "pin");
    if (pin != null && pin != "") {
      secured = true;
    }

    // Updating screen
    setState(() {});
  }

  /// Sets the value from the [TimePicker] to the local variables and also saves it to device.
  Future <void> _setReminderTime(TimeOfDay time) async {
    if (time == null){
      return;
    }
    print(time.toString());
    reminderTime = time;
    String parsedString = time.hour.toString() + ":" + time.minute.toString();
    // Write value 
    await storage.write(key: "reminderTime", value: parsedString);
    setState(() {});
  }


  /// Toggles the value of reminder switch and update saved settings.
  Future <void> _setReminderSwitch(bool v) async {
    // Toggle
    reminder = v;

    // Write value 
    await storage.write(key: "reminder", value: reminder.toString());
  }

  /// Brings up the dialog box to create a pin
  Future <void> _createPin(bool v) async {
    // If activating
    if (v) {
      String pin;
      showDialog<void>(
        context: context,
        barrierDismissible: true, // user can type outside box to dismiss
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Before you start!'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Make sure to write or remember this code.'),
                  Text('If you forget it, all your data will be lost.'),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  setState(() {secured = false;});
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Accept'),
                onPressed: () {
                  showDialog<void>(
                    context:  context,
                    barrierDismissible: false, // user must tap button!
                    builder: (BuildContext context) {
                      return Scaffold(
                        body: PinCode(
                          title: Text(
                            "Create Pin",
                            style: TextStyle(
                                color: Colors.white, fontSize: 25.0, fontWeight: FontWeight.bold),
                          ),
                          subTitle: Text(
                            "Make sure to write it somewhere",
                            style: TextStyle(color: Colors.white),
                          ),
                          obscurePin: false,
                          codeLength: 4,
                          onCodeEntered: (code) {
                            //callback after full code has been entered
                            _setPin(code.toString());
                            setState(() {secured = true;});
                            // Dismiss later dialog box
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    }
                  ).then((v) {
                    // Dismiss former dialog box
                    Navigator.of(context).pop();
                  });
                },
              ),
            ],
          );
        },
      );
    }
    else {
      _setPin("");
      setState(() {secured = false;});
    }
  }

  /// Saves the pin string to the secured storage
  Future _setPin(String p) async {
      // Write value
      await storage.write(key: "pin", value: p); // "" if no pin
  }


  String _readableTimeString(TimeOfDay t) {
    bool pm = false;
    int hourInt = t.hour;
    if (hourInt > 12) {
      hourInt = hourInt - 12;
      pm = true;
    }
    String hour = hourInt.toString();

    String minute = t.minute.toString();
    if (minute.length == 1) {
      minute = "0" + minute;
    }

    // If afternoon add pm else am
    String dn;
    pm ? dn = "PM" : dn = "AM";

    return hour + ":" + minute + " " + dn;
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text("Settings", textAlign: TextAlign.center,),
        elevation: 4.0,
      ),
      backgroundColor: Colors.white.withOpacity(.97),
      body: new Builder(
        builder: (BuildContext context) {
          return Container(
            child: _buildSettings(),
          );
        },
      )
    );
  }


  Widget _buildSettings() {
    return ListView(
      children: <Widget>[
        new Container(
          padding: EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // ------------------------------REMINDERS------------------------------
              new ListTile(
                leading: new Text(
                  "REMINDER",
                  style: _settingHeaderStyle,
                ),
              ),
              new ListTile(
                leading: Icon(
                  Icons.access_time,
                  color: Colors.black87,
                ),
                title: new Text(
                  "Daily reminder",
                  style: _settingTextStyle,
                ),
                trailing: Switch(
                  value: reminder,
                  onChanged: ((v) {
                    _setReminderSwitch(v);
                    setState(() {});
                  }),
                ),
              ),
              new ListTile(
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new Text(
                      (reminderTime != null) ? _readableTimeString(reminderTime) : _readableTimeString(defaultTime),
                      style: TextStyle(
                        // If switch is on display enabled
                        color: reminder ? Colors.black87 : Colors.black45,
                        fontSize: 43,
                        fontWeight: FontWeight.w400,
                      )
                    ),
                  ],
                ),
                onTap: () => showTimePicker(
                  initialTime: reminderTime != null ? reminderTime : defaultTime,
                  context: context,
                ).then((v) async => await _setReminderTime(v)),
              ),
              new Divider(),

              // ---------------------------PIN-------------------------------
              new ListTile(
                leading: new Text(
                  "PIN",
                  style: _settingHeaderStyle,
                ),
              ),
              new ListTile(
                leading: Icon(
                  Icons.security,
                  color: Colors.black87,
                ),
                title: new Text(
                  "Secure with PIN",
                  style: _settingTextStyle,
                ),
                trailing: new Switch(
                  value: secured,
                  onChanged: ((v) {
                    //TODO make sure pin works
                    _createPin(v);
                    setState(() {});
                  }),
                ),
              ),
              new Divider(),

              // --------------------------BACKUPS--------------------------
              new ListTile(
                leading: new Text(
                  "BACKUP",
                  style: _settingHeaderStyle,
                ),
              ),
              new ListTile(
                leading: Icon(
                  Icons.cloud_upload,
                  color: Colors.black87,
                ),
                title: new Text(
                  "Backup to the cloud",
                  style: _settingTextStyle,
                ),
                subtitle: new Text(
                  "Last Backup: Never"
                  // TODO get last time the user back up data
                ),
              ),
              new ListTile(
                leading: Icon(
                  Icons.file_download,
                  color: Colors.black87,
                ),
                title: new Text(
                  "Export to offline file",
                  style: _settingTextStyle,
                ),
              ),
              new ListTile(
                leading: Icon(
                  Icons.file_upload,
                  color: Colors.black87,
                ),
                title: new Text(
                  "Import from offline file",
                  style: _settingTextStyle,
                ),
              ),
            ],
          )
        ),
      ]
    );
  }
}