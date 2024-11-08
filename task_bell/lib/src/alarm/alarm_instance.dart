import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';

class AlarmInstance extends StatefulWidget implements Comparable {

  double containerHeight = 50;

  AlarmSettings alarmSettings;
  String name;
  bool _isActive = false;

  AlarmInstance({
    required this.name,
    required this.alarmSettings,
    isActive = false,
    super.key,
  }) {
    _isActive = isActive;

    if (_isActive) {
      Alarm.set(alarmSettings: alarmSettings);
    }
  }

  void toggleAlarm() async {
      
    _isActive = !_isActive;

    if (_isActive) {
      await Alarm.set(alarmSettings: alarmSettings);
      return;
    }
    
    await Alarm.stop(alarmSettings.id);
  }

  bool isActive() {
    return _isActive;
  }

  // @override
  // Map<String, dynamic> toMap(){
  //   return {"name" : this.name}
  // }

  @override
  State<StatefulWidget> createState() => _AlarmInstanceState();
  
  @override
  int compareTo(other) {
    return alarmSettings.dateTime.millisecondsSinceEpoch
      .compareTo(other.alarmSettings.dateTime.millisecondsSinceEpoch);
  }
}

class _AlarmInstanceState extends State<AlarmInstance> {

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // height: widget.containerHeight,
      child: Row(
        children: [
          IconButton(
            onPressed: (){widget.toggleAlarm(); setState((){});}, 
            icon: Icon(widget.isActive() ? Icons.toggle_on : Icons.toggle_off),
          ),
          Text(widget.name),
        ],
      ),
    );
    // return Text("Hello World");
  }
}