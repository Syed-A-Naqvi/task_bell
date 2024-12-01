// create_alarm_or_folder_dialog.dart
import 'package:flutter/material.dart';
import 'timer_dialog.dart';
import 'folder_dialog.dart';
import '../alarm_instance.dart';
import '../alarm_folder.dart';
import '../timer_folder.dart';
import '../timer_instance.dart';

class TimerOrFolderDialog extends StatefulWidget {
  
  final int parentId;
  final int folderPos;
  final ValueChanged<AlarmInstance> onCreateTimer;
  final ValueChanged<AlarmFolder> onCreateFolder;
  final bool disableTimerTab;
  final bool disableFolderTab;

  const TimerOrFolderDialog({
    required this.onCreateTimer,
    required this.onCreateFolder,
    required this.parentId,
    this.disableTimerTab = false,
    this.disableFolderTab = false,
    this.folderPos = 0,
    super.key
  });

  @override
  TimerOrFolderDialogState createState() => TimerOrFolderDialogState();
}

class TimerOrFolderDialogState extends State<TimerOrFolderDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Tab> tabList = [];
  List<Widget> tabViewList = [];

  void _closeDialog() {
    Navigator.of(context).pop();
  }

  void _onCreateTimer(AlarmInstance alarmInstance) {
    TimerInstance timerInstance = TimerInstance(
      name: alarmInstance.name,
      alarmSettings: alarmInstance.alarmSettings,
      recur: alarmInstance.recur,
      parentId: alarmInstance.parentId);

    widget.onCreateTimer(timerInstance);
    _closeDialog();
  }

  void _onCreateFolder(AlarmFolder folder) {
    TimerFolder timerFolder = TimerFolder.fromMap(folder.toMap());
    widget.onCreateFolder(timerFolder);
    _closeDialog();
  }

  @override
  void initState() {
    super.initState();

    int length = 0;

    if (!widget.disableTimerTab) {
      tabList.add(const Tab(icon: Icon(Icons.timer), text: 'Timer'));
      tabViewList.add(SingleChildScrollView(
          child: TimerDialog(
            parentId: widget.parentId,
            onCreate: _onCreateTimer,
          ),
        ),
      );

      length++;
    }

    if (!widget.disableFolderTab) {
      tabList.add(const Tab(icon: Icon(Icons.folder), text: 'Folder'));
      tabViewList.add(
        SingleChildScrollView(
          child: FolderDialog(
            parentId: widget.parentId,
            position: widget.folderPos,
            onCreate: _onCreateFolder,
          ),
        ),
      );
    }

    _tabController = TabController(length: length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Adjust the padding as needed
        child: SizedBox(
          width: 300, // Adjust as needed
          height: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                controller: _tabController,
                tabs: tabList,
              ),
              Flexible(
                child: TabBarView(
                  controller: _tabController,
                  children: tabViewList,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
