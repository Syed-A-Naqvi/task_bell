import 'package:flutter/material.dart';
import 'alarm_folder.dart';
import 'helpers/timer_or_folder.dart';

class TimerFolder extends AlarmFolder {

  const TimerFolder({super.key, required super.id, required super.name, required super.position});

  @override
  State<StatefulWidget> createState() => TimerFolderState();
}

class TimerFolderState extends AlarmFolderState {

  @override
  void addNewAlarmFolder() {
    showDialog(
      context: context,
      builder: (context) => TimerOrFolderDialog(
        parentId: widget.id,
        folderPos: subfolders.length,
        onCreateTimer: (alarmInstance) {
          setState(() {
            alarms.add(alarmInstance);
          });
          // Insert alarmInstance into the database here
        },
        onCreateFolder: (folder) {
          setState(() {
            subfolders.add(folder);
          });
          // Insert folder into the database here
        },
      ),
    );
  }
}