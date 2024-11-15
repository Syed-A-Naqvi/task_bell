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
  String formatDateTime(bool relative) {
    DateTime now = DateTime.now();
    DateTime? nextOccurrence = widget.recur.getNextOccurrence(now);

    if (nextOccurrence == null) return "";

    if (relative) {

      late final Duration diff;

      if (super.isActive) {
        diff = nextOccurrence.difference(now); 
      } else {
        diff = nextOccurrence.difference((widget.recur as RelativeRecur).initTime);
      }

      
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      final minutes = diff.inMinutes % 60;
      final seconds = diff.inSeconds % 60;

      return "${days}d, ${hours}h, ${minutes}m, ${seconds}s";
    }

    return nextOccurrence.toString();
  }

  @override
  Future<void> toggleAlarmStatus() async {
    // Update recur with a new RelativeRecur object before toggling the alarm
    (widget.recur as RelativeRecur).initTime = DateTime.now();

    debugPrint("Timer toggled");

    await super.toggleAlarmStatus();
  }
}
