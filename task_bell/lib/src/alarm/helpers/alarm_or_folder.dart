// create_alarm_or_folder_dialog.dart
import 'package:flutter/material.dart';
import 'alarm_dialog.dart';
import 'folder_dialog.dart';
import '../alarm_instance.dart';
import '../alarm_folder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AlarmOrFolderDialog extends StatefulWidget {
  
  final int parentId;
  final int folderPos;
  final ValueChanged<AlarmInstance> onCreateAlarm;
  final ValueChanged<AlarmFolder> onCreateFolder;
  final bool disableAlarmTab;
  final bool disableFolderTab;
  final String namePrefill;
  final int activeDays;
  final TimeOfDay initialTime;

  const AlarmOrFolderDialog({
    required this.onCreateAlarm,
    required this.onCreateFolder,
    required this.parentId,
    this.disableAlarmTab = false,
    this.disableFolderTab = false,
    this.folderPos = 0,
    this.namePrefill = "",
    this.activeDays = 0,
    this.initialTime = const TimeOfDay(hour: -1, minute: -1),
    super.key
  });

  @override
  AlarmOrFolderDialogState createState() => AlarmOrFolderDialogState();
}

class AlarmOrFolderDialogState extends State<AlarmOrFolderDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Tab> tabList = [];
  List<Widget> tabViewList = [];

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

    int length = 0;

    if (!widget.disableAlarmTab) {
      tabViewList.add(
        SingleChildScrollView(
          child: AlarmDialog(
            parentId: widget.parentId,
            onCreate: _onCreateAlarm,
            namePrefill: widget.namePrefill,
            activeDays: widget.activeDays,
            initialTime: widget.initialTime,
          ),
        ),
      );

      length++;
    }

    if (!widget.disableFolderTab) {
      
      tabViewList.add(
        SingleChildScrollView(
          child: FolderDialog(
            parentId: widget.parentId,
            position: widget.folderPos,
            namePrefill: widget.namePrefill,
            onCreate: _onCreateFolder,
          ),
        ),
      );

      length++;
    }


    _tabController = TabController(length: length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {

    // Needed to move this out of InitState. Cannot get localizations before initState completes.
    if (!widget.disableAlarmTab) {
      tabList.add(Tab(icon: const Icon(Icons.alarm), text: AppLocalizations.of(context)!.alarm));
    }
    if (!widget.disableFolderTab) {
      tabList.add(Tab(icon: const Icon(Icons.folder), text: AppLocalizations.of(context)!.folder));
    }
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