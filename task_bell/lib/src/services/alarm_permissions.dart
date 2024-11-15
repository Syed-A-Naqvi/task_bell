import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AlarmPermissions {
  static void checkNotificationPermission() async {
    final status = await Permission.notification.status;

    if (status.isDenied) {
      debugPrint("missing permission for notifications, requesting");
      final result = await Permission.notification.request();
      debugPrint("Result: ${result.isGranted}");
    }
  }

  static void checkExternalStoragePermission() async {
    final status = await Permission.storage.status;
    if (status.isDenied) {
      final result = await Permission.storage.request();
      debugPrint("was missing perm for storage, user set to ${result.isGranted}");
    }
  }

  static void checkExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isDenied) {
      final result = await Permission.scheduleExactAlarm.request();
      debugPrint("was missing perm for exact alarm, user set to ${result.isGranted}");
    }
  }
}