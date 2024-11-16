// create_timer_dialog.dart
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:task_bell/src/alarm/timer_instance.dart';
import '../alarm_instance.dart';
import '../recurrence/relative_recur.dart';

class TimerDialog extends StatefulWidget {
  final int parentId;
  final ValueChanged<AlarmInstance> onCreate;

  const TimerDialog({
    required this.onCreate,
    required this.parentId,
    super.key,
  });

  @override
  TimerDialogState createState() => TimerDialogState();
}

class TimerDialogState extends State<TimerDialog> {

  final TextEditingController nameController = TextEditingController();
  int hours = 0;
  int minutes = 0;

  void _createTimer() {
    if (nameController.text.isEmpty || (hours == 0 && minutes == 0)) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("Please provide all details"),
        ),
      );
      return;
    }

    final Duration duration = Duration(hours: hours, minutes: minutes);
    // final DateTime recurTime = DateTime.now().add(duration);
    final DateTime recurTime = DateTime(0).add(duration);

    TimerInstance alarmInstance = TimerInstance(
      name: nameController.text,
      parentId: widget.parentId,
      alarmSettings: AlarmSettings(
        id: (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 2147483647,
        dateTime: recurTime,
        assetAudioPath: "assets/alarm.mp3", // Specify your asset audio path
        vibrate: true,
        loopAudio: true,
        volume: null,
        volumeEnforced: false,
        fadeDuration: 3,
        warningNotificationOnKill: true,
        androidFullScreenIntent: true,
        notificationSettings: NotificationSettings(
          title: nameController.text,
          body: "Timer set for ${hours}h ${minutes}m from now",
          stopButton: 'Stop the timer',
          icon: 'notification_icon',
        ),
      ),
      recur: RelativeRecur(
        initTime: DateTime.now(),
        recurTime: recurTime,
      ),
    );
    widget.onCreate(alarmInstance);

  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Enter Timer Name',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hour Picker
              Column(
                children: [
                  const Text('Hours'),
                  NumberPicker(
                    value: hours,
                    minValue: 0,
                    maxValue: 23,
                    onChanged: (value) {
                      setState(() {
                        hours = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(width: 30),
              // Minute Picker
              Column(
                children: [
                  const Text('Minutes'),
                  NumberPicker(
                    value: minutes,
                    minValue: 0,
                    maxValue: 59,
                    onChanged: (value) {
                      setState(() {
                        minutes = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _createTimer,
              child: const Text('Create'),
            ),
          ),
        ],
      ),
    );
  }
}
