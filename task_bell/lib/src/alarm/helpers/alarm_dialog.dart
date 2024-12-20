// create_alarm_dialog.dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter/services.dart';
import '../../settings/settings_global_references.dart';
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

  // Need this for setting correct placeholder info in case of editing alarms; defaults to current time of day
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
      builder: (BuildContext context, Widget? child) {
        // This makes sure it uses the systems preference for 12h or 24h format
        // requires app restart for format change to take effect
        return MediaQuery(
          data: MediaQuery.of(context),
          child: child!,
        );
      },
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
          title: Text(AppLocalizations.of(context)!.missingInformation,
            style: TextStyle(fontSize: SettingGlobalReferences.defaultFontSize.toDouble())),
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

    // Create a complete AlarmInstance / AlarmSettings
    AlarmInstance alarmInstance = AlarmInstance(
      name: nameController.text,
      parentId: widget.parentId,
      isActive: true,
      alarmSettings: AlarmSettings(
        id: (DateTime.now().millisecondsSinceEpoch ~/ 100) % 2147483647,
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
            inputFormatters: [
              LengthLimitingTextInputFormatter(SettingGlobalReferences.maxChars),
            ],
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
                : '${AppLocalizations.of(context)!.selectedTime}${recurTime!.hour.toString().padLeft(2,'0')}:${recurTime!.minute.toString().padLeft(2,'0')}',
                style: TextStyle(fontSize: SettingGlobalReferences.defaultFontSize.toDouble())),
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _createAlarm,
              child: widget.namePrefill.isEmpty ? 
                Text(AppLocalizations.of(context)!.create, style: TextStyle(fontSize: SettingGlobalReferences.defaultFontSize.toDouble())) : 
                Text(AppLocalizations.of(context)!.update, style: TextStyle(fontSize: SettingGlobalReferences.defaultFontSize.toDouble())), 
            ),
          ),
        ],
      ),
    );
  }
}