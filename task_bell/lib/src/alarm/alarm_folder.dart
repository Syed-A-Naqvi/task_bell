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

  void addNewAlarmFolder() {
    // showDialog(context: context, builder: (context) => Dialog(
    //   child: DefaultTabController(
    //     length: 2, 
    //     initialIndex: 0,
    //     child: child)
    // ));
    // showDialog(
    //   context: context,
    //   builder: (context) => DefaultTabController(
    //     length: 2,
    //     child: Dialog(
    //       child: Container(
    //         // width: 200,
    //         // height: 340,
    //         // child: Column(
    //         //   children: [
    //         //     // Expanded(child: _buildTabBar(context)),
    //         //     // Expanded(child: _buildTabView()),
    //         //   _buildTabBar(context),
    //         //   _buildTabView(),
    //         //   ],
    //         // ),
    //         child: _buildTabBar(context),
    //       ),
    //     ),
    //   ),
    // );
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: DefaultTabController(
          length: 2,
          // child: _buildTabBar(context)
          child: Column(
            children: [
              _buildTabBar(context),
              _buildTabView()
            ],
          )
        )
      )
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

final TextEditingController _alarmNameController = TextEditingController();
final TextEditingController _alarmTimeController = TextEditingController();

Widget _buildTabView() {
  
  if (true) {
    return const SizedBox(
      height: 100,
      child: TabBarView(
        children: [
          Text("3"),
          Text("2")
        ],
      )
    );
  }

  return TabBarView(
    children: [
      // Create Alarm
      // SizedBox(
      //   width: 100,
      //   height: 100,
      //   child: Text("Create Alarm :0"),
      // ),
      Column(
        children: [
          Text("Create Alarm?"),
          // Row(
          //   children: [
          //     // Text("Name: "),
          //     Expanded(
          //       child: TextFormField(
          //         decoration: const InputDecoration(
          //           border: UnderlineInputBorder(),
          //           labelText: 'Enter Alarm Name',
          //         ),
          //       controller: _alarmNameController,
          //       )
          //     ),
          //   ],
          // ),
          // Row(
          //   children: [
          //     // Text("Time: "),
          //     Expanded(
          //       child: TextFormField(
          //         decoration: const InputDecoration(
          //           border: UnderlineInputBorder(),
          //           labelText: 'Enter Alarm Time',
          //         ),
          //       controller: _alarmTimeController,
          //       )
          //     ),
          //   ],
          // ),
          // Row(
          //   children: [
          //     Expanded(child:Container()),
          //     TextButton(
          //       child: Text("ADD"),
          //       onPressed: (){},
          //     )
          //   ],
          // )
        ],
      ),

      // Create Folder
      Text("Create Folder"),
    ],
  );
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
              // padding: EdgeInsets.fromLTRB(40,0,0,0),
              child: ListView(
                children: widget.alarms.toList()
                // children: [Text("1"), Text("2")]
              )
            ),
          )
        ),
        
      ],
    );
  }
  
}