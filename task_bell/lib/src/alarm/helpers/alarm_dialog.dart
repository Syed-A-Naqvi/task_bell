// create_alarm_dialog.dart
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:task_bell/src/alarm/helpers/ringtone_service.dart';
import '../weekday_selector.dart';
import '../recurrence/week_recur.dart';
import '../alarm_instance.dart';

class AlarmDialog extends StatefulWidget {
  final String parentId;
  final ValueChanged<AlarmInstance> onCreate;

  const AlarmDialog({
    required this.onCreate,
    required this.parentId,
    super.key
  });

  @override
  AlarmDialogState createState() => AlarmDialogState();
}

class AlarmDialogState extends State<AlarmDialog> {
  final TextEditingController nameController = TextEditingController();
  int activeDays = 0;
  DateTime? recurTime;

  void _handleActiveDaysChanged(int newActiveDays) {
    setState(() {
      activeDays = newActiveDays;
    });
  }

  Future<void> _selectTime() async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null) {
      setState(() {
        recurTime = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          selectedTime.hour,
          selectedTime.minute,
        );
      });
    }
  }

  void _createAlarm() async {
    if (nameController.text.isEmpty || recurTime == null) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("Please provide all details"),
        ),
      );
      return;
    }

    String path = (await RingtoneService().getRingtones())[0];

    AlarmInstance alarmInstance = AlarmInstance(
      name: nameController.text,
      parentId: widget.parentId,
      key: Key((DateTime.now().millisecondsSinceEpoch.toString())),
      alarmSettings: AlarmSettings(
        id: (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 2147483647,
        dateTime: recurTime!,
        // assetAudioPath: "content://media/internal/audio/media/43", // Specify your asset audio path
        assetAudioPath: path,
        vibrate: true,
        loopAudio: true,
        volume: 1.0,
        volumeEnforced: false,
        fadeDuration: 3,
        warningNotificationOnKill: true,
        androidFullScreenIntent: true,
        notificationSettings: NotificationSettings(
          title: nameController.text,
          body: "Alarm at ${recurTime!.hour}:${recurTime!.minute}",
          stopButton: 'Stop the alarm',
          icon: 'notification_icon',
        ),
      ),
      recur: WeekRecur(
        activeDays: activeDays,
        recurTime: recurTime!,
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
              labelText: 'Enter Alarm Name',
            ),
          ),
          const SizedBox(height: 30),
          WeekdaySelector(
            activeDays: activeDays,
            onActiveDaysChanged: _handleActiveDaysChanged,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _selectTime,
            child: Text(recurTime == null
                ? 'Select Time'
                : 'Selected Time: ${recurTime!.hour}:${recurTime!.minute}'),
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _createAlarm,
              child: const Text('Create'),
            ),
          ),
        ],
      ),
    );
  }
}