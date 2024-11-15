import 'package:flutter/material.dart';
import '../settings/settings_view.dart';
import '../alarm/alarm_folder.dart';
import '../storage/task_bell_database.dart';
import '../alarm/alarm_instance.dart';
import '../alarm/helpers/alarm_or_folder.dart';

class AlarmClockPage extends StatefulWidget {
  const AlarmClockPage({super.key});

  @override
  AlarmClockPageState createState() => AlarmClockPageState();
}

class AlarmClockPageState extends State<AlarmClockPage> {

  // database instance
  TaskBellDatabase tDB = TaskBellDatabase();
  // items to be displayed on the main page
  List<Widget> items = [];

  // maintains list of elements to display
  List<AlarmFolder> topLevelFolders = [];
  List<AlarmInstance> topLevelAlarms = [];
  // sort folders and items in a custom way
  int compareFolders(AlarmFolder a, AlarmFolder b) {
    return a.position.compareTo(b.position);
  }
  int compareAlarms(AlarmInstance a, AlarmInstance b) {
    return a.alarmSettings.dateTime.millisecondsSinceEpoch
    .compareTo(b.alarmSettings.dateTime.millisecondsSinceEpoch);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    topLevelFolders = await tDB.getAllChildFolders('-1');
    topLevelFolders.sort(compareFolders);
    debugPrint('Fetched ${topLevelFolders.length} folders');
    topLevelAlarms = await tDB.getAllChildAlarms('-1');
    topLevelAlarms.sort(compareAlarms);
    debugPrint('Fetched ${topLevelAlarms.length} alarms');
    setState(() {
      items = [...topLevelFolders, ...topLevelAlarms];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Clock'),
        actions: [
          IconButton(
            onPressed: () async {
              for (var i in items) {
                if (i is AlarmFolder) {
                  await tDB.deleteFolder(i.id);
                } else if (i is AlarmInstance){
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
              return AlarmOrFolderDialog(
                parentId: '-1', // Provide the necessary parentId
                folderPos: items.length, // Provide the necessary folderPos
                onCreateAlarm: (alarmInstance) async {
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
