import 'package:flutter/material.dart';
import '../settings/settings_view.dart';
import '../alarm/alarm_folder.dart';

class AlarmClockPage extends StatefulWidget {
  const AlarmClockPage({super.key});

  @override
  AlarmClockPageState createState() => AlarmClockPageState();
}

class AlarmClockPageState extends State<AlarmClockPage> {
  
  AlarmFolder defaultFolder = AlarmFolder(
    id: "0",
    name: "Alarms",
    position: 0,
  );

  List<dynamic> items = [];

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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () {
          // Add your onPressed code here!
          print("the button was pressed");
        },
        foregroundColor: Theme.of(context).colorScheme.surface,
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        child: const Icon(Icons.add),
      ),
    );
  }
}
