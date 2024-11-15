import 'package:flutter/material.dart';
import 'package:task_bell/src/alarm_clock/alarm_clock_page.dart';
import '../settings/settings_view.dart';
import '../alarm/alarm_folder.dart';
import '../alarm/helpers/timer_or_folder.dart';
// import '../alarm/timer_instance.dart';
import '../alarm/alarm_instance.dart';

class TimerPage extends AlarmClockPage {
  const TimerPage({super.key});

  @override
  AlarmClockPageState createState() => TimerPageState();
}

class TimerPageState extends AlarmClockPageState {


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    topLevelFolders = await tDB.getAllChildFolders('-2');
    topLevelFolders.sort(compareFolders);
    debugPrint('Fetched ${topLevelFolders.length} folders');
    topLevelAlarms = await tDB.getAllChildAlarms('-2');
    topLevelAlarms.sort(compareAlarms);
    debugPrint('Fetched ${topLevelAlarms.length} timers');
    setState(() {
      items = [...topLevelFolders, ...topLevelAlarms];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer'),
        actions: [
          IconButton(
            onPressed: () async {
              for (var i in items) {
                if (i is AlarmFolder) {
                  await tDB.deleteFolder(i.id);
                } else if (i is AlarmInstance) {
                  await tDB.deleteAlarm(i.alarmSettings.id);
                }
              }
              _loadData();
            },
            icon: const Icon(Icons.delete) ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      body: ListView(
        children: items,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return TimerOrFolderDialog(
                parentId: '-2', // Provide the necessary parentId
                folderPos: items.length, // Provide the necessary folderPos
                onCreateTimer: (alarmInstance) async {
                  await tDB.insertAlarm(alarmInstance);
                  topLevelAlarms.add(alarmInstance);
                  topLevelAlarms.sort(compareAlarms);
                  items = [...topLevelFolders, ...topLevelAlarms];
                  setState(() {});
                },
                onCreateFolder: (folder) async {
                  await tDB.insertFolder(folder);
                  topLevelFolders.add(folder);
                  topLevelFolders.sort(compareFolders);
                  items = [...topLevelFolders, ...topLevelAlarms];
                  setState(() {});
                },
              );
            },
          );
        },
        foregroundColor: Theme.of(context).colorScheme.surface,
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        child: const Icon(Icons.add),
      ),
    );
  }
}