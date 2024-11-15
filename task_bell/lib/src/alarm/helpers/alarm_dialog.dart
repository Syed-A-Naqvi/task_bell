// create_alarm_dialog.dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
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
    
    String path;

    // hack together a file picker, this is temporary; I guess this isn't temporary
    File? file = await FilePicker.platform.pickFiles().then((FilePickerResult? result) async {
      if (result == null) {
        return null;
      }

      final PlatformFile selectedFile = result.files.single;

      if (selectedFile.path == null) {
        return null;
      }

      final File file = File(selectedFile.path!);
      return file;

    });

    if (file == null) {
      path = "";
    } else {
      path = file.path;
    }

    AlarmInstance alarmInstance = AlarmInstance(
      name: nameController.text,
      parentId: widget.parentId,
      key: Key((DateTime.now().millisecondsSinceEpoch.toString())),
      alarmSettings: AlarmSettings(
        id: (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 2147483647,
        dateTime: recurTime!,
        assetAudioPath: path,
        vibrate: true,
        loopAudio: true,
        volume: null,
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