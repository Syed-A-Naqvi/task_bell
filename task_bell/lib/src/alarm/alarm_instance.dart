import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'recurrence/recur.dart';

class AlarmInstance extends StatefulWidget implements Comparable {

  double containerHeight = 50;

  AlarmSettings alarmSettings;
  String name;
  bool _isActive = false;

  Recur recur;

  AlarmInstance({
    required this.name,
    required this.alarmSettings,
    required this.recur,
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
      DateTime? nextOccur = recur.getNextOccurence(DateTime.now());

      // If it fails to grab the next occurence for whatever reason,
      // the alarm should not be set, because there is no time to trigger at
      if (nextOccur == null) {
        _isActive = false;
        return;
      }

      // Create new AlarmSettings object to modify the next occurence.
      // cannot modify directly due to constant fields
      alarmSettings = AlarmSettings(
        id: alarmSettings.id, 
        dateTime: nextOccur, 
        assetAudioPath: alarmSettings.assetAudioPath, 
        notificationSettings: alarmSettings.notificationSettings,
        loopAudio: alarmSettings.loopAudio,
        vibrate: alarmSettings.vibrate,
        volume: alarmSettings.volume,
        volumeEnforced: alarmSettings.volumeEnforced,
        fadeDuration: alarmSettings.fadeDuration,
        warningNotificationOnKill: alarmSettings.warningNotificationOnKill,
        androidFullScreenIntent: alarmSettings.androidFullScreenIntent
      );

      await Alarm.set(alarmSettings: alarmSettings);
      return;
    }
    
    await Alarm.stop(alarmSettings.id);
  }

  bool isActive() {
    return _isActive;
  }

  @override
  Map<String, dynamic> toMap(){
    return {
      "name" : this.name,
      
      };
  }

  @override
  State<StatefulWidget> createState() => _AlarmInstanceState();
  
  @override
  int compareTo(other) {
    return alarmSettings.dateTime.millisecondsSinceEpoch
      .compareTo(other.alarmSettings.dateTime.millisecondsSinceEpoch);
  }
}

class _AlarmInstanceState extends State<AlarmInstance> {

  void _toggleAlarm() {

    widget.toggleAlarm();

    setState((){});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Row(
        children: [
          IconButton(
            onPressed: _toggleAlarm, 

            icon: Icon(widget.isActive() ? Icons.toggle_on : Icons.toggle_off),
          ),
          Text(widget.name),
        ],
      ),
    );
  }
}