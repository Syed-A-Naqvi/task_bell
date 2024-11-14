// create_alarm_or_folder_dialog.dart
import 'package:flutter/material.dart';
import 'alarm_dialog.dart';
import 'folder_dialog.dart';
import '../alarm_instance.dart';
import '../alarm_folder.dart';

class AlarmOrFolderDialog extends StatefulWidget {
  
  final String parentId;
  final int folderPos;
  final ValueChanged<AlarmInstance> onCreateAlarm;
  final ValueChanged<AlarmFolder> onCreateFolder;

  const AlarmOrFolderDialog({
    required this.onCreateAlarm,
    required this.onCreateFolder,
    this.parentId = '-1',
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
    return AlertDialog(
      title: const Text('Add New Item'),
      content: SizedBox(
        width: double.maxFinite,
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
            SizedBox(
              height: 300, // Adjust as needed
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Alarm Creation Tab
                  AlarmDialog(
                    parentId: widget.parentId,
                    onCreate: _onCreateAlarm,
                  ),
                  // Folder Creation Tab
                  FolderDialog(
                    parentId: widget.parentId,
                    position: widget.folderPos,
                    onCreate: _onCreateFolder,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
