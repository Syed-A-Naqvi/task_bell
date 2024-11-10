import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import '../settings/settings_view.dart';
import '../alarm/alarm_folder.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class AlarmClockPage extends StatefulWidget {
  const AlarmClockPage({super.key});

  @override
  _AlarmClockPageState createState() => _AlarmClockPageState();
}


class _AlarmClockPageState extends State<AlarmClockPage> {

  AlarmFolder defaultFolder = AlarmFolder(
    id: "0",
    name: "default",
    position: 0,
  );

  SpeedDial _buildSpeedDial() {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      visible: true,
      children: [
        SpeedDialChild(
          child: Icon(Icons.access_alarm),
          onTap: () {debugPrint("alarm pressed"); },
          label: "new alarm",
        ),
        SpeedDialChild(
          child: Icon(Icons.folder),
          onTap: () { debugPrint(defaultFolder.subfolders.toList().toString()); },
          label: "new folder",
        ),
      ]
    );
  }

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
      // floatingActionButton: _buildSpeedDial(),
    );
  }
}