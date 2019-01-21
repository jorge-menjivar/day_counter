import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'schedules_model.dart';


class SchedulesDatabase {
  
  //ADD ANOTHER FIELD TO THIS COUNTER

  /// Initialize this database and return it
  Future<Database> getDb(String id) async {
    assert (id != null && id != "");
    // Get a location using path_provider
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, '${id}Schedule');
    return await openDatabase(path, version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
            "CREATE TABLE Schedules ("
                "${Schedules.dbDay} INTEGER PRIMARY KEY, " 
                "${Schedules.dbFlag} INTEGER, "
                "${Schedules.dbAmount} INTEGER, "
                "${Schedules.dbTime} INTEGER "
                ")");
      });
  }

  /// Add new row to database
  Future <int> addToDb(Database db, int day bool flagBool, int amount, int time) async{
    int flag;
    (flagBool) ? flag = 1 : flag = 0;
    return await db.rawInsert(
          'INSERT INTO '
              'Schedules (${Schedules.dbDay}, ${Schedules.dbFlag}, ${Schedules.dbAmount}, ${Schedules.dbTime})'
              'VALUES ("$day", "$flag", "$amount", "$time")');
  }

  /// Get map of the desired searched item
  Future<List<Map>> getDayQuery(Database db, int day) async{
    var result = await db.rawQuery('SELECT * FROM Schedules WHERE ${Schedules.dbDay} = "$day"');
    return result;
  }

  /// Delete requested day
  Future<int> deleteDay(Database db, int day) async{
    return db.rawDelete('DELETE FROM Schedules WHERE ${Schedules.dbDay} = "$day"');
  }
  
  /// Delete requested day which matches time
  Future<int> deleteByDay(Database db, int time) async{
    return db.rawDelete('DELETE FROM Schedules WHERE ${Schedules.dbTime} = "$time"');
  }
  
  /// Delete all rows
  Future<int> deleteAll(Database db) async{
    return db.rawDelete('DELETE FROM Schedules');
  }

  /// Get query of all the rows in database
  Future getQuery(Database db) async {
    var query = await db.rawQuery('SELECT * FROM Schedules ORDER BY ${Schedules.dbDay} ASC');
    return query;
  }
  
  /// Get query of all the rows in database
  Future getQueryDesc(Database db) async {
    var query = await db.rawQuery('SELECT * FROM Schedules ORDER BY ${Schedules.dbDay} DESC');
    return query;
  }
  
  /// Deletes database of the given name
  Future<String> deleteDb(String id) async {
    assert (id != null && id != "");
    // Get a location using path_provider
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, '${id}Schedule');

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


  /// Renames the file name of the given database
  Future<void> renameDatabase(String id, String newId) async {
    assert (id != null && id != "");
    assert (newId != null && newId != "");

    // Get a location using path_provider
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, '${id}Schedule');

    // New directory for the file (new name)
    String newPath = join(documentsDirectory.path, '${newId}Schedule');

    // renaming
    var file = File(path);
    file.rename(newPath);

    return;
  }

}