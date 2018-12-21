import 'package:meta/meta.dart';

class Counter {
  static final dbName = "name";
  static final dbValue = "value";
  static final dbInitial = "initial";
  static final dbLast = "last";

  String name, value, initial, last;

  Counter({
    @required this.name,
    @required this.value,
    @required this.initial,
    @required this.last
  });

  Counter.fromMap(Map<String, dynamic> map): this(
    name: map[dbName],
    value: map[dbValue],
    initial: map[dbInitial],
    last: map[dbLast]
  );

  // Currently not used
  static Map<String, dynamic> toMap(map) => {
    dbName: map.name,
    dbValue: map.value,
    dbInitial: map.initial,
    dbLast: map.last
  };
}