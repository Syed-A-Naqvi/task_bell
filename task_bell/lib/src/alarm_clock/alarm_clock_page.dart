import 'package:alarm/alarm.dart';
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
    name: "default",
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
      // body: Center(
      //   // child: Text('Alarm Clock Page'),
      //   child: 
      // ),
      body: defaultFolder,
      floatingActionButton: FloatingActionButton(
        onPressed: () async { debugPrint("stopall"); await Alarm.stopAll(); },
        tooltip: "New Alarm",
        child: const Icon(Icons.add),
      ),
    );
  }
}