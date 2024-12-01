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
      debugPrint("alarm instance is null; this is bad unless an alarm was just deleted");
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
        debugPrint("Next occur was null when attempting to reschedule alarm $id");
        return;
      }


      // if isActive is false, assume it was toggled off and stop
      if (!alarmInstance.isActive) {
        debugPrint("is active was false; assuming alarm was toggled off; cancelling rescheduling");
        return;
      }

      AlarmSettings newAlarmSettings = alarmInstance.alarmSettings.copyWith(dateTime: nextOccur);

      AlarmInstance newAlarmInstance = AlarmInstance(
        name: alarmInstance.name,
        alarmSettings: newAlarmSettings,
        recur: alarmInstance.recur,
        parentId: alarmInstance.parentId,
        isActive: alarmInstance.isActive,
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

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(MyApp(settingsController: settingsController));
}
