import 'package:meta/meta.dart';

class Counter {
  static final dbName = "name";
  static final dbValue = "value";
  static final dbLast = "last";

  String name, value, last;

  bool starred;
  Counter({
    @required this.name,
    @required this.value,
    @required this.last
  });

  Counter.fromMap(Map<String, dynamic> map): this(
    name: map[dbName],
    value: map[dbValue],
    last: map[dbLast]
  );

  // Currently not used
  static Map<String, dynamic> toMap(map) => {
    dbName: map.name,
    dbValue: map.value,
    dbLast: map.last
  };
}