import 'package:flutter/material.dart';

import 'package:day_counter/main.dart';

// Utils
import 'package:tuple/tuple.dart';
import 'gap_average_database.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:math';
import 'flags_database.dart';

class Algorithms {
  
  //TODO round up doubles so they don't overflow
  
  GapAverageDatabase _gapAverageDatabase = GapAverageDatabase();
  FlagsDatabase _flagsDatabase = FlagsDatabase();
  
  /// Algorithm to get chart data from the red flags in database.
  List<ProgressByDate> getDataList (dynamic results, String initial) {
    
    const double penaltyValue = .2;
    const int minDayExtraPenalty = 5;
    const double extraPenalty = 1.7;
    
    // The data we will later return.
    List<ProgressByDate> data = new List<ProgressByDate>();
    
    // The day the counter was started
    DateTime date1 = DateTime.fromMillisecondsSinceEpoch(int.parse(initial));
    
    // Starting the data with the initial day as our first point.
    data.add(new ProgressByDate(day: 0, progress: 0, color: Colors.blue));
    
    double progress = 0;
    int days = 0;
    
    DateTime date2;
    
    final int size = results.length;
    for (int i = 0; i < size; i++) {
      double penalty = 0;
      
      var row = results[i];
      
      // Gettin the next flag date from the database
      date2 = DateTime.fromMillisecondsSinceEpoch(int.parse(row['date']));
      
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
      }
      
      else {
        penalty = (progress * penaltyValue);
      }
      
      // Adding penalties
      progress -= penalty;
      
      // Adding starting point for the following progress (The following blue line), after penalty
      data.add(new ProgressByDate(day: days, progress: progress, color: Colors.blue));
      
      date1 = date2;
    }
    
    date2 = DateTime.now();
    int difference = date2.difference(date1).inDays;
    days += difference;
    progress += difference;

    data.add(new ProgressByDate(day: days, progress: progress, color: Colors.blue));
    
    return data;
    
  }
  
  
  
  
  
  
  /// Machine Learning algorith that returns a schedule ([List] of [Tuple2]) for the user counter[name],
  /// based on their flag patterns. The tuple represents range and amount.
  /// Returns [null] if no flags were found.
  Future<List<Tuple2<int, int>>> getSchedule(String name) async{
    
    // A list of tuples or pairs representing range and amount
    var schedule = List<Tuple2<int, int>>();
    
    double average;
    double bias;
    double ground;
    double difference;
    double gap;
    
    // Getting the gap average for today as well as saving it to the gap average database.
    average = await _computeAverage(name);
    
    // User has not added a flag yet.
    if (average == null) {
      return null;
    }
    
    Tuple2 aAndG = await _getAverageAndGround(name);
    
    bias = aAndG.item1;
    ground = aAndG.item2;
    
    // The difference between todays average and AGA
    difference = average - bias;
    
    // Absolute value of difference
    double dAbsolute = sqrt(difference * difference);
    
    if (ground < 0) {
      gap = dAbsolute - bias;
    }
    
    else if (ground >= 0) {
      gap = (dAbsolute * ground) + average;
    }
    
    schedule = await _translateSchedule(gap, ground);
    
    return schedule;
  }
  
  
  
  
  
  
  /// Returns the Average Gap Average[average] and Ground[ground] variables for the given query
  Future<Tuple2<double, double>> _getAverageAndGround(String name) async {
    
    Database gapDb = await _gapAverageDatabase.getDb(name);
    var query = await _gapAverageDatabase.getQuery(gapDb);
    
    double average;
    double ground;
    double sum = 0, gSum = 0;
    
    // The number of days the var ground takes in consideration. In case less than 6 days of data are available.
    int dFG = -1;
    
    // Taking in consideration the last 30 days of GAs only
    for (int i = 0; i < 30; i++) {
      
      var row = query[i];
      double rAvg = row['average'];
      
      sum += rAvg;
      
      // If time to start getting the ground variable
      if (i >= query.length - 5 && i > 0) {
        
        // If dFg has not been initialized yet.
        if (dFG == -1) {
          dFG = i;
        }
        
        var rowBef = query[i -1];
        var aveBef = rowBef['average'];
        
        gSum += (rAvg - aveBef) / 1;
      }
      
      // If database does not have 30 days stored yet.
      if (i == query.length-1) {
        // Time to exit
        average = sum / query.length;
        break;
      }
      
      // If the loop reached day 30
      else if (i == 29) {
        average = sum / i;
        ground = gSum / (i - dFG);
      }
    }
    
    gapDb.close();
    return Tuple2<double, double>(average, ground);
  }
  
  
  
  
  /// Gets and saving the gap average for any days missing from database and returns the average for today
  /// Returns [null] if user has not added flags to this counter.
  Future<double> _computeAverage(String name) async{
    
    const int DAYS_TO_CONSIDER = 20;
    double average;
    double sum;
    
    Database flagsDb = await _flagsDatabase.getDb(name);
    var query = await _flagsDatabase.getQueryDesc(flagsDb);
    
    if (query.length == 0) {
      return null;
    }
    
    Database gapDb = await _gapAverageDatabase.getDb(name);
    var gapQuery = await _gapAverageDatabase.getQuery(gapDb);
    
    // The last time an average was saved to database;
    var gapRow = gapQuery[0];
    DateTime lastSaved = DateTime.fromMillisecondsSinceEpoch(int.parse(gapRow['date']));
    
    // The number of averages that need to be added to the database
    int missing = DateTime.now().difference(lastSaved).inDays;
    
    for (int j = missing - 1; j >= 0; j--) {
      // The flags to take in consideration for this day;
      int start = j;
      int end = start + DAYS_TO_CONSIDER;
      var row = query[start];
      DateTime date1 = DateTime.fromMillisecondsSinceEpoch(int.parse(row['date']));
      DateTime date2;
      
      for (int i = start + 1; i < end; i++) {
        row = query[i];
        
        // Gettin the next flag date from the database
        date2 = DateTime.fromMillisecondsSinceEpoch(int.parse(row['date']));
        
        // The gap between the last flag and this flag.
        int gap = date2.difference(date1).inDays;
        sum += gap;
        
        date1 = date2;
        
        if (i == query.length-1) {
          // Time to exit
          average = sum / query.length;
        }
        
        if (i == gap -1) {
          average = sum / DAYS_TO_CONSIDER;
        }
      }
      
      // Getting the correct date for this average
      DateTime day = DateTime.now().subtract(Duration(days: j));
      
      // Saving to database
      await _gapAverageDatabase.addToDb(gapDb, day.millisecondsSinceEpoch.toString(), average);
    }
    return average;
  }
  
  /// Transalates the given [gap] and ground [values] into a readable schedule for next week
  Future<List<Tuple2<int, int>>> _translateSchedule(double gap, double ground) async{
    var schedule = List<Tuple2<int, int>>();
    
    const int DAYS_IN_SCHEDULE = 7;
    
    // The number of flags that fit in this schedule
    int flags = (DAYS_IN_SCHEDULE ~/ gap).toInt();
    
    // If ground is negative put ranges as close as possible
    if (ground < 0) {
      while (flags > 0) {
        int range = flags;
        int amount = (flags / 2).round();
        flags -= amount;
        
        // The days with flags
        schedule.add(Tuple2<int, int>(range, amount));
        
        // The days without flags
        schedule.add(Tuple2<int, int>(1, 0));
      }
    }
    
    // If ground is positive put range as separate as possible
    else if (ground >= 0) {
      switch (flags) {
        case 1: {
          schedule.add(Tuple2<int, int>(3, 0));
          schedule.add(Tuple2<int, int>(2, 1));
          break;
        }
        
        case 2: {
          schedule.add(Tuple2<int, int>(1, 0));
          schedule.add(Tuple2<int, int>(2, 1));
          schedule.add(Tuple2<int, int>(2, 0));
          schedule.add(Tuple2<int, int>(2, 1));
          break;
        }
        
        case 3: {
          schedule.add(Tuple2<int, int>(1, 0));
          schedule.add(Tuple2<int, int>(4, 2));
          schedule.add(Tuple2<int, int>(1, 0));
          schedule.add(Tuple2<int, int>(1, 1));
        }
      }
    }
    return schedule;
  }
}