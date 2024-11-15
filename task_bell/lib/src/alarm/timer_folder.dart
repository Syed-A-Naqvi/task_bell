import 'package:flutter/material.dart';
import 'helpers/timer_or_folder.dart';
import 'package:collection/collection.dart';
import '../alarm/timer_instance.dart';
import 'alarm_folder.dart';
import 'alarm_instance.dart';

class TimerFolder extends AlarmFolder {

  const TimerFolder({super.key, required super.id, required super.name, required super.position});

  @override
  State<StatefulWidget> createState() => TimerFolderState();
}

class TimerFolderState extends AlarmFolderState {

  // Keep track of subfolders and alarms
  HeapPriorityQueue<TimerFolder> tiemrSubfolders = HeapPriorityQueue<TimerFolder>();
  HeapPriorityQueue<TimerInstance> timers = HeapPriorityQueue<TimerInstance>();

  @override
  void initState(){
    super.initState();
    // Initialize the folder's children from the database here
    _loadData();
  }

  Future<void> _loadData() async {
    List<AlarmFolder> subfoldersList = await tDB.getAllChildFolders(widget.id);
    for (var item in subfoldersList) {
      subfolders.add(item as TimerFolder);
    }
    List<AlarmInstance> timersList = await tDB.getAllChildAlarms(widget.id);
    for (var item in timersList) {
      timers.add(item as TimerInstance);
    }
    setState(() {});
  }

  @override
  void addNewAlarmFolder() {
    showDialog(
      context: context,
      builder: (context) => TimerOrFolderDialog(
        parentId: widget.id,
        folderPos: subfolders.length,
        onCreateTimer: (alarmInstance) async {
          await tDB.insertAlarm(alarmInstance);
          setState(() {
            alarms.add(alarmInstance);
          });
        },
        onCreateFolder: (folder) async {
          await tDB.insertFolder(folder);
          setState(() {
            subfolders.add(folder);
          });
        },
      ),
    );
  }
}