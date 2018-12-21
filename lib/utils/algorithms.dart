import 'package:flutter/material.dart';

import 'package:day_counter/main.dart';

class Algorithms {
  
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

}