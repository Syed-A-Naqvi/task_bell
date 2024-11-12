

import 'package:flutter/material.dart';
import 'package:task_bell/src/alarm/recurrence/relative_recur.dart';

import 'alarm_instance.dart';

class TimerInstance extends AlarmInstance {
  TimerInstance({
    required super.name, 
    required super.alarmSettings, 
    required super.recur,
    required super.parentId,
    super.key,
  });

  @override
  void toggleAlarm() {
    super.recur = RelativeRecur(recurTime: (recur as RelativeRecur).recurTime, initTime: DateTime.now());
    debugPrint("TOGGLED ALARM${(super.recur as RelativeRecur).initTime.toString()}\n");
    super.toggleAlarm();
  }

}