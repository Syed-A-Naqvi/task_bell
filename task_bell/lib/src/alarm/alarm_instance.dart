import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter/services.dart';
import 'package:task_bell/src/alarm/helpers/alarm_or_folder.dart';
import 'package:task_bell/src/alarm/helpers/map_converters.dart';
import 'package:task_bell/src/storage/task_bell_database.dart';
import 'recurrence/recur.dart';
import 'recurrence/relative_recur.dart';
import 'recurrence/week_recur.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AlarmInstance extends StatefulWidget implements Comparable {
  
  final double containerHeight = 50;
  final String name;
  final bool isActive;
  final int parentId;
  final Recur recur;
  final AlarmSettings alarmSettings;

  const AlarmInstance({
    required this.name,
    required this.alarmSettings,
    required this.recur,
    required this.parentId,
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
        "isactive": MapConverters.boolToInt(isActive),
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
  TaskBellDatabase tDB = TaskBellDatabase();
  late bool isActive = false;
  late AlarmSettings alarmSettings = widget.alarmSettings;
  late String fakeName;
  late Recur fakeRecur;
  bool deleted = false;
  bool edited = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    fakeName = widget.name;
    fakeRecur = widget.recur;
  }

  Future<void> _initialize() async {
    try {
      AlarmInstance? currentAlarm = await tDB.getAlarm(widget.alarmSettings.id);
      if (currentAlarm != null) {
        isActive = currentAlarm.isActive;
        alarmSettings = currentAlarm.alarmSettings;
        if (isActive) {
          await Alarm.set(alarmSettings: alarmSettings);
        }
      } else {
        isActive = false;
      }
    } catch (e) {
      debugPrint("Failed to initialize alarm: $e");
    }

    if (mounted) {
      setState(() {});
    }
  }


  Future<void> toggleAlarmStatus() async {
    bool newIsActive = !isActive;

    if (newIsActive) {
      // Activate the alarm
      DateTime? nextOccurrence = widget.recur.getNextOccurrence(DateTime.now());
      if (nextOccurrence == null) {
        // Can't activate the alarm
        newIsActive = false;
        displaySnackBar("No new occurrence, can't activate alarm.");
      } else {
        alarmSettings = alarmSettings.copyWith(dateTime: nextOccurrence);
        try {
          // Update alarm settings in the database
          await tDB.updateAlarm(widget.alarmSettings.id, {
            ...MapConverters.alarmSettingsToMap(alarmSettings),
            'isactive': MapConverters.boolToInt(newIsActive),
          });
          await Alarm.set(alarmSettings: alarmSettings);
          debugPrint("Alarm set for $nextOccurrence");
          // displaySnackBar("Scheduled for ${formatDateTime(true)} from now");
          displaySnackBar(AppLocalizations.of(context)!.alarmScheduled(formatDateTime(true)));
        } catch (e) {
          debugPrint("Failed to set the alarm or update the database: $e");
          displaySnackBar("Failed to set the alarm or update the database: $e");
          newIsActive = false;
        }
      }
    } else {
      // Deactivate the alarm
      try {
        await Alarm.stop(alarmSettings.id);
        debugPrint("Alarm stopped.");
        // Update `isactive` in the database
        await tDB.updateAlarm(widget.alarmSettings.id, {'isactive': MapConverters.boolToInt(false)});
        // displaySnackBar(AppLocalizations.of(context)!.alarmDisable);
      } catch (e) {
        debugPrint("Failed to stop the alarm: $e");
        displaySnackBar("Failed to stop the alarm: $e");
      }
    }

    // Update the UI state
    if (mounted) {
      setState(() {
        isActive = newIsActive;
      });
    }
  }


  void displaySnackBar(String message) {
    var snackBar = SnackBar(
      content: Text(message)
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String formatDateTime(bool relative) {
    DateTime now = DateTime.now();
    // DateTime? nextOccurrence = widget.recur.getNextOccurrence(now);
    DateTime? nextOccurrence;
    if (edited) {
      nextOccurrence = fakeRecur.getNextOccurrence(now);
    } else {
      nextOccurrence = widget.recur.getNextOccurrence(now);
    }
      

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

  void openEditMenu() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime? nextOccur = fakeRecur.getNextOccurrence(DateTime.now());
        return AlarmOrFolderDialog(
          parentId: -1, // Provide the necessary parentId
          disableFolderTab: true,
          namePrefill: widget.name,
          activeDays: (fakeRecur as WeekRecur).activeDays,
          initialTime: nextOccur == null ? const TimeOfDay(hour: -1, minute: -1) :
                                                 TimeOfDay.fromDateTime(nextOccur),
          onCreateAlarm: (alarmInstance) async {

            // update time and next occurrence and name in the database
            await tDB.updateAlarm(widget.alarmSettings.id, alarmInstance.recur.toMap());
            await tDB.updateAlarm(widget.alarmSettings.id, {"name":alarmInstance.name});

            // if the alarm is toggled on, remove from queue, update time and re-add to queue
            if (widget.isActive) {
              Alarm.stop(widget.alarmSettings.id); // remove from queue, may be unnecessary
              Alarm.set(alarmSettings: alarmInstance.alarmSettings); // add to queue with updated time
            }

            fakeName = alarmInstance.name;
            fakeRecur = alarmInstance.recur;
            edited = true;

            setState((){});
          },
          onCreateFolder: (folder) {}, // do nothing. folder tab is disabled
        );
      }
    );
  }

  double dragStartX = 0;
  double xOffset = 0;
  final double maxOffset = 40;
  int vibrate = 0;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: !deleted,
      child: GestureDetector(
        onLongPress: openEditMenu, 
          
        // onDoubleTap: () {setState((){deleted = true;});},
        onHorizontalDragStart: (details) {
          xOffset = 0;
          dragStartX = details.globalPosition.dx;
        },
        onHorizontalDragUpdate: (details) {
          xOffset = details.globalPosition.dx - dragStartX;
          if (xOffset < 0) {
            xOffset = 0;
            vibrate = 0;
          } else if (xOffset > maxOffset) {
            vibrate++;
            xOffset = maxOffset;
            if (vibrate == 3) {
              HapticFeedback.heavyImpact();
            }
          }
          setState((){});
        },
        onHorizontalDragEnd: (details) {
          
          if (details.globalPosition.dx - dragStartX > maxOffset) {
            // delete the alarm
            deleted = true;
            // remove from db
            tDB.deleteAlarm(widget.alarmSettings.id);
            // unschedule the alarm
            Alarm.stop(widget.alarmSettings.id);

            setState((){});
            // HapticFeedback.heavyImpact(); // haptic feedback when deleting
          }
          // do this regardless so undo delete isn't messed up
          xOffset = 0;
          dragStartX = 0;
          vibrate = 0;
        },
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
              child: SizedBox(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        toggleAlarmStatus();
                        HapticFeedback.lightImpact();
                      },
                      icon: Icon(isActive ? Icons.toggle_on : Icons.toggle_off_outlined),
                    ),
                    Text(edited ? fakeName : widget.name), // no idea why this is necessary
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
              )
            )
          ] 
        )
        
      )
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