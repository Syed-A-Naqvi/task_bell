

import 'package:task_bell/src/alarm/recurrence/relative_recur.dart';

import 'alarm_instance.dart';

class TimerInstance extends AlarmInstance {
  TimerInstance({
    required super.name, 
    required super.alarmSettings, 
    required super.recur,
    super.key,
  });

  @override
  void toggleAlarm() {
    super.recur = RelativeRecur(recurTime: (recur as RelativeRecur).recurTime, initTime: DateTime.now());
    super.toggleAlarm();
  }

}