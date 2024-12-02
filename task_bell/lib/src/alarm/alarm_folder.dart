import 'dart:async';

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'helpers/alarm_or_folder.dart';
import 'alarm_instance.dart';
import '../storage/task_bell_database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../settings/settings_global_references.dart';

// Each folder will need to pull all its children from the database upon initialization
// this should be implemented in the state's initstate logic
// the inline function passed to creation widgets' onCreate parameter will need to
  // 1. insert the newly created object into a local collection
  // 2. insert the newly created object into the sqflite db

class AlarmFolder extends StatefulWidget implements Comparable {
  // AlarmFolder info
  final int id;
  final int parentId;
  final String name;
  final int position;

  const AlarmFolder({
    required this.id,
    required this.name,
    required this.position,
    required this.parentId,
    super.key,
  });

  // Generic settings
  final double containerHeight = 50;
  final double childIndent = 30;
  
  @override
  State<StatefulWidget> createState() => AlarmFolderState();
  
  @override
  int compareTo(other) {
    return position.compareTo(other.position);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'name': name,
      'position': position,
    };
  }

  static AlarmFolder fromMap(Map<String, dynamic> map) {
    return AlarmFolder(
      id: map["id"],
      parentId: map['parentId'],
      name: map["name"],
      position: map["position"],
    );
  }
}

class AlarmFolderState extends State<AlarmFolder> {
  // database object
  TaskBellDatabase tDB = TaskBellDatabase();
  // Keep track of subfolders and alarms
  HeapPriorityQueue<dynamic> subfolders = HeapPriorityQueue<dynamic>();  
  HeapPriorityQueue<dynamic> alarms = HeapPriorityQueue<dynamic>();
 
  bool _expanded = false;
  Icon icon = const Icon(Icons.chevron_right);
  late String fakeName;
  bool deleted = false;

  double dragStartX = 0;
  double xOffset = 0;
  final double maxOffset = 40;

  @override
  void initState(){
    super.initState();
    // Initialize the folder's children from the database here
    _loadData();
    fakeName = widget.name;
  }

  Future<void> _loadData() async {
    List<AlarmFolder> subfoldersList = await tDB.getAllChildFolders(widget.id);
    subfolders.addAll(subfoldersList);
    List<AlarmInstance> alarmsList = await tDB.getAllChildAlarms(widget.id);
    alarms.addAll(alarmsList);
    setState(() {});    
  }

  void _toggleExpansion() {
    setState(() {
      _expanded = !_expanded;
      icon = _expanded ? const Icon(Icons.expand_more) : const Icon(Icons.chevron_right);
    });
  }

  // show user the dialog for creating a new alarm or folder
  void addNewAlarmFolder() {
    showDialog(
      context: context,
      builder: (context) => AlarmOrFolderDialog(
        parentId: widget.id,
        folderPos: subfolders.length,

        // add the alarm user creates to the list
        onCreateAlarm: (alarmInstance) async {
          await tDB.insertAlarm(alarmInstance);
          setState(() {
            alarms.add(alarmInstance);
          });
        },

        // add the folder user creates to the list
        onCreateFolder: (folder) async {
          await tDB.insertFolder(folder);
          setState(() {
            subfolders.add(folder);
          });
        },
      ),
    );
  }

  // Set the padding for each child of this widget
  List<Widget> indentChildren() {
    List<Widget> indented = [];

    final folders = subfolders.toList();
    final alarmsList = alarms.toList();

    for (AlarmFolder af in folders) {
      indented.add(
        Padding(
          // check if its the default list; if so don't indent
          padding: EdgeInsets.fromLTRB((af.parentId == -1) ? 0 : widget.childIndent, 0, 0, 0),
          child: af,
        ),
      );
    }
    for (AlarmInstance al in alarmsList) {
      indented.add(
        Padding(
          // check if its the default list; if so don't indent
          padding: EdgeInsets.fromLTRB((al.parentId == -1) ? 0 : widget.childIndent, 0, 0, 0),
          child: al,
        ),
      );
    }

    return indented;
  }

  // open modification of alarm or folder dialog prefilled with data for current alarm
  void openEditMenu() {
    HapticFeedback.mediumImpact();
    debugPrint("pressed ${widget.name}");

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlarmOrFolderDialog(
          parentId: -1, // Provide the necessary parentId
          folderPos: widget.position, // Provide the necessary folderPos
          disableAlarmTab: true,
          namePrefill: widget.name,
          onCreateAlarm: (alarmInstance){}, // do nothing. alarm tab is disabled
          onCreateFolder: (folder) async {
            // update folder name. Since its final, use fakeName to store changes until reload
            await tDB.updateFolder(widget.id, {"name": folder.name});
            fakeName = folder.name;
            setState((){});
          },
        );
      }
    );
  }

  @override
  void dispose() {
    if (deleted) {
      // can't do this unfortunately, throws huge error
      // don't think there is a way to get it to hide the snackbar when this widget is deleted
      // ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // if this widget gets deleted, and this folder is flagged for deletion, make sure it gets deleted
      tDB.deleteFolder(widget.id);
      
    }

    super.dispose();
  }

  

  @override
  Widget build(BuildContext context) {

    // hide the widget if its marked as deleted
    return Visibility(
      visible: !deleted,
      child: Stack(
        children: [
          Visibility(
            visible: xOffset >= maxOffset,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 10, 0),
              child: Icon(Icons.delete)
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(xOffset,0,0,0),

            child: GestureDetector(

              onLongPress: openEditMenu,
              
              // keep track of where the dragging starts; important for the animation
              onHorizontalDragStart: (details) {
                xOffset = 0;
                dragStartX = details.globalPosition.dx;
              },

              onHorizontalDragUpdate: (details) {
                // calculate the offset from where drag started
                // updates padding so the widget slides with the drag
                xOffset = details.globalPosition.dx - dragStartX;
                if (xOffset < 0) {
                  xOffset = 0;
                  // limit drag so it doesn't go off screen
                } else if (xOffset > maxOffset) {
                  xOffset = maxOffset;
                }
                setState((){});
              },

              onHorizontalDragEnd: (details) {
                
                if (details.globalPosition.dx - dragStartX > maxOffset) {
                  
                  // mark this widget as deleted and hide it
                  deleted = true;

                  // wait until after the snackbar expires before actually deleting the folder
                  // cannot easily undo the delete, so we don't; just delay it until user loses the option
                  Timer(const Duration(milliseconds: 4000), () {
                    if (!deleted) {
                      return;
                    }
                    // if it was deleted by the end of the duration, delete the folder
                    tDB.deleteFolder(widget.id);
                  });
                  
                  setState((){});
                  HapticFeedback.heavyImpact(); // haptic feedback when deleting

                  // Give user option to undo the delete through the snackbar
                  // don't actually delete until after this expires
                  var snackBar = SnackBar(
                    content: Text("${AppLocalizations.of(context)!.deleted} ${
                      AppLocalizations.of(context)!.quoteLeft}$fakeName${
                      AppLocalizations.of(context)!.quoteRight}",
                      style: TextStyle(
                        fontSize: SettingGlobalReferences.defaultFontSize.toDouble(),
                      ),),
                    action: SnackBarAction(label: AppLocalizations.of(context)!.undo, onPressed: (){
                      deleted = false;

                      setState((){});
                    }),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
                // do this regardless so undo delete isn't messed up
                xOffset = 0;
                dragStartX = 0;
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: [
                      IconButton(
                        icon: icon,
                        onPressed: _toggleExpansion,
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(0, 0, 8, 0),
                        child: Icon(Icons.folder),
                      ),
                      Text(fakeName,
                        style: TextStyle(fontSize: SettingGlobalReferences.defaultFontSize.toDouble())),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: addNewAlarmFolder,
                      ),
                      Expanded(child: Container()),
                    ],
                  ),
                ] + (_expanded ? indentChildren() : []),
              ),
            )
          ),
        ]
      )
    );
  }
}
