import 'package:flutter/material.dart';
import 'recurrence/week_recur.dart';

class WeekdaySelector extends StatefulWidget {

  int activeDays;

  /// activeDays should be a bit vector, the same used by recurrence/WeekRecur
  WeekdaySelector({
    required this.activeDays,
    super.key,
  });


  @override
  State<StatefulWidget> createState() => _WeekdaySelectorState();
}

class _WeekdaySelectorState extends State<WeekdaySelector> {

  /*
  Default/builtin checkboxes are not well built for our purposes, will need
  to make our own, which is pretty unfortunate
  */

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
                value: widget.activeDays & WeekRecur.sunday == WeekRecur.sunday,
                onChanged: (bool? value) {setState((){
                  widget.activeDays = widget.activeDays ^ WeekRecur.sunday;
                });},
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
                value: widget.activeDays & WeekRecur.monday == WeekRecur.monday,
                onChanged: (bool? value) {setState((){
                  widget.activeDays = widget.activeDays ^ WeekRecur.monday;
                });},
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
                value: widget.activeDays & WeekRecur.tuesday == WeekRecur.tuesday,
                onChanged: (bool? value) {setState((){
                  widget.activeDays = widget.activeDays ^ WeekRecur.tuesday;
                });},
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
                value: widget.activeDays & WeekRecur.wednesday == WeekRecur.wednesday,
                onChanged: (bool? value) {setState((){
                  widget.activeDays = widget.activeDays ^ WeekRecur.wednesday;
                });},
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
                value: widget.activeDays & WeekRecur.thursday == WeekRecur.thursday,
                onChanged: (bool? value) {setState((){
                  widget.activeDays = widget.activeDays ^ WeekRecur.thursday;
                });},
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
                value: widget.activeDays & WeekRecur.friday == WeekRecur.friday,
                onChanged: (bool? value) {setState((){
                  widget.activeDays = widget.activeDays ^ WeekRecur.friday;
                });},
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
                value: widget.activeDays & WeekRecur.saturday == WeekRecur.saturday,
                onChanged: (bool? value) {setState((){
                  widget.activeDays = widget.activeDays ^ WeekRecur.saturday;
                });},
                shape: const CircleBorder(),
              )
            ],
          ),
        ),
        
        
      ],
    );
  }
}