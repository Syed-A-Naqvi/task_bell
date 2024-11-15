import 'package:task_bell/src/alarm/recurrence/relative_recur.dart';
import 'alarm_instance.dart';
import 'package:flutter/material.dart';

class TimerInstance extends AlarmInstance {
  const TimerInstance({
    required super.name, 
    required super.alarmSettings, 
    required super.recur,
    required super.parentId,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => TimerInstanceState();
}

class TimerInstanceState extends AlarmInstanceState {

  @override
  Future<void> toggleAlarmStatus() async {
    // Update recur with a new RelativeRecur object before toggling the alarm
    (widget.recur as RelativeRecur).initTime = DateTime.now();

    await super.toggleAlarmStatus();
  }
}
