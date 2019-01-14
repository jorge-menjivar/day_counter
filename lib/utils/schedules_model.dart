import 'package:meta/meta.dart';

class Schedules {
  static final dbDay = "day";
  static final dbFlag = "flag";
  static final dbAmount = "amount";
  static final dbTime = "time";

  int day, flag, amount, time;

  Schedules({
    @required this.day,
    @required this.flag,
    @required this.amount,
    @required this.time,
  });

  Schedules.fromMap(Map<String, dynamic> map): this(
    day: map[dbDay],
    flag: map[dbFlag],
    amount: map[dbAmount],
    time: map[dbTime],
  );

  // Currently not used
  static Map<String, dynamic> toMap(map) => {
    dbDay: map.day,
    dbFlag: map.flag,
    dbAmount: map.amount,
    dbTime: map.time,
  };
}