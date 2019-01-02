import 'package:meta/meta.dart';

class GapAverage {
  static final dbDate = "date";
  static final dbAverage = "average";

  String date;
  double average;

  GapAverage({
    @required this.date,
    @required this.average
  });

  GapAverage.fromMap(Map<String, dynamic> map): this(
    date: map[dbDate],
    average: map[dbAverage]
  );

  // Currently not used
  static Map<String, dynamic> toMap(map) => {
    dbDate: map.date,
    dbAverage: map.average
  };
}