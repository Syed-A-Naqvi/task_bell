import 'package:flutter/material.dart';
import '../settings/settings_view.dart';
import '../alarm/alarm_folder.dart';

class AlarmClockPage extends StatefulWidget {
  const AlarmClockPage({super.key});

  @override
  _AlarmClockPageState createState() => _AlarmClockPageState();
}


class _AlarmClockPageState extends State<AlarmClockPage> {

  AlarmFolder defaultFolder = AlarmFolder(
    id: "0",
    name: "Alarms",
    position: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Clock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      body: defaultFolder,
    );
  }
}