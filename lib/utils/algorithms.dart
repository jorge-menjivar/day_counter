import 'package:flutter/material.dart';

import 'package:day_counter/main.dart';

// Utils
import 'package:tuple/tuple.dart';
import 'gap_average_database.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:math';
import 'flags_database.dart';
import 'schedules_database.dart';

class Algorithms {
  
  final int daysInSchedule = 7;
  
  GapAverageDatabase _gapAverageDatabase = GapAverageDatabase();
  FlagsDatabase _flagsDatabase = FlagsDatabase();
  SchedulesDatabase _schedulesDatabase = SchedulesDatabase();
  
  /// Algorithm to get chart data from the red flags in database.
  List<ProgressByDate> getDataList (dynamic results, int initial) {
    
    const double penaltyValue = .2;
    const int minDayExtraPenalty = 5;
    const double extraPenalty = 1.7;
    
    // The data we will later return.
    List<ProgressByDate> data = new List<ProgressByDate>();
    
    // The day the counter was started
    DateTime date1 = DateTime.fromMillisecondsSinceEpoch(initial);
    
    // Starting the data with the initial day as our first point.
    data.add(new ProgressByDate(day: 0, progress: 0, color: Colors.blue));
    
    double progress = 0;
    int days = 0;
    
    DateTime date2;
    
    final int size = results.length;
    for (int i = 0; i < size; i++) {
      double penalty = 0;
      
      var row = results[i];
      
      // Getting the next flag date from the database
      date2 = DateTime.fromMillisecondsSinceEpoch(row['date']);
      
      // The difference between the last flag and this flag.
      int difference = date2.difference(date1).inDays;
      days += difference;
      
      // Adding the difference to the progress before penalizing.
      progress += difference;
      
      // Adding a point before the penalties so that it represents the loss
      data.add(new ProgressByDate(day: days-1, progress: progress, color: Colors.red));
      
      // If extra penalty should be applied
      if (difference <= minDayExtraPenalty) {
        penalty = (progress * penaltyValue) * (extraPenalty);
        // Rounding double to 3 decimal places.
        penalty = dp(penalty, 3);
      }
      
      else {
        penalty = (progress * penaltyValue);
        // Rounding double to 3 decimal places.
        penalty = dp(penalty, 3);
      }
      
      // Adding penalties
      progress -= penalty;
      // Rounding double to 3 decimal places.
      progress = dp(progress, 3);
      
      // Adding starting point for the following progress (The following blue line), after penalty
      data.add(new ProgressByDate(day: days, progress: progress, color: Colors.blue));
      
      date1 = date2;
    }
    
    date2 = DateTime.now();
    int difference = date2.difference(date1).inDays;
    days += difference;
    progress += difference;
    // Rounding double to 3 decimal places.
    progress = dp(progress, 3);
    
    data.add(new ProgressByDate(day: days, progress: progress, color: Colors.blue));
    
    return data;
    
  }
  
  
  
  
  
  
  /// Machine Learning algorithm that returns a schedule ([List] of [Tuple2]) for that represent a day
  /// with flag if [bool] is [true]. And includes the number of flags in [int]
  /// This is for the counter [name], and based on its flag patterns.
  /// Returns [null] if no flags were found.
  Future<List<Tuple2>> getSchedule(String name, int initial, int last, bool rebuild) async{
    
    // A list of tuples or pairs representing range and amount
    var schedule = List<Tuple2>();
    
    double average;
    double bias;
    double ground;
    double difference;
    double gap;
    
    // Getting the gap average for today as well as saving it to the gap average database.
    average = await _computeAverage(name, initial, last, rebuild);
    
    // Exit if the number of flags does not meet criteria
    if (average == null) return null;
    
    Tuple2 aAndG = await _getAverageAndGround(name);
    
    bias = aAndG.item1;
    ground = aAndG.item2;
    
    // The difference between todays average and AGA
    difference = average - bias;
    difference = dp(difference, 3);
    
    // Absolute value of difference
    double dAbsolute = sqrt(difference * difference);
    dAbsolute = dp(dAbsolute, 3);
    
    if (ground < 0) {
      gap = dAbsolute + ground;
    }
    
    else if (ground >= 0) {
      gap = (dAbsolute * ground) + average;
    }
    
    schedule = await _createSchedule(name, gap, ground, rebuild);
    
    return schedule;
  }
  
  
  
  
  
  
  /// Returns the Average Gap Average[average] and Ground[ground] variables for the given query
  Future<Tuple2<double, double>> _getAverageAndGround(String name) async {
    
    const int daysToConsider = 15;
    
    var now = DateTime.now();
    var today = DateTime(now.year, now.month, now.day);
    DateTime start = today.subtract(Duration(days: 29));
    
    Database gapDb = await _gapAverageDatabase.getDb(name);
    // Descending query
    var query = await _gapAverageDatabase.getQueryRange(gapDb, start.millisecondsSinceEpoch, today.millisecondsSinceEpoch, true);
    
    double average;
    double ground;
    double sum = 0, gSum = 0;
    
    // The number of days the var ground takes in consideration. In case less than 6 days of data are available.
    int dFG = 0;
    
    // Taking in consideration the last 30 days of GAs only
    for (int i = 0; i < daysToConsider && i < query.length; i++) {
      
      var row = query[i];
      double rAvg = row['average'];
      
      sum += rAvg;
      // Rounding double to 3 decimal places.
      sum = dp(sum, 3);
      
      // If time to start getting the ground variable
      if (i < 7) {
        
        if (i != 0) {
          // Counting the actual number of days.
          dFG++;
          
          // Since we are counting from right to left (desc), row[i-1] is older than row[i]
          var rowAft = query[(i -1)];
          var aveAft = rowAft['average'];
          
          gSum += (aveAft - rAvg);
          // Rounding double to 3 decimal places.
          gSum = dp(gSum, 3);
          
          // Updating the ground variable
          ground = gSum / dFG;
          // Rounding double to 3 decimal places.
          ground = dp(ground, 3);
        }
      }
      
      // If not enough days to reach days to consider
      if (query.length < daysToConsider) {
        average = sum / query.length;
      }
      else {
        average = sum / daysToConsider;
      }
      
      // Rounding double to 3 decimal places.
      average = dp(average, 3);
      
    }
    
    gapDb.close();
    return Tuple2(average, ground);
  }
  
  
  
  
  /// Gets and saving the gap average for any days missing from database and returns the average for today
  /// Returns [null] if user has not added flags to this counter.
  Future<double> _computeAverage(String name, int initial, int last, bool rebuild) async{
    
    const int daysToConsider = 10;
    
    double average;
    int sum = 0;
    
    var now = DateTime.now();
    var today = DateTime(now.year, now.month, now.day);
    
    Database flagsDb = await _flagsDatabase.getDb(name);
    var flagsQuery = await _flagsDatabase.getQuery(flagsDb);
    
    if (flagsQuery.length < 5) {
      return null;
    }
    
    Database gapDb = await _gapAverageDatabase.getDb(name);
    var gapQuery = await _gapAverageDatabase.getQuery(gapDb);
    
    var gapRow;
    int missing;
    
    if (rebuild || gapQuery.length < 5) {
      // The number of averages that need to be added to the database
      var row = flagsQuery[0];
      DateTime lastSaved = DateTime.fromMillisecondsSinceEpoch(row['date']);
      
      // The number of averages that need to be added to the database
      missing = DateTime.now().difference(lastSaved).inDays;
    }
    
    else {
      // The number of averages that need to be added to the database
      gapRow = gapQuery[(gapQuery.length-1)];
      DateTime lastSaved = DateTime.fromMillisecondsSinceEpoch(gapRow['date']);
      
      // The number of averages that need to be added to the database
      missing = DateTime.now().difference(lastSaved).inDays;
    }
    
    // Adjusting the missing days factor so it rebuilds todays date and the actual missing days only.
    int loopStart;
    missing == 0 ? loopStart = 0 : loopStart = missing-1;
    
    for (int j = loopStart; j >= 0; j--) {
      sum = 0;
      // The days to take in consideration for this average
      // End in DateTime
      var endDT = today.subtract(Duration(days: j));
      // Start and end in millisecondsSinceEpoch
      var start = endDT.subtract(Duration(days: daysToConsider)).millisecondsSinceEpoch;
      var end = endDT.millisecondsSinceEpoch;
      
      // Range query from start to end
      var flagRangeQuery = await _flagsDatabase.getQueryRange(flagsDb, start, end, false);
      
      // Checking that there is at least 2 flags.
      if (flagRangeQuery.length > 1) {
        
        DateTime date1;
        DateTime date2;
        
        // First Row
        var row = flagRangeQuery[0];
        date1 = DateTime.fromMillisecondsSinceEpoch(row['date']);
        
        for (int i = 1; i < flagRangeQuery.length; i++) {
        
          // Current Row
          row = flagRangeQuery[i];
          
          // Getting the next flag date from the database
          date2 = DateTime.fromMillisecondsSinceEpoch(row['date']);
          
          // The gap between the last flag and this flag.
          int gap = date2.difference(date1).inDays;
          sum += gap;
          
          date1 = date2;
          
          // If everything went well, time to exit
          if (i == flagRangeQuery.length-1) {
            // From last flag to day being calculated
            DateTime day = today.subtract(Duration(days: j));
            int gap = day.difference(date1).inDays;
            sum += gap;
            // Time to conclude
            average = sum / flagRangeQuery.length;
            // Rounding double to 3 decimal places.
            average = dp(average, 3);
            break;
          }
        
        }
      
        // Getting the correct date for this average
        DateTime day = today.subtract(Duration(days: j));
        
        // If all the machine needs to be rebuilt
        if (rebuild || j == 0 || gapQuery.length < 5){
          // Deleting previously saved data
          await _gapAverageDatabase.deleteRow(gapDb, day.millisecondsSinceEpoch);
        }
        
        // Saving new
        await _gapAverageDatabase.addToDb(gapDb, day.millisecondsSinceEpoch, average);
      }
      
      // If less than 2 flags found for this range
      else {
        average = daysToConsider.toDouble();
        // Getting the correct date for this average
        DateTime day = today.subtract(Duration(days: j));
        
        // If all the machine needs to be rebuilt
        if (rebuild || j == 0){
          // Deleting previously saved data
          await _gapAverageDatabase.deleteRow(gapDb, day.millisecondsSinceEpoch);
        }
        
        // Saving new
        await _gapAverageDatabase.addToDb(gapDb, day.millisecondsSinceEpoch, average);
      }
    }
    
    await flagsDb.close();
    await gapDb.close();
    return average;
  }
  
  /// Makes the given [gap] and ground [values] into a readable schedule for next week
  Future<List<Tuple2<bool, int>>> _createSchedule(String name, double gap, double ground, bool rebuild) async{
    var schedule = List<Tuple2<bool, int>>();
    var newSchedule = List<Tuple2<bool, int>>();
    
    // Deleting database so it can be rebuilt
    if (rebuild) {
      await _schedulesDatabase.deleteDb(name);
    }
    
    var sDatabase = await _schedulesDatabase.getDb(name);
    var oldScheduleQuery = await _schedulesDatabase.getQuery(sDatabase);
    
    if (oldScheduleQuery.length == 0) {
      // +2
      schedule.add(Tuple2(false, 0));
      schedule.add(Tuple2(false, 0));
      
      // +7 = 9
      schedule.addAll(_get7Days(gap, ground));
      
      // +7 = 16
      schedule.addAll(_get7Days(gap, ground));
    }
    
    else {
      for (int i = 0; i < oldScheduleQuery.length; i++) {
        var row = oldScheduleQuery[i];
        bool flagBool;
        (row['flag'] == 1) ? flagBool = true : flagBool = false;
        var tuple = Tuple2<bool, int>(flagBool, row['amount']);
        schedule.add(tuple);
      }
      
      var tempRow = oldScheduleQuery[0];
      var lastDate = DateTime.fromMillisecondsSinceEpoch(tempRow['time']);
      
      var now = DateTime.now();
      var today = DateTime(now.year, now.month, now.day);
      
      int difference = today.difference(lastDate).inDays - 2;
      
      for (int i = difference; i > 0; i--) {
        schedule.removeAt(0);
        // Shifting the list left since first value is removed
        for (int j = 1; j < schedule.length; j++) {
          schedule[j-1] = schedule[j];
        }
      }
      
      while (difference >= daysInSchedule) {
        // Get 7 days
        newSchedule.clear();
        newSchedule = _get7Days(gap, ground);
        
        // Adding days to the main schedule
        schedule.addAll(_get7Days(gap, ground));
        
        difference -= 7;
      }
    }
    
    await _save(name, schedule, sDatabase);
    sDatabase.close();
    return schedule;
  }
  
  
  /// Returns a schedule for 7 days
  List<Tuple2<bool, int>> _get7Days (double gap, double ground) {
    var newSchedule = List<Tuple2<int, int>>();
    
    // The number of flags that fit in this schedule
    int f = (daysInSchedule ~/ gap).toInt();
    int flags = sqrt(f*f).round();
    
    // If ground is negative put ranges as close as possible
    if (ground < 0) {
      while (flags > 0) {
        int amount = (flags / 2).round();
        int range = amount;
        flags -= amount;
        
        // The days with flags
        newSchedule.add(Tuple2<int, int>(range, 1));
        
        // Days without flags
        newSchedule.add(Tuple2<int, int>(1, 0));
      }
    }
    
    // If ground is positive put range as separate as possible
    else if (ground >= 0) {
      switch (flags) {
        case 1: {
          newSchedule.add(Tuple2<int, int>(3, 0));
          newSchedule.add(Tuple2<int, int>(1, 1));
          break;
        }
        
        case 2: {
          newSchedule.add(Tuple2<int, int>(1, 0));
          newSchedule.add(Tuple2<int, int>(1, 1));
          newSchedule.add(Tuple2<int, int>(2, 0));
          newSchedule.add(Tuple2<int, int>(1, 1));
          newSchedule.add(Tuple2<int, int>(2, 0));
          break;
        }
        
        case 3: {
          newSchedule.add(Tuple2<int, int>(2, 0));
          newSchedule.add(Tuple2<int, int>(1, 1));
          newSchedule.add(Tuple2<int, int>(1, 0));
          newSchedule.add(Tuple2<int, int>(1, 1));
          newSchedule.add(Tuple2<int, int>(1, 0));
          newSchedule.add(Tuple2<int, int>(1, 1));
          break;
        }
      }
    }
    
    
    return _translateSchedule(newSchedule);
  }
  
  
  /// Saves schedule to database
  Future<void> _save(String name, List<Tuple2> schedule, var db) async{
    await _schedulesDatabase.deleteAll(db);
    
    for (int i = 0; i < schedule.length; i++) {
      var now = DateTime.now();
      var today = DateTime(now.year, now.month, now.day);
      
      var timeDT = today.add(Duration(days: i - 2));
      int time = timeDT.millisecondsSinceEpoch;
      
      await _schedulesDatabase.addToDb(db, timeDT.day, schedule[i].item1, schedule[i].item2, time);
    }
  }
  
  
  /// Translates the given raw schedule and makes it into a neat list that specifies if
  /// there is a flag for each day of the week.
  List<Tuple2<bool, int>> _translateSchedule(List<Tuple2<int, int>> schedule) {
    // Converting the passed schedule list of tuples so it is easier for the widget to understand.
    var days = List<Tuple2<bool, int>>();
    
    // For every range in the schedule
    for (var v in schedule) {
      
      // For every day in the range
      for (int i = 0; i < v.item1; i++) {
        (v.item2 == 0) ? days.add(Tuple2(false, v.item2)) : days.add(Tuple2(true, v.item2));
      }
    }
    
    // Add the remaining days the schedule did not include
    while (days.length < 7) {
      days.add(Tuple2(false, 0));
    }
    
    // Trimming schedule in case accidentally added more than 7
    while (days.length > 7) {
      days.removeLast();
    }
    
    return days;
  }
  
  double dp(double val, double places){ 
    double mod = pow(10.0, places); 
    return ((val * mod).round().toDouble() / mod); 
  }
}