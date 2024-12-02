import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/services.dart';
import 'package:task_bell/src/alarm/recurrence/relative_recur.dart';
import 'alarm_instance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'helpers/timer_or_folder.dart';

class TimerInstance extends AlarmInstance {
  const TimerInstance({
    required super.name, 
    required super.alarmSettings, 
    required super.recur,
    required super.parentId,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => TimerInstanceState();
}

class TimerInstanceState extends AlarmInstanceState {

  @override
  void initState(){
    super.initState();
    showRelativeTime = true;
    showSwapTimeModes = false;
  }

  @override
  Future<void> initialize() async {
    try {
      AlarmInstance? currentAlarm = await tDB.getAlarm(widget.alarmSettings.id);
      AlarmSettings? alarmSettings2 = Alarm.getAlarm(widget.alarmSettings.id);

      if (currentAlarm != null) {
        debugPrint("recur init: ${(currentAlarm.recur as RelativeRecur).initTime}");
        isActive = currentAlarm.isActive;
        showSwapTimeModes = isActive;
        // (currentAlarm.recur as RelativeRecur).initTime = 
        alarmSettings = currentAlarm.alarmSettings;
        if (isActive && alarmSettings2 == null) {
          debugPrint("Scheduling alarm to go off at ${alarmSettings.dateTime.toString()}");
          await Alarm.set(alarmSettings: alarmSettings);
        }
        else if (isActive) {
          debugPrint("its active");
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

  @override
  String formatDateTime(bool relative) {
    DateTime now = DateTime.now();
    DateTime? nextOccurrence = widget.recur.getNextOccurrence(now);

    if (nextOccurrence == null) return "";

    if (relative || !super.isActive) { // only show relative time unless the timer is active

      late final Duration diff;

      if (super.isActive) {
        diff = nextOccurrence.difference(now); 
      } else {
        diff = nextOccurrence.difference((widget.recur as RelativeRecur).initTime);
      }

      if (!periodicTimerEnabled && isActive) {
        periodicTimerEnabled = true;
        Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!showRelativeTime || !isActive) {
            periodicTimerEnabled = false;
            timer.cancel();
            return;
          }
          if (mounted) {
            setState(() {});
          } 
        });
      }
      
      // final days = diff.inDays;
      final hours = diff.inHours % 24;
      final minutes = diff.inMinutes % 60;
      final seconds = diff.inSeconds % 60;

      // return "$days${
      //   AppLocalizations.of(context)!.dayLetter}, $hours${
      //   AppLocalizations.of(context)!.hourLetter}, $minutes${
      //   AppLocalizations.of(context)!.minuteLetter}, $seconds${
      //   AppLocalizations.of(context)!.secondLetter}";

      // not including days because the longest the timer can be is 23h 59m
      return "$hours${
        AppLocalizations.of(context)!.hourLetter}, $minutes${
        AppLocalizations.of(context)!.minuteLetter}, $seconds${
        AppLocalizations.of(context)!.secondLetter}";
    }

    // return nextOccurrence.toString();
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
    return "${nextOccurrence.day} $month ${nextOccurrence.hour}${AppLocalizations.of(context)!.hourLetter}${
      nextOccurrence.minute}${AppLocalizations.of(context)!.minuteLetter}${
      nextOccurrence.second}${AppLocalizations.of(context)!.secondLetter}";
  }

  @override
  Future<void> toggleAlarmStatus() async {
    // Update recur with a new RelativeRecur object before toggling the alarm
    (widget.recur as RelativeRecur).initTime = DateTime.now();
  
    // Create a timer to toggle the toggle off in case the user stares at the timer until the timer goes off
    // Timer(Duration(milliseconds: widget.recur.getNextOccurrence(DateTime.now())!.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch), (){
    Timer(widget.recur.getNextOccurrence(DateTime.now())!.difference(DateTime.now()), (){
      if (!isActive) {
        return;
      }
      if (mounted) {
        setState((){isActive = false;});  
      }
    });

    debugPrint("Timer toggled");

    await super.toggleAlarmStatus();

    showSwapTimeModes = true;

    if (isActive) {
      (widget.recur as RelativeRecur).initTime = DateTime.now();
      tDB.updateAlarm(widget.alarmSettings.id, {'inittime' : (widget.recur as RelativeRecur).initTime.millisecondsSinceEpoch});
    }
  }

  @override
  void openEditMenu() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TimerOrFolderDialog(
          parentId: -2, // Provide the necessary parentId
          disableFolderTab: true,
          namePrefill: widget.name,
          onCreateTimer: (alarmInstance) async {
            // I don't think there should be any real changes here other than
            // the type of dialog
            // update time and next occurrence and name in the database
            Map<String, dynamic> map = alarmInstance.recur.toMap();
            map["name"] = alarmInstance.name;
            map["isactive"] = isActive ? 1 : 0;
            await tDB.updateAlarm(widget.alarmSettings.id, map);

            // await tDB.updateAlarm(widget.alarmSettings.id, alarmInstance.recur.toMap());
            // await tDB.updateAlarm(widget.alarmSettings.id, {"name":alarmInstance.name, "isactive": isActive ? 1 : 0});

            // if the alarm is toggled on, remove from queue, update time and re-add to queue
            // I'm honestly not sure how this should be handled for timers. So for
            // the time being, behaviour of alarms will be copied
            if (isActive) {
              Alarm.stop(widget.alarmSettings.id); // remove from queue, may be unnecessary
              Alarm.set(alarmSettings: alarmInstance.alarmSettings); // add to queue with updated time
            }

            fakeName = alarmInstance.name;
            fakeRecur = alarmInstance.recur;
            edited = true;

            setState((){});
          },
          onCreateFolder: (folder){},
        );
      }
    );
  }
}