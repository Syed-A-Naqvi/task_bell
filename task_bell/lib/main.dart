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

  Alarm.ringStream.stream.listen((_) async {
    debugPrint("LISTENER: ${_.toString()}");
    debugPrint("WENT OFF AT ${DateTime.now()}");

    AlarmInstance? alarmInstance = await tDB.getAlarm(_.id);

    if (alarmInstance == null) {
      debugPrint("current ringing alarm doesn't exist in the database");
    } else if (alarmInstance.recur is RelativeRecur) {
      // This is a timer going off, so toggle it off
      tDB.updateAlarm(_.id, {"isactive": false});
    }

  });

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(MyApp(settingsController: settingsController));
}
