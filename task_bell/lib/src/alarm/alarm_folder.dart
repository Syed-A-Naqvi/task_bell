import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'helpers/alarm_or_folder.dart';
import 'alarm_instance.dart';
import '../storage/task_bell_database.dart';

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

  void addNewAlarmFolder() {
    showDialog(
      context: context,
      builder: (context) => AlarmOrFolderDialog(
        parentId: widget.id,
        folderPos: subfolders.length,
        onCreateAlarm: (alarmInstance) async {
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

  List<Widget> indentChildren() {
    List<Widget> indented = [];

    final folders = subfolders.toList();
    final alarmsList = alarms.toList();

    for (AlarmFolder af in folders) {
      indented.add(
        Padding(
          padding: EdgeInsets.fromLTRB((af.parentId == -1) ? 0 : widget.childIndent, 0, 0, 0),
          child: af,
        ),
      );
    }
    for (AlarmInstance al in alarmsList) {
      debugPrint("alarm isactive? : ${al.isActive}");
      indented.add(
        Padding(
          padding: EdgeInsets.fromLTRB((al.parentId == -1) ? 0 : widget.childIndent, 0, 0, 0),
          child: al,
        ),
      );
    }

    return indented;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        debugPrint("pressed ${widget.name}");

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlarmOrFolderDialog(
              parentId: -1, // Provide the necessary parentId
              folderPos: widget.position, // Provide the necessary folderPos
              disableAlarmTab: true,
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
              Text(fakeName),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: addNewAlarmFolder,
              ),
              Expanded(child: Container()),
            ],
          ),
        ] + (_expanded ? indentChildren() : []),
      ),
    );
  }
}
