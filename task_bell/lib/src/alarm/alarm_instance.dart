import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:task_bell/src/alarm/helpers/map_converters.dart';
import 'recurrence/recur.dart';
import 'recurrence/relative_recur.dart';
import 'recurrence/week_recur.dart';

class AlarmInstance extends StatefulWidget implements Comparable {
  
  final double containerHeight = 50;
  final String name;
  final bool isActive;
  final String parentId;
  final Recur recur;
  final AlarmSettings alarmSettings;

  const AlarmInstance({
    required this.name,
    required this.alarmSettings,
    required this.recur,
    this.parentId = '-1',
    this.isActive = false,
    super.key,
  });

  static AlarmInstance fromMap(Map<String, dynamic> map) {
    Recur? recur;
    if (map["recurtype"] == "week") {
      recur = WeekRecur.fromMap(map);
    } else if (map["recurtype"] == "relative") {
      recur = RelativeRecur.fromMap(map);
    }
    if (recur == null) {
      throw Exception("Unknown or missing recur type when reading AlarmInstance from map");
    }

    AlarmSettings alarmSettings = MapConverters.alarmSettingsFromMap(map);

    return AlarmInstance(
      name: map["name"],
      parentId: map["parentId"],
      isActive: (map['isactive'] is bool)? map['isactive'] : MapConverters.intToBool(map["isactive"]),
      recur: recur,
      alarmSettings: alarmSettings,
    );
  }

  Map<String, dynamic> toMap() => {
        "name": name,
        "isactive": isActive,
        "parentId": parentId,
        ...recur.toMap(),
        ...MapConverters.alarmSettingsToMap(alarmSettings),
      };

  @override
  State<StatefulWidget> createState() => AlarmInstanceState();

  @override
  int compareTo(other) {
    return alarmSettings.dateTime.millisecondsSinceEpoch
        .compareTo(other.alarmSettings.dateTime.millisecondsSinceEpoch);
  }
}

class AlarmInstanceState extends State<AlarmInstance> {
  
  bool _showRelativeTime = false;
  late bool isActive;
  late AlarmSettings alarmSettings;

  @override
  void initState() {
    super.initState();
    isActive = widget.isActive;
    alarmSettings = widget.alarmSettings;
    if (isActive) {
      Alarm.set(alarmSettings: alarmSettings);
    }
  }

  Future<void> toggleAlarmStatus() async {
    setState(() {
      isActive = !isActive;
    });

    if (isActive) {
      DateTime? nextOccurrence = widget.recur.getNextOccurrence(DateTime.now());
      if (nextOccurrence == null) {
        setState(() {
          isActive = false;
        });
        return;
      }

      alarmSettings = alarmSettings.copyWith(dateTime: nextOccurrence);
      await Alarm.set(alarmSettings: alarmSettings);

      debugPrint("Alarm set for $nextOccurrence");
    } else {
      await Alarm.stop(alarmSettings.id);
    }
    
    debugPrint("alarm isactive? : $isActive");

  }

  String formatDateTime(bool relative) {
    DateTime now = DateTime.now();
    DateTime? nextOccurrence = widget.recur.getNextOccurrence(now);

    if (nextOccurrence == null) return "";

    if (relative) {
      final diff = nextOccurrence.difference(now);
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      final minutes = diff.inMinutes % 60;
      final seconds = diff.inSeconds % 60;

      return "${days}d, ${hours}h, ${minutes}m, ${seconds}s";
    }

    return nextOccurrence.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              toggleAlarmStatus();
            },
            icon: Icon(isActive ? Icons.toggle_on : Icons.toggle_off_outlined),
          ),
          Text(widget.name),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Text(formatDateTime(_showRelativeTime)),
          ),
          IconButton(
            onPressed: () => setState(() {
              _showRelativeTime = !_showRelativeTime;
            }),
            icon: const Icon(Icons.swap_horiz),
          ),
        ],
      ),
    );
  }
}

  /* Current List of all fields for alarm instance
    "name" String
    "isactive" bool
    "parentId" String
    "key" String
    "recurtype" String
    "activedays": int,
    "skipweeks": int,
    "repeatweeks": int,
    "recurtime": int,
    "inittime": int,
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