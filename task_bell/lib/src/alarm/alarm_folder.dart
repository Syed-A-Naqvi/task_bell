import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:task_bell/src/alarm/weekday_selector.dart';
import '../settings/settings_view.dart';
import 'package:collection/collection.dart';

import 'alarm_instance.dart';
import 'recurrence/week_recur.dart';

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
  double childIndent = 50;

  // Keep track of subfolders, folders should also not be alarms, so keep them separate
  HeapPriorityQueue<AlarmFolder> subfolders = HeapPriorityQueue<AlarmFolder>();
  
  // Keep track of alarms contained within the folder
  HeapPriorityQueue<AlarmInstance> alarms = HeapPriorityQueue<AlarmInstance>();
  
  @override
  State<StatefulWidget> createState() => AlarmFolderState();
  
  @override
  int compareTo(other) {
    return position.compareTo(other.position);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'position': position,
    };
  }

  static AlarmFolder fromMap(Map<String, dynamic> map) {
    return AlarmFolder(id: map["id"], name: map["name"], position: map["position"]);
  }

}

class AlarmFolderState extends State<AlarmFolder> {

  bool _expanded = false;

  Icon icon = const Icon(Icons.chevron_right);

  void _toggleExpansion() {
    _expanded = !_expanded;
    icon = !_expanded ? const Icon(Icons.chevron_right) : const Icon(Icons.expand_more);
    setState((){});
  }

  void createNewAlarm() async {
    if (nameController.text.isEmpty) {
      debugPrint("Invalid name provided");
      showDialog(context: context, builder: (context) => const AlertDialog(
        title: Text("Invalid name"),
      ));

      return;
    }

    TimeOfDay? selectedTime24Hour = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 47),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    // user closed dialog, did not select time
    if (selectedTime24Hour == null) {
      return;
    }

    Navigator.of(context).pop();

    debugPrint(selectedTime24Hour.hour.toString());

    DateTime recurTime = DateTime(
      DateTime.now().year, 
      DateTime.now().month,
      DateTime.now().day,
      selectedTime24Hour.hour,
      selectedTime24Hour.minute,  
    );

    widget.alarms.add(AlarmInstance(
      name: nameController.text, 
      alarmSettings: AlarmSettings(
        id: (DateTime.now().millisecondsSinceEpoch ~/1000) % 2147483647, 
        dateTime: recurTime,
        assetAudioPath: "", 
        vibrate: true,
        androidFullScreenIntent: true,
        notificationSettings: NotificationSettings(
          title: nameController.text,
          body: "Alarm triggered at ${recurTime.hour}:${recurTime.minute}",
          stopButton: 'Stop the alarm',
          icon: 'notification_icon',
        ),
      ),
      recur: WeekRecur(
        activeDays: weekdaySelector.activeDays,
        recurTime: recurTime
      ),
      parentId: widget.id,
    ),);

    nameController.text = "";

    setState((){});
  }

  void _createNewFolder() {
    if (nameController.text.isEmpty) {
      debugPrint("Invalid name provided");
      showDialog(context: context, builder: (context) => const AlertDialog(
        title: Text("Invalid name"),
      ));

      return;
    }

    AlarmFolder subFolder = AlarmFolder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text,
      position: widget.subfolders.length,
    );

    debugPrint("Before ${widget.name}, adding ${nameController.text}");
    debugPrint(widget.subfolders.toList().toString());
    widget.subfolders.add(subFolder);

    setState((){});

    Navigator.of(context).pop();

    nameController.text = "";
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

  final TextEditingController nameController = TextEditingController();

  WeekdaySelector weekdaySelector = WeekdaySelector(activeDays: 0,);

  Widget _buildTabView() {
  return Expanded(child: Padding(
    padding: const EdgeInsets.all(10),
    child: TabBarView(
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Enter Alarm Name',
                  ),
                controller: nameController,
                )
              ),
            ],
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0,10,10,0),
              child: weekdaySelector,
            )
          ),

          Expanded(child: Container(),),
          Row(
            children: [
              Expanded(child:Container()),
              TextButton(
                onPressed: createNewAlarm,
                child: const Text("SET TIME"),
              )
            ],
          )
        ],
      ),

      // Create Folder
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Create folder for ${widget.name}"),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Enter Folder Name',
                  ),
                controller: nameController,
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

  List<Widget> indentChildren() {
    List<Widget> indented = [];

    final folders = widget.subfolders.toList();
    final alarms = widget.alarms.toList();

    for (AlarmFolder af in folders) {
      indented.add(
        Padding(
          padding: EdgeInsets.fromLTRB(widget.childIndent, 0,0,0),
          child: af,
        )
      );
    }
    for (final af in alarms) {
      indented.add(
        Padding(
          padding: EdgeInsets.fromLTRB(widget.childIndent, 0,0,0),
          child: af,
        )
      );
    }

    return indented;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: (){debugPrint("pressed ${widget.name}");},
      // onTap: _toggleExpansion, // do not want this, gaps between children trigger
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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
          
        ] + (_expanded ? indentChildren() : []),
      )
    );
  }
  
}