import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:task_bell/src/alarm/helpers/map_converters.dart';
import 'recurrence/recur.dart';
import 'recurrence/relative_recur.dart';
import 'recurrence/week_recur.dart';

class AlarmInstance extends StatefulWidget implements Comparable {

  double containerHeight = 50;

  AlarmSettings alarmSettings;
  String name;
  bool _isActive = false;
  String parentId;

  Recur recur;

  AlarmInstance({
    required this.name,
    required this.alarmSettings,
    required this.recur,
    this.parentId = '-1',
    isActive = false,
    super.key,
  }) {
    _isActive = isActive;

    if (_isActive) {
      Alarm.set(alarmSettings: alarmSettings);
    }
  }

  void toggleAlarm() async {

    debugPrint("Toggle alarm called");
      
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

      debugPrint("Alarm set for ${nextOccur.toString()}");

      
      return;
    }
    
    await Alarm.stop(alarmSettings.id);
  }

  bool isActive() {
    return _isActive;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      "name" : name,
      "isactive": _isActive,
      "parendId": parentId,
    };
    map.addAll(recur.toMap());
    map.addAll(MapConverters.alarmSettingsToMap(alarmSettings));

    return map;
  }


  /* Current List of all fields for alarm instance
    "name" String
    "isactive" bool
    "recurtype" String
    "parentId" String
    "inittime" int
    "recurtime" int
    "id" int // this refers to the alarmsettings id, could potentially benefit from renaming
    "datetime" int // milliseconds since epoch when alarm will go off
    "assetAudioPath" String
    "loopAudio" bool
    "vibrate" bool
    "volume" double (nullable)
    "volumeEnforced" bool
    "fadeDuration" double
    "warningNotificationOnKill" bool
    "androidFullScreenIntent" bool
    "title" String // notification title
    "body" String // notification body
    "stopButton" String (nullable) // notification stop button text 
    "icon" String (nullable) // icon path? to for the icon of the alarm, for notification
  */
  AlarmInstance fromMap(Map<String, dynamic> map) {
    Recur? recur;
    if (map["recurtype"] == "week") {
      recur = WeekRecur.fromMap(map);
    } 
    else if (map["recurtype"] == "relative") {
      recur = RelativeRecur.fromMap(map);
    }
    if (recur == null) {
      throw Exception("unknown or missing recur type when reading AlarmInstance from map"); 
    }

    AlarmSettings as = MapConverters.alarmSettingsFromMap(map);
  
    return AlarmInstance(
      name: map["name"], 
      alarmSettings: as, 
      recur: recur,
      parentId: map["parentId"],
      isActive: map["isactive"],
    );

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

  bool _relative = false;

  /// This will do custom formatting for display
  String _dateTimeToString(bool relative) {

    DateTime? nextOccur = widget.recur.getNextOccurence(DateTime.now());
    DateTime dt = DateTime.now();
    
    if (nextOccur == null) {
      return "";
    }

    if (widget.recur is RelativeRecur) {
      dt = (widget.recur as RelativeRecur).initTime;
    }
    

    if (relative) {
      int days = nextOccur.day - dt.day;
      int hours = nextOccur.hour - dt.hour;
      int minutes = nextOccur.minute - dt.minute;
      int seconds = nextOccur.second - dt.second;

      if (seconds < 0) { 
        minutes -= 1;
        seconds = 60 + seconds;
      }
      if (minutes < 0) {
        hours -= 1;
        minutes = 60 + minutes;
      }
      if (hours < 0) {
        days -= 1;
        hours = 24 + hours;
      }
      return "${days}d, ${hours}h, ${minutes}m ${seconds}s";

      // return "${dt.day*24 + dt.hour}h, ${dt.minute}m";
    }
    return nextOccur.toString();
  }

  void _toggleAlarm() {

    widget.toggleAlarm();

    setState((){});

    DateTime? nextOccur = widget.recur.getNextOccurence(DateTime.now());

    if (nextOccur == null) {
      return;
    }
    if (widget._isActive) {
      SnackBar snackBar = SnackBar(content: Text("Alarm set for ${_dateTimeToString(true)} from now"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    

    
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Row(
        children: [
          IconButton(
            onPressed: _toggleAlarm, 

            icon: Icon(widget.isActive() ? Icons.toggle_on : Icons.toggle_off_outlined),
          ),
          Text(widget.name),
          Padding(
            padding: const EdgeInsets.fromLTRB(10,0,10,0),
            child: Text(_dateTimeToString(_relative)),
          ),

          IconButton(
            onPressed: (){setState((){_relative = !_relative;});}, 
            icon: const Icon(Icons.swap_horiz),
          ),


          
        ],
      ),
    );
  }
}