import 'dart:async';

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
      isActive: map["isactive"] == 0 ? false : true,
      // isActive: (map['isactive'] is bool)? map['isactive'] : MapConverters.intToBool(map["isactive"]),
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
  
  bool showRelativeTime = false;
  TaskBellDatabase tDB = TaskBellDatabase();
  late bool isActive = false;
  late AlarmSettings alarmSettings = widget.alarmSettings;
  late String fakeName;
  late Recur fakeRecur;
  bool deleted = false;
  bool edited = false;
  bool periodicTimerEnabled = false;
  bool showSwapTimeModes = true;

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
      // AlarmSettings? alarmSettings2 = Alarm.getAlarm(widget.alarmSettings.id);

      if (currentAlarm != null) {
        isActive = currentAlarm.isActive;
        alarmSettings = currentAlarm.alarmSettings;
        if (isActive) {
          debugPrint("Scheduling alarm to go off at ${alarmSettings.dateTime.toString()}");
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
    // newIsActive = true;
    if (newIsActive) {
      // Activate the alarm
      DateTime? nextOccurrence = widget.recur.getNextOccurrence(DateTime.now());
      if (nextOccurrence == null) {
        // Can't activate the alarm
        isActive = false;
        // displaySnackBar("No new occurrence, can't activate alarm.");
        setState((){});
        return; 
      }

      alarmSettings = alarmSettings.copyWith(dateTime: nextOccurrence);
      try {
        // Update alarm settings in the database
        // Map<String, dynamic> map = MapConverters.alarmSettingsToMap(alarmSettings);
        // map["isactive"] = 1;

        // await tDB.updateAlarm(alarmSettings.id, map);
        await tDB.activateAlarm(alarmSettings.id);
        // await tDB.updateAlarm(widget.alarmSettings.id, {
        //   ...MapConverters.alarmSettingsToMap(alarmSettings),
        //   'isactive': MapConverters.boolToInt(newIsActive),
        // });
        
        await Alarm.set(alarmSettings: alarmSettings);
        debugPrint("Alarm set for $nextOccurrence");
        // displaySnackBar("Scheduled for ${formatDateTime(true)} from now");
        // displaySnackBar(AppLocalizations.of(context)!.alarmScheduled(formatDateTime(true)));
      } catch (e) {
        debugPrint("Failed to set the alarm or update the database: $e");
        // displaySnackBar("Failed to set the alarm or update the database: $e");
        newIsActive = false;
      }

      isActive = newIsActive;
      setState((){});
      return;
    }

    // Deactivate the alarm
    try {
      
      // Update `isactive` in the database
      await tDB.updateAlarm(widget.alarmSettings.id, {'isactive': MapConverters.boolToInt(false)});
      // displaySnackBar(AppLocalizations.of(context)!.alarmDisable);
      // do this last
      await Alarm.stop(widget.alarmSettings.id);
      debugPrint("Alarm stopped.");
    } catch (e) {
      debugPrint("Failed to stop the alarm: $e");
      displaySnackBar("Failed to stop the alarm: $e");
    }

    isActive = newIsActive;
    // Update the UI state
    if (mounted) {
      setState(() {});
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


      if (!periodicTimerEnabled) { //  && isActive // doesn't make sense to exist for alarms
        periodicTimerEnabled = true;
        Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!showRelativeTime) { // !isActive
            periodicTimerEnabled = false;
            timer.cancel();
            return;
          }
          if (mounted) {
            setState((){});  
          }
        });
      }
      

      return "${days}d, ${hours}h, ${minutes}m, ${seconds}s";
    }

    String month = "";
    switch(nextOccurrence.month){
      case  1: month = AppLocalizations.of(context)!.jan; break;
      case  2: month = AppLocalizations.of(context)!.feb; break;
      case  3: month = AppLocalizations.of(context)!.mar; break;
      case  4: month = AppLocalizations.of(context)!.apr; break;
      case  5: month = AppLocalizations.of(context)!.may; break;
      case  6: month = AppLocalizations.of(context)!.jun; break;
      case  7: month = AppLocalizations.of(context)!.jul; break;
      case  8: month = AppLocalizations.of(context)!.aug; break;
      case  9: month = AppLocalizations.of(context)!.sep; break;
      case 10: month = AppLocalizations.of(context)!.oct; break;
      case 11: month = AppLocalizations.of(context)!.nov; break;
      case 12: month = AppLocalizations.of(context)!.dec; break;
      default: "";
    }

    // theoretically should base this on the locale, but day month year is standard most places
    // not sure if time should go before or after date; not sure what should be considered more important
    // don't display seconds, alarms are not that precise
    if (MediaQuery.of(context).alwaysUse24HourFormat) {
      return "${nextOccurrence.day} $month ${nextOccurrence.hour.toString().padLeft(2, '0')}${AppLocalizations.of(context)!.hourMinuteSeparator}${
      nextOccurrence.minute.toString().padLeft(2, '0')}";
    }

    // not sure if there is any point in localizing it since I think 12h time isn't seen much in other languages
    if (nextOccurrence.hour > 12) {
      return "${nextOccurrence.day} $month ${(nextOccurrence.hour-12).toString().padLeft(2, '0')}${AppLocalizations.of(context)!.hourMinuteSeparator}${
      nextOccurrence.minute.toString().padLeft(2, '0')}pm";
    }
    if (nextOccurrence.hour == 0) {
      return "${nextOccurrence.day} $month 12${AppLocalizations.of(context)!.hourLetter}${
      nextOccurrence.minute}am";
    }
    return "${nextOccurrence.day} $month ${nextOccurrence.hour.toString().padLeft(2, '0')}${AppLocalizations.of(context)!.hourMinuteSeparator}${
      nextOccurrence.minute.toString().padLeft(2, '0')}am";
    

    // return nextOccurrence.toString();
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
            Map<String, dynamic> map = alarmInstance.recur.toMap();
            map["name"] = alarmInstance.name;
            map["isactive"] = isActive ? 1 : 0;
            await tDB.updateAlarm(widget.alarmSettings.id, map);
            
            // await tDB.updateAlarm(widget.alarmSettings.id, alarmInstance.recur.toMap());
            // await tDB.updateAlarm(widget.alarmSettings.id, {"name":alarmInstance.name, "isactive": isActive ? 1 : 0});

            // if the alarm is toggled on, remove from queue, update time and re-add to queue
            if (isActive) {
              Alarm.stop(widget.alarmSettings.id); // remove from queue, may be unnecessary
              Alarm.set(alarmSettings: alarmInstance.alarmSettings); // add to queue with updated time
            }

            fakeName = alarmInstance.name;
            fakeRecur = alarmInstance.recur;
            edited = true;

            if (mounted) {
              setState((){});
            }
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
          if (mounted) {
            setState((){});
          }
        },
        onHorizontalDragEnd: (details) {
          
          if (details.globalPosition.dx - dragStartX > maxOffset) {
            // delete the alarm
            deleted = true;
            // remove from db
            tDB.deleteAlarm(widget.alarmSettings.id);
            // unschedule the alarm
            Alarm.stop(widget.alarmSettings.id);

            var snackBar = SnackBar(
              // content: Text("Deleted Alarm"),
              content: Text("${AppLocalizations.of(context)!.deleted} ${
                AppLocalizations.of(context)!.quoteLeft}${
                edited ? fakeName : widget.name}${
                AppLocalizations.of(context)!.quoteRight}"),
              action: SnackBarAction(label: AppLocalizations.of(context)!.undo, onPressed: (){
                deleted = false;
                tDB.insertAlarm(AlarmInstance(
                  alarmSettings: alarmSettings,
                  name: edited ? fakeName : widget.name,
                  recur: edited ? fakeRecur : widget.recur,
                  parentId: widget.parentId,
                  isActive: isActive,
                ));
                if (isActive) {
                  Alarm.set(alarmSettings: alarmSettings);
                }
                setState((){});
              }),
            );

            ScaffoldMessenger.of(context).showSnackBar(snackBar);

          }
          // do this regardless so undo delete isn't messed up
          xOffset = 0;
          dragStartX = 0;
          vibrate = 0;
          setState((){});

          // if (mounted) {
          //   setState((){});
          // }
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
                      child: Text(formatDateTime(showRelativeTime)),
                    ),
                    Visibility(
                      visible: showSwapTimeModes,
                      child: IconButton(
                        onPressed: () => setState(() {
                          showRelativeTime = !showRelativeTime;
                        }),
                        icon: const Icon(Icons.swap_horiz),
                      ),
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