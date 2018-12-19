import 'package:meta/meta.dart';

class Flags {
  static final dbDate = "date";

  String date;

  bool starred;
  Flags({
    @required this.date,
  });

  Flags.fromMap(Map<String, dynamic> map): this(
    date: map[dbDate],
  );

  // Currently not used
  static Map<String, dynamic> toMap(map) => {
    dbDate: map.date,
  };
}