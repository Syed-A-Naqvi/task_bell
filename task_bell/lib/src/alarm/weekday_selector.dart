import 'package:flutter/material.dart';
import 'recurrence/week_recur.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WeekdaySelector extends StatefulWidget {

  final int activeDays;
  final ValueChanged<int>? onActiveDaysChanged;

  /// activeDays should be a bit vector, the same used by recurrence/WeekRecur
  const WeekdaySelector({
    required this.activeDays,
    this.onActiveDaysChanged,
    super.key,
  });

  @override
  WeekdaySelectorState createState() => WeekdaySelectorState();

}

class WeekdaySelectorState extends State<WeekdaySelector>{

  late int activeDays;

  @override
  void initState(){
    super.initState();
    activeDays = widget.activeDays;
  }

  void _toggleDay(int day) {
    if(widget.onActiveDaysChanged == null){
      debugPrint("somehow widget.onActiveDaysChanged is null");
      return;
    }
    int newActiveDays = activeDays ^ day; // Toggle the bit for the selected day
    widget.onActiveDaysChanged!(newActiveDays);
    setState(() {
      activeDays = newActiveDays;
    });
  }

  static const double colWidth = 32.0;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        SizedBox(
          width: colWidth,
          child: Column(
            children: [
              Text(AppLocalizations.of(context)!.sundayLetter),
              Checkbox(
                value: activeDays & WeekRecur.sunday == WeekRecur.sunday,
                onChanged: (bool? value) {
                  _toggleDay(WeekRecur.sunday);
                },
                shape: const CircleBorder(),
              )
            ],
          ),
        ),
        SizedBox(
          width: colWidth,
          child: Column(
            children: [
              Text(AppLocalizations.of(context)!.mondayLetter),
              Checkbox(
                value: activeDays & WeekRecur.monday == WeekRecur.monday,
                onChanged: (bool? value) {
                  _toggleDay(WeekRecur.monday);
                },
                shape: const CircleBorder(),
              )
            ],
          ),
        ),
        SizedBox(
          width: colWidth,
          child: Column(
            children: [
              Text(AppLocalizations.of(context)!.tuesdayLetter),
              Checkbox(
                value: activeDays & WeekRecur.tuesday == WeekRecur.tuesday,
                onChanged: (bool? value) {
                  _toggleDay(WeekRecur.tuesday);
                },
                shape: const CircleBorder(),
              )
            ],
          ),
        ),
        SizedBox(
          width: colWidth,
          child: Column(
            children: [
              Text(AppLocalizations.of(context)!.wednesdayLetter),
              Checkbox(
                value: activeDays & WeekRecur.wednesday == WeekRecur.wednesday,
                onChanged: (bool? value) {
                  _toggleDay(WeekRecur.wednesday);
                },
                shape: const CircleBorder(),
              )
            ],
          ),
        ),
        SizedBox(
          width: colWidth,
          child: Column(
            children: [
              Text(AppLocalizations.of(context)!.thursdayLetter),
              Checkbox(
                value: activeDays & WeekRecur.thursday == WeekRecur.thursday,
                onChanged: (bool? value) {
                  _toggleDay(WeekRecur.thursday);
                },
                shape: const CircleBorder(),
              )
            ],
          ),
        ),
        SizedBox(
          width: colWidth,
          child: Column(
            children: [
              Text(AppLocalizations.of(context)!.fridayLetter),
              Checkbox(
                value: activeDays & WeekRecur.friday == WeekRecur.friday,
                onChanged: (bool? value) {
                  _toggleDay(WeekRecur.friday);
                },
                shape: const CircleBorder(),
              )
            ],
          ),
        ),
        SizedBox(
          width: colWidth,
          child: Column(
            children: [
              Text(AppLocalizations.of(context)!.saturdayLetter),
              Checkbox(
                value: activeDays & WeekRecur.saturday == WeekRecur.saturday,
                onChanged: (bool? value) {
                  _toggleDay(WeekRecur.saturday);
                },
                shape: const CircleBorder(),
              )
            ],
          ),
        ),
      ],
    );
  }
}