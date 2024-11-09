import 'dart:math';

import 'recur.dart';


class WeekRecur implements Recur {

  static const monday = 1;
  static const tuesday = 2;
  static const wednesday = 4;
  static const thursday = 8;
  static const friday = 16;
  static const saturday = 32;
  static const sunday = 64;
  static const fullWeek = 0x7F;

  // Store active days as a bit vector. can check if a day
  // is active or inactive by performing bitwise & w/ consts above
  int activeDays = 0;

  // bad variable name, but this is the number of weeks skipped after each
  // week that the alarm goes off
  // for example, if skip weeks = 1, alarm will go off every other week
  int skipWeeks = 0;

  // similar to skipWeeks, except this is the number of times the alarm
  // will be repeated in a row, so if this is 1, and skipWeeks is also 1
  // then you get 2 weeks with alarm, then 1 week skip
  int repeatWeeks = 0;

  /// The primary purpose of this is to act as a way of getting the
  /// hour, minute, and day of the alarm.
  /// However, the specific day will have an impact on when the alarm
  /// triggers, if skipWeeks and repeatWeeks are non zero
  DateTime recurTime;

  WeekRecur({
    required this.activeDays,
    required this.recurTime,
    this.skipWeeks = 0,
    this.repeatWeeks = 0,
  });

  static int getWeekBitVector(
    bool sunday, bool monday, bool tuesday, 
    bool wednesday, bool thursday, bool friday, bool saturday
  ) {
    // If only java supported casting bool -> int
    return  (sunday    ? WeekRecur.sunday   : 0) | 
            (monday    ? WeekRecur.monday   : 0) |
            (tuesday   ? WeekRecur.tuesday  : 0) |
            (wednesday ? WeekRecur.wednesday: 0) |
            (thursday  ? WeekRecur.thursday : 0) |
            (friday    ? WeekRecur.friday   : 0) |
            (saturday  ? WeekRecur.saturday : 0) ;
  }

  /// Expects day to refer to a single day, 
  bool isDayActive(int weekRecurDay) {
    return weekRecurDay & activeDays != 0;
  }

  bool isNumDayActive(int dateTimeWeekDay) {
    return isDayActive(pow(2,dateTimeWeekDay-1).toInt());
  }

  @override
  DateTime? getNextOccurence(DateTime time) {

    // Ignore skipWeeks and repeatWeeks for now
    if (activeDays == 0) {
      return null;
    }

    int hourDiff = recurTime.hour - time.hour;
    hourDiff = hourDiff < 0 ? 0 : hourDiff;
    int minuteDiff = recurTime.minute - time.minute;
    minuteDiff = minuteDiff < 0 ? 0 : minuteDiff;
    int secondDiff = recurTime.second - time.second;
    secondDiff = secondDiff < 0 ? 0 : secondDiff;

    // check if alarm is later today
    if (isNumDayActive(time.weekday) && 
        hourDiff > 0 ||
        hourDiff == 0 && minuteDiff > 0 ||
        hourDiff == 0 && minuteDiff == 0 && secondDiff > 0) {

      return DateTime(
        time.year,
        time.month,
        time.day,
        recurTime.hour,
        recurTime.minute,
        recurTime.second
      );
    }

    // go through rest of days of week in order from given day
    for (int i = 0; i < DateTime.daysPerWeek; i++) {

      int day = time.weekday + i + 1;
      if (day > 7) {
        day -= 7;
      }

      if (!isNumDayActive(day)) {
        continue;
      }

      // i is the number of days after the next day, so +1 is needed
      // DateTime should automatically handle exceeding num of days in month (untested)
      return DateTime(
        time.year,
        time.month,
        time.day + i+1,
        recurTime.hour,
        recurTime.minute,
        recurTime.second
      );
    }

    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      "activedays" : activeDays,
      "skipweeks" : skipWeeks,
      "repeatweeks" : repeatWeeks,
      "time": recurTime.millisecondsSinceEpoch,
    };
  }

  static fromMap(Map<String, dynamic> map) {
    return WeekRecur(
      activeDays: map["activedays"], 
      recurTime: DateTime.fromMillisecondsSinceEpoch(map["time"]),
      skipWeeks: map["skipweeks"],
      repeatWeeks: map["repeatweeks"],
    );
  }
}