import 'package:flutter/material.dart';

import 'recur.dart';

class RelativeRecur implements Recur {

  final DateTime recurTime;
  final DateTime initTime;

  /// recurTime is expected to be the actual timer offset. All fields matter
  /// So, if days is > 0, the timer will be over 1 day long. Applies for all fields.
  /// Note: Using months & years is inaccurate and uses approxiate values (30d, 365d respectively)
  /// initTime is when the timer/alarm was enabled. next occurence will be calculated relative to this
  RelativeRecur({
    required this.recurTime,
    required this.initTime,
  });

  @override
  DateTime? getNextOccurence(DateTime time) {

    DateTime out = DateTime(
      initTime.year,
      initTime.month,
      initTime.day,
      initTime.hour + recurTime.hour,
      initTime.minute + recurTime.minute,
      initTime.second + recurTime.second + recurTime.millisecond > 500 ? 1 : 0,
    );

    debugPrint("scheduled for ${out.toString()}, current time: ${DateTime.now()}");
    debugPrint("recurTime: ${recurTime.toString()}, initTime: ${initTime.toString()}");
    
    return out;
  }
  
  static Recur? fromMap(Map<String, dynamic> map) {
    if (map["recurtype"] != "relative") {
      return null;
    }

    return RelativeRecur(
      initTime: DateTime.fromMillisecondsSinceEpoch(map["inittime"]),
      recurTime: DateTime.fromMillisecondsSinceEpoch(map["recurtime"]),
    );
  }
  
  @override
  Map<String, dynamic> toMap() {
    return {
      "recurtype": "relative",
      "inittime": initTime.millisecondsSinceEpoch,
      "recurtime": recurTime.millisecondsSinceEpoch,
    };
  }

}
