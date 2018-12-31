import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'counter_model.dart';


class CounterDatabase {

  /// Initizalize this database and return it
  Future<Database> getDb() async {
    // Get a location using path_provider
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'Counters');
    return await openDatabase(path, version: 1,
      onCreate: (Database db, int version) async {
        // When creating the db, create the table
        await db.execute(
            "CREATE TABLE Counters ("
                "${Counter.dbName} TEXT PRIMARY KEY, "
                "${Counter.dbValue} TEXT, "
                "${Counter.dbInitial} TEXT, "
                "${Counter.dbLast} TEXT "
                ")");
      });
  }

  /// Add new row to databse
  Future <int> addToDb(Database db, String name, String value, String initial, String last) async{
    return await db.rawInsert(
          'INSERT INTO '
              'Counters(${Counter.dbName}, ${Counter.dbValue}, ${Counter.dbInitial}, ${Counter.dbLast})'
              ' VALUES("$name", "$value", "$initial", "$last")');
  }

  /// Update row in database
  Future<int> updateCounter(Database db, String name, String value, String last) async {
    return await db.rawUpdate('UPDATE Counters SET ${Counter.dbValue} = "$value", ${Counter.dbLast} = "$last" WHERE ${Counter.dbName} = "$name"');
  }

  /// Update the initial time for the row in database
  Future<int> updateCounterAndInitial(Database db, String name, String value, String initial, String last) async {
    return await db.rawUpdate('UPDATE Counters SET ${Counter.dbValue} = "$value", ${Counter.dbInitial} = "$initial", ${Counter.dbLast} = "$last" WHERE ${Counter.dbName} = "$name"');
  }

  /// Get map of the desired searched item
  Future<List<Map>> getCounterQuery(Database db, String name) async{
    var result = await db.rawQuery('SELECT * FROM Counters WHERE ${Counter.dbName} = "$name"');
    return result;
  }

  /// Delete requested counters
  Future<int> deleteCounter(Database db, String name) async{
    return db.rawDelete('DELETE FROM Counters WHERE ${Counter.dbName} = "$name"');
  }

  /// Get query of all the rows in database
  Future getQuery(Database db) async {
    var query = await db.rawQuery('SELECT * FROM Counters ORDER BY ${Counter.dbName} ASC');
    if (query.length == 0)print('No Counters');
    return query;
  }

  /// Deletes the database
  Future<String> deleteDb() async {
    // Get a location using path_provider
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'counters');

    // make sure the folder exists
    if (await Directory(dirname(path)).exists()) {
      await deleteDatabase(path);
    } else {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (e) {
        print(e);
      }
    }
    return path;
  }

}