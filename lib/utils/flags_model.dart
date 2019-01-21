import 'package:meta/meta.dart';

class Flags {
  static final dbDate = "date";
  static final dbCheat = "cheat";
  
  int date;
  int cheat;
  
  Flags({
    @required this.date,
    @required this.cheat,
  });
  
  Flags.fromMap(Map<String, dynamic> map): this(
    date: map[dbDate],
    cheat: map[dbCheat],
  );
  
  // Currently not used
  static Map<String, dynamic> toMap(map) => {
    dbDate: map.date,
    dbCheat: map.cheat,
  };
}