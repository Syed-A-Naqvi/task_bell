import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../settings/settings_view.dart';
import 'package:collection/collection.dart';

import 'alarm_instance.dart';

class AlarmFolder extends StatefulWidget implements Comparable {

  // AlarmFolder info
  String id;
  String name;
  int position;
  AlarmFolder({
    required this.id,
    required this.name,
    required this.position,
    super.key,
  });

  // Generic settings
  double containerHeight = 50;
  double childIndent = 40;

  // Keep track of subfolders, folders should also not be alarms, so keep them separate
  HeapPriorityQueue<AlarmFolder> subfolders = HeapPriorityQueue<AlarmFolder>();
  
  // Keep track of alarms contained within the folder
  HeapPriorityQueue<AlarmInstance> alarms = HeapPriorityQueue<AlarmInstance>();
  
  @override
  State<StatefulWidget> createState() => _AlarmFolderState();
  
  @override
  int compareTo(other) {
    return position.compareTo(other.position);
  }

}

class _AlarmFolderState extends State<AlarmFolder> {

  bool _expanded = false;

  // TabController _tabController = 

  Icon icon = const Icon(Icons.expand_less);

  void _toggleExpansion() {
    _expanded = !_expanded;
    icon = !_expanded ? const Icon(Icons.expand_less) : const Icon(Icons.expand_more);
    setState((){});
  }

  void _createNewAlarm(AlarmFolder folder, AlarmInstance alarm) {
    folder.alarms.add(alarm);
  }

  void _createNewFolder() {
    if (_nameController.text.isEmpty) {
      showDialog(context: context, builder: (context) => const AlertDialog(
        title: Text("Invalid name"),
      ));
    }

    AlarmFolder subFolder = AlarmFolder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      position: widget.subfolders.length,
    );

    debugPrint("Before ${widget.name}");
    debugPrint(widget.subfolders.toList().toString());
    widget.subfolders.add(subFolder);

    setState((){});

    debugPrint("Created new folder");
    debugPrint(widget.subfolders.toList().toString());
    Navigator.of(context).pop();
  }

  void addNewAlarmFolder() {
    showDialog(
      context: context,
      builder: (context) => DefaultTabController(
        length: 2,
        child: Dialog(
          child: SizedBox(
            width: 200,
            height: 250,
            child: Column(
              children: [
              _buildTabBar(context),
              _buildTabView(),
              ],
            ),
          ),
        ),
      ),
    );

  }

  Widget _buildTabBar(BuildContext context) {
  return const TabBar(
    tabs: [
      Tab(icon: Icon(Icons.alarm)),
      Tab(icon: Icon(Icons.folder)),
    ],
  );
}

final TextEditingController _nameController = TextEditingController();
final TextEditingController _alarmTimeController = TextEditingController();

Widget _buildTabView() {
  return Expanded(child: Padding(
    padding: const EdgeInsets.all(10),
    child: TabBarView(
    children: [
      Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Enter Alarm Name',
                  ),
                controller: _nameController,
                )
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Enter Alarm Time',
                  ),
                controller: _alarmTimeController,
                )
              ),
            ],
          ),
          Expanded(child: Container(),),
          Row(
            children: [
              Expanded(child:Container()),
              TextButton(
                child: const Text("ADD"),
                onPressed: (){},
              )
            ],
          )
        ],
      ),

      // Create Folder
      Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Enter Folder Name',
                  ),
                controller: _nameController,
                )
              ),
            ],
          ),
          Expanded(child: Container(),),
          Row(
            children: [
              Expanded(child:Container()),
              TextButton(
                onPressed: _createNewFolder,
                child: const Text("ADD"),
              )
            ],
          )
        ],
      ),
    ],
  )));
}

  @override
  Widget build(BuildContext context) {
    
    return Column(
      // mainAxisAlignment: MainAxisAlignment.end,
      // crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: icon,
              onPressed: _toggleExpansion,
            ),
            Text(widget.name),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: addNewAlarmFolder,
                
            ),
            Expanded(child: Container()),
            const Padding(
              padding: EdgeInsets.fromLTRB(0,0,10,0),
              child: Icon(Icons.folder),
            ),
          ]
        ),
        Visibility(
          visible: _expanded,
          child: Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(widget.childIndent,0,0,0),
              // child: ListView(
              //   children: widget.subfolders.toList()
              // )
              child: ListView.builder(
                itemCount: widget.subfolders.length + widget.alarms.length,
                itemBuilder: (context, index) {

                  List<AlarmFolder> folders = widget.subfolders.toList();
                  List<AlarmInstance> alarms = widget.alarms.toList();

                  Widget child;
                  if (index < widget.subfolders.length) {
                    child = folders[index];
                  } else {
                    child = alarms[index - folders.length];
                  }

                  return GestureDetector(
                    onLongPress: (){ debugPrint("long pressed the item, show edit options"); },
                    child: child
                  );
                }
                )
            ),
          )
        ),
        
      ],
    );
  }
  
}