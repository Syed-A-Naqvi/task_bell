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

  static TimerFolder fromMap(Map<String, dynamic> map) {
    return TimerFolder(
      id: map["id"],
      parentId: map['parentId'],
      name: map["name"],
      position: map["position"],
    );
  }

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
      item = TimerFolder.fromMap(item.toMap());
      subfolders.add(item);
    }
    List<AlarmInstance> timersList = await tDB.getAllChildAlarms(widget.id);
    for (var item in timersList) {
      item = TimerInstance(
        name: item.name,
        alarmSettings: item.alarmSettings,
        recur: item.recur,
        parentId: item.parentId
      );
      alarms.add(item);
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