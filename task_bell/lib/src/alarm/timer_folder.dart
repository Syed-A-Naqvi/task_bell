import 'package:flutter/material.dart';
import 'package:task_bell/src/alarm/alarm_instance.dart';
import 'helpers/timer_or_folder.dart';
import '../alarm/timer_instance.dart';
import 'alarm_folder.dart';

class TimerFolder extends AlarmFolder {

  const TimerFolder({
    required super.id,
    required super.parentId,
    required super.name,
    required super.position,
    super.key
  });

  @override
  State<StatefulWidget> createState() => TimerFolderState();
}

class TimerFolderState extends AlarmFolderState {

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
      alarms.add(item as TimerInstance);
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
            alarms.add(alarmInstance as TimerInstance);
          });
        },
        onCreateFolder: (folder) async {
          await tDB.insertFolder(folder);
          setState(() {
            subfolders.add(folder as TimerFolder);
          });
        },
      ),
    );
  }
}