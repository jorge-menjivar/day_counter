import 'package:meta/meta.dart';

class Counter {
  static final dbName = "name";
  static final dbValue = "value";
  static final dbInitial = "initial";
  static final dbLast = "last";
  static final dbFSwitch = "fSwitch";
  static final dbSSwitch = 'sSwitch';

  String name;
  int value, initial, last, fSwitch, sSwitch;

  Counter({
    @required this.name,
    @required this.value,
    @required this.initial,
    @required this.last,
    @required this.fSwitch,
    @required this.sSwitch
  });

  Counter.fromMap(Map<String, dynamic> map): this(
    name: map[dbName],
    value: map[dbValue],
    initial: map[dbInitial],
    last: map[dbLast],
    fSwitch: map[dbFSwitch],
    sSwitch: map[dbSSwitch]
  );

  // Currently not used
  static Map<String, dynamic> toMap(map) => {
    dbName: map.name,
    dbValue: map.value,
    dbInitial: map.initial,
    dbLast: map.last,
    dbFSwitch: map.fSwitch,
    dbSSwitch: map.sSwitch
  };
}