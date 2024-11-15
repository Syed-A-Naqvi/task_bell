// create_alarm_or_folder_dialog.dart
import 'package:flutter/material.dart';
import 'timer_dialog.dart';
import 'folder_dialog.dart';
import '../alarm_instance.dart';
import '../alarm_folder.dart';

class TimerOrFolderDialog extends StatefulWidget {
  
  final String parentId;
  final int folderPos;
  final ValueChanged<AlarmInstance> onCreateTimer;
  final ValueChanged<AlarmFolder> onCreateFolder;

  const TimerOrFolderDialog({
    required this.onCreateTimer,
    required this.onCreateFolder,
    this.parentId = '-1',
    this.folderPos = 0,
    super.key
  });

  @override
  TimerOrFolderDialogState createState() => TimerOrFolderDialogState();
}

class TimerOrFolderDialogState extends State<TimerOrFolderDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  void _closeDialog() {
    Navigator.of(context).pop();
  }

  void _onCreateTimer(AlarmInstance alarmInstance) {
    widget.onCreateTimer(alarmInstance);
    _closeDialog();
  }

  void _onCreateFolder(AlarmFolder folder) {
    widget.onCreateFolder(folder);
    _closeDialog();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
                tabs: const [
                  Tab(icon: Icon(Icons.timer), text: 'Timer'),
                  Tab(icon: Icon(Icons.folder), text: 'Folder'),
                ],
              ),
              Flexible(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Wrap each tab content in a SingleChildScrollView
                    SingleChildScrollView(
                      child: TimerDialog(
                        parentId: widget.parentId,
                        onCreate: _onCreateTimer,
                      ),
                    ),
                    SingleChildScrollView(
                      child: FolderDialog(
                        parentId: widget.parentId,
                        position: widget.folderPos,
                        onCreate: _onCreateFolder,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
