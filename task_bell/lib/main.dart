import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/alarm/alarm_instance.dart';
import 'src/alarm/recurrence/relative_recur.dart';
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'package:alarm/alarm.dart';

import 'src/storage/task_bell_database.dart';

void main() async {
  // Set up the SettingsController, which will glue user settings to multiple
  // Flutter Widgets.
  final settingsController = SettingsController(SettingsService());

  final TaskBellDatabase tDB = TaskBellDatabase();

  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  // Initialize alarm event handler
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();

  Alarm.updateStream.stream.listen((id) async {
    debugPrint("update stream output: ${id.toString()}");
    // _ is the alarm id

    // check if its not currently ringing, and if the scheduled time is in the past
    // if so, check to see if its a recurring alarm, if so, reschedule it to next occur
    
    // once an alarm is dismissed, ID is removed. So we should get the time of alarm from the DB

    // make sure the alarm id is good
    AlarmInstance? alarmInstance = await tDB.getAlarm(id);
    if (alarmInstance == null) {
      debugPrint("alarm instance is null for some reason. Probably quite bad");
      return;
    }

    // if the alarm exists according to Alarm, we want to discard since it hasn't been dismissed yet
    // if (!await Alarm.isRinging(id) && Alarm.getAlarm(id)!.dateTime.isBefore(DateTime.now())) {
    if (Alarm.getAlarm(id) == null) {

      // check if its recurring or not

      // check if its non recurring. If not, update DB to indicate it is off now
      if (alarmInstance.recur is RelativeRecur) {
        tDB.updateAlarm(id, {"isactive": 0});
        debugPrint("Non recurring alarm went off, not rescheduling and updating DB");
        return;
      }

      // alarm must be recurring at this point. Update AlarmInstance, AlarmSettings, and Database
      DateTime? nextOccur = alarmInstance.recur.getNextOccurrence(DateTime.now());

      if (nextOccur == null) {
        debugPrint("Next occur was null when attempting to reschedule alarm ${id}");
        return;
      }

      AlarmSettings newAlarmSettings = alarmInstance.alarmSettings.copyWith(dateTime: nextOccur);

      AlarmInstance newAlarmInstance = AlarmInstance(
        name: alarmInstance.name,
        alarmSettings: newAlarmSettings,
        recur: alarmInstance.recur,
        parentId: alarmInstance.parentId,
      );

      tDB.updateAlarm(id, newAlarmInstance.toMap());
      bool success = await Alarm.set(alarmSettings: newAlarmSettings);

      if (success) {
        debugPrint("Rescheduled alarm for ${nextOccur.toString()}");
      } else {
        debugPrint("Something went wrong when rescheduling the alarm. Alarm.set returned false");
      }
      
    }
  });

  // Alarm.ringStream.stream.listen((_) async {
  //   debugPrint("LISTENER: ${_.toString()}");
  //   debugPrint("WENT OFF AT ${DateTime.now()}");

  //   AlarmInstance? alarmInstance = await tDB.getAlarm(_.id);

  //   if (alarmInstance == null) {
  //     debugPrint("current ringing alarm doesn't exist in the database");
  //   } else if (alarmInstance.recur is RelativeRecur) {
  //     // This is a timer going off, so toggle it off
  //     tDB.updateAlarm(_.id, {"isactive": 0});
  //     debugPrint("Non recurring alarm went off, not rescheduling and updating DB");
  //   } else {
  //     // this is a recurring alarm, so toggle it back on
  //     // get next occurence from current time
  //     DateTime? nextOccur = alarmInstance.recur.getNextOccurrence(DateTime.now());
  //     if (nextOccur != null) {
  //       // need to make a new alarmInstance because everything is final
  //       // also means we need to make a new alarmSettings
  //       // then update value in the DB 
  //       // AlarmSettings newAlarmSettings = alarmInstance.alarmSettings.copyWith(dateTime: nextOccur);
  //       // AlarmInstance newAlarmInstance = AlarmInstance(
  //       //   name: alarmInstance.name, 
  //       //   alarmSettings: newAlarmSettings, 
  //       //   recur: alarmInstance.recur, 
  //       //   parentId: alarmInstance.parentId
  //       // );
        
  //       // Alarm.set(alarmSettings: newAlarmInstance.alarmSettings);
  //       // tDB.updateAlarm(_.id, newAlarmInstance.toMap());

  //       debugPrint("rescheduled recurring alarm for ${nextOccur.toString()}");
  //     } else {
  //       debugPrint("next occur was null for some reason, unable to reschedule alarm");
  //     }
        
  //     debugPrint("Is this not being reached ???");
  //   }

  // });

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(MyApp(settingsController: settingsController));
}
