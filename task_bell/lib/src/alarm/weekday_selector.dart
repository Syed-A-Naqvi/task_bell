import 'package:flutter/material.dart';
import 'recurrence/week_recur.dart';

class WeekdaySelector extends StatefulWidget {
  final int activeDays;

  /// activeDays should be a bit vector, the same used by recurrence/WeekRecur
  const WeekdaySelector({
    required this.activeDays,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _WeekdaySelectorState();
}

class _WeekdaySelectorState extends State<WeekdaySelector> {
  late int _activeDays;

  @override
  void initState() {
    super.initState();
    _activeDays = widget.activeDays;
  }

  void toggleDay(int day) {
    setState(() {
      _activeDays ^= day; // Toggle the bit for the selected day
    });
  }

  double colWidth = 32.0;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        SizedBox(
          width: colWidth,
          child: Column(
            children: [
              const Text("S"),
              Checkbox(
                value: _activeDays & WeekRecur.sunday == WeekRecur.sunday,
                onChanged: (bool? value) {
                  toggleDay(WeekRecur.sunday);
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
              const Text("M"),
              Checkbox(
                value: _activeDays & WeekRecur.monday == WeekRecur.monday,
                onChanged: (bool? value) {
                  toggleDay(WeekRecur.monday);
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
              const Text("T"),
              Checkbox(
                value: _activeDays & WeekRecur.tuesday == WeekRecur.tuesday,
                onChanged: (bool? value) {
                  toggleDay(WeekRecur.tuesday);
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
              const Text("W"),
              Checkbox(
                value: _activeDays & WeekRecur.wednesday == WeekRecur.wednesday,
                onChanged: (bool? value) {
                  toggleDay(WeekRecur.wednesday);
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
              const Text("T"),
              Checkbox(
                value: _activeDays & WeekRecur.thursday == WeekRecur.thursday,
                onChanged: (bool? value) {
                  toggleDay(WeekRecur.thursday);
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
              const Text("F"),
              Checkbox(
                value: _activeDays & WeekRecur.friday == WeekRecur.friday,
                onChanged: (bool? value) {
                  toggleDay(WeekRecur.friday);
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
              const Text("S"),
              Checkbox(
                value: _activeDays & WeekRecur.saturday == WeekRecur.saturday,
                onChanged: (bool? value) {
                  toggleDay(WeekRecur.saturday);
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