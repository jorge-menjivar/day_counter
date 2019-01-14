import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'flags_model.dart';


class FlagsDatabase {
  
  //ADD ANOTHER FIELD TO THIS COUNTER

  /// Initialize this database and return it
  Future<Database> getDb(String id) async {
    assert (id != null && id != "");
    // Get a location using path_provider
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, '${id}Flags');
    return await openDatabase(path, version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
            "CREATE TABLE Flags ("
                "${Flags.dbDate} INTEGER PRIMARY KEY "
                ")");
      });
  }

  /// Add new row to databse
  Future <int> addToDb(Database db, int date) async{
    return await db.rawInsert(
          'INSERT INTO '
              'Flags(${Flags.dbDate})'
              ' VALUES("$date")');
  }

  /// Get map of the desired searched item
  Future<List<Map>> getFlagQuery(Database db, int date) async{
    var result = await db.rawQuery('SELECT * FROM Flags WHERE ${Flags.dbDate} = "$date"');
    return result;
  }

  /// Delete requested flag
  Future<int> deleteFlag(Database db, int date) async{
    return db.rawDelete('DELETE FROM Flags WHERE ${Flags.dbDate} = "$date"');
  }

  /// Get query of all the rows in database
  Future getQuery(Database db) async {
    var query = await db.rawQuery('SELECT * FROM Flags ORDER BY ${Flags.dbDate} ASC');
    return query;
  }
  
  /// Get query of all the rows in database
  Future getQueryDesc(Database db) async {
    var query = await db.rawQuery('SELECT * FROM Flags ORDER BY ${Flags.dbDate} DESC');
    return query;
  }
  
  /// Return a query with that begins at [start] and finishes at [end], and returns in descending if [desc] is true;
  Future getQueryRange(Database db, int start, int end, bool desc) async {
    var query;
    if (!desc) {
      query = await db.rawQuery('SELECT * FROM Flags WHERE ${Flags.dbDate} >= $start AND ${Flags.dbDate} <= $end');
    }
    else {
      query = await db.rawQuery('SELECT * FROM Flags WHERE ${Flags.dbDate} >= $start AND ${Flags.dbDate} <= $end '
      'ORDER BY ${Flags.dbDate} DESC');
    }
    return query;
  }

  /// Deletes database of the given name
  Future<String> deleteDb(String id) async {
    assert (id != null && id != "");
    // Get a location using path_provider
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, '${id}Flags');

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
    String path = join(documentsDirectory.path, '${id}Flags');

    // New directory for the file (new name)
    String newPath = join(documentsDirectory.path, '${newId}Flags');

    // renaming
    var file = File(path);
    file.rename(newPath);

    return;
  }

}