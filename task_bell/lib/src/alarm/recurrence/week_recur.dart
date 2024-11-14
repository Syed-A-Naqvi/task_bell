import 'package:flutter/material.dart';
import 'recur.dart';

class WeekRecur implements Recur {
  static const monday = 1;
  static const tuesday = 2;
  static const wednesday = 4;
  static const thursday = 8;
  static const friday = 16;
  static const saturday = 32;
  static const sunday = 64;

  final int activeDays;
  final DateTime recurTime;
  final int skipWeeks;
  final int repeatWeeks;

  WeekRecur({
    required this.activeDays,
    required this.recurTime,
    this.skipWeeks = 0,
    this.repeatWeeks = 0,
  });

  /// Helper to convert individual days to a bit vector.
  static int getWeekBitVector({
    required bool sunday,
    required bool monday,
    required bool tuesday,
    required bool wednesday,
    required bool thursday,
    required bool friday,
    required bool saturday,
  }) {
    return (sunday ? WeekRecur.sunday : 0) |
           (monday ? WeekRecur.monday : 0) |
           (tuesday ? WeekRecur.tuesday : 0) |
           (wednesday ? WeekRecur.wednesday : 0) |
           (thursday ? WeekRecur.thursday : 0) |
           (friday ? WeekRecur.friday : 0) |
           (saturday ? WeekRecur.saturday : 0);
  }

  bool _isDayActive(int dayBit) => activeDays & dayBit != 0;

  bool _isWeekdayActive(int weekday) => _isDayActive(1 << (weekday - 1));

  @override
  DateTime? getNextOccurrence(DateTime time) {
    if (activeDays == 0) {
      debugPrint("No active days set for recurrence.");
      return null;
    }

    // Check if the alarm can occur later today
    if (_isWeekdayActive(time.weekday) &&
        (time.isBefore(DateTime(time.year,time.month, time.day, recurTime.hour, recurTime.minute, recurTime.second)))) {
      return DateTime(
        time.year,
        time.month,
        time.day,
        recurTime.hour,
        recurTime.minute,
        recurTime.second,
      );
    }

    // Search the next active day of the week
    for (int i = 1; i <= DateTime.daysPerWeek; i++) {
      final nextDay = (time.weekday + i) % DateTime.daysPerWeek;
      if (_isWeekdayActive(nextDay == 0 ? 7 : nextDay)) {
        final targetDate = time.add(Duration(days: i));
        return DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          recurTime.hour,
          recurTime.minute,
          recurTime.second,
        );
      }
    }

    debugPrint("Unexpectedly reached null in getNextOccurrence.");
    return null;
  }

  @override
  Map<String, dynamic> toMap() => {
        "recurtype": "week",
        "activedays": activeDays,
        "skipweeks": skipWeeks,
        "repeatweeks": repeatWeeks,
        "time": recurTime.millisecondsSinceEpoch,
      };

  static WeekRecur fromMap(Map<String, dynamic> map) {
    return WeekRecur(
      activeDays: map["activedays"],
      recurTime: DateTime.fromMillisecondsSinceEpoch(map["time"]),
      skipWeeks: map["skipweeks"] ?? 0,
      repeatWeeks: map["repeatweeks"] ?? 0,
    );
  }
}
