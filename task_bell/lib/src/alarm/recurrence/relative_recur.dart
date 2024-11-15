import 'package:flutter/material.dart';
import 'recur.dart';

class RelativeRecur implements Recur {
  final DateTime recurTime; // Offset for recurrence
  DateTime initTime; // Initial time of setting the alarm

  /// [recurTime] specifies the recurrence offset (e.g., hours, minutes, seconds).
  /// Note: Month and year offsets are approximate (30 days, 365 days).
  RelativeRecur({
    required this.recurTime,
    required this.initTime,
  });

  @override
  DateTime? getNextOccurrence(DateTime time) {
    final durationOffset = Duration(
      hours: recurTime.hour,
      minutes: recurTime.minute,
      seconds: recurTime.second,
    );
    final nextOccurrence = initTime.add(durationOffset);

    debugPrint("Next occurrence scheduled for $nextOccurrence "
               "(InitTime: $initTime, RecurTime: $recurTime)");

    return nextOccurrence;
  }

  static RelativeRecur? fromMap(Map<String, dynamic> map) {
    if (map["recurtype"] != "relative") return null;

    return RelativeRecur(
      initTime: DateTime.fromMillisecondsSinceEpoch(map["inittime"]),
      recurTime: DateTime.fromMillisecondsSinceEpoch(map["recurtime"]),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    "recurtype": "relative",
    "inittime": initTime.millisecondsSinceEpoch,
    "recurtime": recurTime.millisecondsSinceEpoch,
  };
}
