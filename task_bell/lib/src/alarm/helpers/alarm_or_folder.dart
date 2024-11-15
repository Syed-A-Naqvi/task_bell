// create_alarm_or_folder_dialog.dart
import 'package:flutter/material.dart';
import 'alarm_dialog.dart';
import 'folder_dialog.dart';
import '../alarm_instance.dart';
import '../alarm_folder.dart';

class AlarmOrFolderDialog extends StatefulWidget {
  
  final int parentId;
  final int folderPos;
  final ValueChanged<AlarmInstance> onCreateAlarm;
  final ValueChanged<AlarmFolder> onCreateFolder;

  const AlarmOrFolderDialog({
    required this.onCreateAlarm,
    required this.onCreateFolder,
    required this.parentId,
    this.folderPos = 0,
    super.key
  });

  @override
  AlarmOrFolderDialogState createState() => AlarmOrFolderDialogState();
}

class AlarmOrFolderDialogState extends State<AlarmOrFolderDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  void _closeDialog() {
    Navigator.of(context).pop();
  }

  void _onCreateAlarm(AlarmInstance alarmInstance) {
    widget.onCreateAlarm(alarmInstance);
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
                  Tab(icon: Icon(Icons.alarm), text: 'Alarm'),
                  Tab(icon: Icon(Icons.folder), text: 'Folder'),
                ],
              ),
              Flexible(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Wrap each tab content in a SingleChildScrollView
                    SingleChildScrollView(
                      child: AlarmDialog(
                        parentId: widget.parentId,
                        onCreate: _onCreateAlarm,
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