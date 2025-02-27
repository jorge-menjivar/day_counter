import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'gap_average_model.dart';

class GapAverageDatabase {

  /// Initialize this database and return it
  Future<Database> getDb(String id) async {
    assert (id != null && id != "");
    // Get a location using path_provider
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, '${id}GA');
    return await openDatabase(path, version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
            "CREATE TABLE GA ("
                "${GapAverage.dbDate} INTEGER PRIMARY KEY, "
                "${GapAverage.dbAverage} REAL "
                ")");
      });
  }

  /// Add new row to database
  Future <int> addToDb(Database db, int date, double average) async{
    await db.rawInsert(
          'INSERT INTO '
              'GA(${GapAverage.dbDate}, ${GapAverage.dbAverage})'
              'VALUES ($date, $average)');
    return 0;
  }

  /// Get map of the desired searched item
  Future<List<Map>> getAverageQuery(Database db, int date) async{
    var result = await db.rawQuery('SELECT * FROM GA WHERE ${GapAverage.dbDate} = "$date"');
    return result;
  }

  /// Delete requested date and average
  Future<int> deleteRow(Database db, int date) async{
    return db.rawDelete('DELETE FROM GA WHERE ${GapAverage.dbDate} = "$date"');
  }

  /// Get query of all the rows in database
  Future getQuery(Database db) async {
    var query = await db.rawQuery('SELECT * FROM GA ORDER BY ${GapAverage.dbDate} ASC');
    return query;
  }
  
  /// Return a query with that begins at [start] and finishes at [end], and returns in descending if [desc] is true;
  Future getQueryRange(Database db, int start, int end, bool desc) async {
    var query;
    if (!desc) {
      query = await db.rawQuery('SELECT * FROM GA WHERE ${GapAverage.dbDate} >= $start AND ${GapAverage.dbDate} <= $end');
    }
    else {
      query = await db.rawQuery('SELECT * FROM GA WHERE ${GapAverage.dbDate} >= $start AND ${GapAverage.dbDate} <= $end '
      'ORDER BY ${GapAverage.dbDate} DESC');
    }
    return query;
  }

  /// Deletes database of the given name
  Future<String> deleteDb(String id) async {
    assert (id != null && id != "");
    // Get a location using path_provider
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, '${id}GA');

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
    String path = join(documentsDirectory.path, '${id}GA');

    // New directory for the file (new name)
    String newPath = join(documentsDirectory.path, '${newId}GA');

    // renaming
    var file = File(path);
    file.rename(newPath);

    return;
  }

}