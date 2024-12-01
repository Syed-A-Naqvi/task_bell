// create_alarm_dialog.dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import '../weekday_selector.dart';
import '../recurrence/week_recur.dart';
import '../alarm_instance.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AlarmDialog extends StatefulWidget {
  final int parentId;
  final ValueChanged<AlarmInstance> onCreate;
  final String namePrefill;
  final int activeDays;
  final TimeOfDay initialTime;

  const AlarmDialog({
    required this.onCreate,
    required this.parentId,
    this.namePrefill = "",
    this.activeDays = 0,
    this.initialTime = const TimeOfDay(hour: -1, minute: -1),
    super.key
  });

  @override
  AlarmDialogState createState() => AlarmDialogState();
}

class AlarmDialogState extends State<AlarmDialog> {
  late final TextEditingController nameController = TextEditingController(text: widget.namePrefill);
  late int activeDays = widget.activeDays;
  late DateTime? recurTime = widget.initialTime.hour < 0 ? null : DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          widget.initialTime.hour,
          widget.initialTime.minute,
        );
  late TimeOfDay initialTime = widget.initialTime.hour < 0 ? TimeOfDay.now() : widget.initialTime;

  void _handleActiveDaysChanged(int newActiveDays) {
    setState(() {
      activeDays = newActiveDays;
    });
  }

  Future<void> _selectTime() async {

    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
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
      debugPrint(recurTime.toString());
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.missingInformation),
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

    WeekRecur recur = WeekRecur(activeDays: activeDays, recurTime: recurTime!);

    AlarmInstance alarmInstance = AlarmInstance(
      name: nameController.text,
      parentId: widget.parentId,
      isActive: true,
      alarmSettings: AlarmSettings(
        id: (DateTime.now().millisecondsSinceEpoch ~/ 100) % 2147483647,
        // dateTime: recurTime!,
        dateTime: recur.getNextOccurrence(DateTime.now())!,
        assetAudioPath: path,
        vibrate: true,
        loopAudio: true,
        volume: null,
        volumeEnforced: false,
        fadeDuration: 3,
        warningNotificationOnKill: true,
        androidFullScreenIntent: true,
        notificationSettings: NotificationSettings(
          title: "${AppLocalizations.of(context)!.notificationTitle}${nameController.text}",
          body: AppLocalizations.of(context)!.notificationBody,
          stopButton: AppLocalizations.of(context)!.notificationDismiss,
          icon: 'notification_icon',
        ),
      ),
      recur: recur
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
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.enterAlarmName,
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
                ? AppLocalizations.of(context)!.selectTime
                : '${AppLocalizations.of(context)!.selectedTime}${recurTime!.hour}:${recurTime!.minute}'),
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _createAlarm,
              child: widget.namePrefill.isEmpty ? 
                Text(AppLocalizations.of(context)!.create) : 
                Text(AppLocalizations.of(context)!.update), 
            ),
          ),
        ],
      ),
    );
  }
}