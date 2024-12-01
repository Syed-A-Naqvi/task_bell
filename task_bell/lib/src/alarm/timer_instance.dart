import 'package:alarm/alarm.dart';
import 'package:task_bell/src/alarm/recurrence/relative_recur.dart';
import 'alarm_instance.dart';
import 'package:flutter/material.dart';

import 'helpers/timer_or_folder.dart';

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

  @override
  void openEditMenu() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TimerOrFolderDialog(
          parentId: -2, // Provide the necessary parentId
          disableFolderTab: true,
          onCreateTimer: (alarmInstance) async {
            // I don't think there should be any real changes here other than
            // the type of dialog
            // update time and next occurrence and name in the database
            await tDB.updateAlarm(widget.alarmSettings.id, alarmInstance.recur.toMap());
            await tDB.updateAlarm(widget.alarmSettings.id, {"name":alarmInstance.name});

            // if the alarm is toggled on, remove from queue, update time and re-add to queue
            // I'm honestly not sure how this should be handled for timers. So for
            // the time being, behaviour of alarms will be copied
            if (widget.isActive) {
              Alarm.stop(widget.alarmSettings.id); // remove from queue, may be unnecessary
              Alarm.set(alarmSettings: alarmInstance.alarmSettings); // add to queue with updated time
            }

            fakeName = alarmInstance.name;
            fakeRecur = alarmInstance.recur;

            setState((){});
          },
          onCreateFolder: (folder){},
        );
      }
    );
  }
}