import 'package:alarm/alarm.dart';
import 'recurrence/recur.dart';
import 'recurrence/relative_recur.dart';
import 'package:flutter/material.dart';
import 'alarm_instance.dart';

import 'alarm_folder.dart';

class TimerFolder extends AlarmFolder {
  TimerFolder({super.key, required super.id, required super.name, required super.position});

  @override
  State<StatefulWidget> createState() => TimerFolderState();
}

class TimerFolderState extends AlarmFolderState {

  @override
  Recur getRecurObject(DateTime recurTime) {
    return RelativeRecur(
      initTime: DateTime.now(),
      recurTime: recurTime
    );
  }
}