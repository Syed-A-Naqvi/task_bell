import 'package:flutter/material.dart';
import '../settings/settings_view.dart';

class AlarmClockPage extends StatelessWidget {
  const AlarmClockPage({super.key});

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
      body: const Center(
        child: Text('Alarm Clock Page'),
      ),
    );
  }
}