import 'package:alarm/alarm.dart';
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
  void createNewAlarm() async {
    if (nameController.text.isEmpty) {
      debugPrint("Invalid name provided");
      showDialog(context: context, builder: (context) => const AlertDialog(
        title: Text("Invalid name"),
      ));

      return;
    }

    TimeOfDay? selectedTime24Hour = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 47),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    // user closed dialog, did not select time
    if (selectedTime24Hour == null) {
      return;
    }

    Navigator.of(context).pop();

    debugPrint(selectedTime24Hour.hour.toString());

    DateTime recurTime = DateTime(
      DateTime.now().year, 
      DateTime.now().month,
      DateTime.now().day,
      selectedTime24Hour.hour,
      selectedTime24Hour.minute,  
    );

    widget.alarms.add(AlarmInstance(
      name: nameController.text, 
      alarmSettings: AlarmSettings(
        id: (DateTime.now().millisecondsSinceEpoch ~/1000) % 2147483647, 
        dateTime: recurTime,
        assetAudioPath: "", 
        vibrate: true,
        androidFullScreenIntent: true,
        notificationSettings: NotificationSettings(
          title: nameController.text,
          body: "Alarm triggered at ${recurTime.hour}:${recurTime.minute}",
          stopButton: 'Stop the alarm',
          icon: 'notification_icon',
        ),
      ),
      recur: RelativeRecur(
        initTime: DateTime.now(),
        recurTime: recurTime
      )
    ),);

    nameController.text = "";

    setState((){});
  }
}