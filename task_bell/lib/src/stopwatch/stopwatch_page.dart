import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../settings/settings_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'stopwatch.dart';

class StopwatchPage extends StatefulWidget {
  const StopwatchPage({super.key});

  @override
  StopwatchPageState createState() => StopwatchPageState();
}

class StopwatchPageState extends State<StopwatchPage> {
  final StopwatchService _stopwatchService = StopwatchService();
  bool _isRunning = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _stopwatchService.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();

    // Load current running state and update the UI accordingly
    final savedState = prefs.getString('currentState') ?? 'stopped';
    setState(() {
      _isRunning = savedState == 'running';
    });

    // Load laps and populate _stopwatchService
    final lapsJson = prefs.getString('laps');
    if (lapsJson != null) {
      final List<dynamic> lapsList = jsonDecode(lapsJson);
      _stopwatchService.laps.clear();
      for (var lapData in lapsList) {
        _stopwatchService.laps.add({
          'start': Duration(milliseconds: lapData['start']),
          'end': Duration(milliseconds: lapData['end']),
          'duration': Duration(milliseconds: lapData['duration']),
        });
      }
    }

    // Load start, lap start, and paused durations to calculate elapsed time and lap time
    final startTimeEpoch = prefs.getInt('startTimeEpoch') ?? 0;
    final pausedDuration = Duration(milliseconds: prefs.getInt('pausedDuration') ?? 0);
    final lastStopTimeEpoch = prefs.getInt('lastStopTimeEpoch') ?? DateTime.now().millisecondsSinceEpoch;

    if (!_isRunning && startTimeEpoch != 0) {
      // Calculate the elapsed time and lap time at the moment it was last paused
      final elapsedTime = Duration(milliseconds: lastStopTimeEpoch - startTimeEpoch - pausedDuration.inMilliseconds);
      final lapStartTimeEpoch = prefs.getInt('lapStartTimeEpoch') ?? startTimeEpoch;
      final lapPausedDuration = Duration(milliseconds: prefs.getInt('lapPausedDuration') ?? 0);
      final lapTime = Duration(milliseconds: lastStopTimeEpoch - lapStartTimeEpoch - lapPausedDuration.inMilliseconds);

      // Use the new method to update UI with the loaded elapsed and lap times
      _stopwatchService.updateElapsedAndLapTime(elapsedTime, lapTime);
    } else if (_isRunning) {
      // If running, continue ticking to keep updating the time
      _stopwatchService.start();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _toggleStartStop() async {
    if (_isRunning) {
      if (kDebugMode) print("Stop button pressed");
      _stopwatchService.stop();
    } else {
      if (kDebugMode) print("Start button pressed");
      _stopwatchService.start();
    }
    setState(() {
      _isRunning = !_isRunning;
    });

    // Save state to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('currentState', _isRunning ? 'running' : 'paused');
  }

  void _reset() async {
    if (kDebugMode) print("Reset button pressed");
    _stopwatchService.reset();
    setState(() {
      _isRunning = false;
    });

    // Save state to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('currentState', 'stopped');
  }

  void _recordLap() {
    _stopwatchService.recordLap();
    setState(() {}); // Update the UI immediately after recording a lap
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stopwatch')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return _buildMainUI(context);
  }

  Scaffold _buildMainUI(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    final lapTextColor = theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stopwatch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.clean_hands),
            onPressed: () {
              _stopwatchService.clearSharedPreferences();
              if (kDebugMode) print("SharedPreferences cleared");
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              if (kDebugMode) print("_isRunning: $_isRunning");
            },
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StreamBuilder<Duration>(
            stream: _stopwatchService.elapsedTimeStream,
            builder: (context, snapshot) {
              final elapsed = snapshot.data ?? Duration.zero;
              final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
              final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
              final milliseconds = (elapsed.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
              return Text('$minutes:$seconds.$milliseconds', style: TextStyle(fontSize: 64, color: textColor));
            },
          ),
          StreamBuilder<Duration>(
            stream: _stopwatchService.lapTimeStream,
            builder: (context, snapshot) {
              final lapTime = snapshot.data ?? Duration.zero;
              final minutes = lapTime.inMinutes.remainder(60).toString().padLeft(2, '0');
              final seconds = lapTime.inSeconds.remainder(60).toString().padLeft(2, '0');
              final milliseconds = (lapTime.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
              return Text('$minutes:$seconds.$milliseconds', style: TextStyle(fontSize: 24, color: lapTextColor));
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _isRunning ? _recordLap : _reset,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(24),
                    fixedSize: const Size(100, 100),
                    backgroundColor: _isRunning ? Colors.grey : Colors.grey.shade700,
                    foregroundColor: textColor,
                  ),
                  child: Text(
                    _isRunning ? 'Lap' : 'Reset',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _toggleStartStop,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(24),
                    fixedSize: const Size(100, 100),
                    backgroundColor: _isRunning ? Colors.red : Colors.green,
                    foregroundColor: textColor,
                  ),
                  child: Text(
                    _isRunning ? 'Stop' : 'Start',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _stopwatchService.laps.length,
              itemBuilder: (context, index) {
                final laps = _stopwatchService.laps;
                final lap = laps[laps.length - 1 - index];
                final lapDuration = lap['duration']!;
                final minutes = lapDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
                final seconds = lapDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
                final milliseconds = (lapDuration.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');

                // Determine the shortest and longest lap
                Duration? shortestLap;
                Duration? longestLap;
                if (laps.length > 1) {
                  shortestLap = laps.map((lap) => lap['duration']!).reduce((a, b) => a < b ? a : b);
                  longestLap = laps.map((lap) => lap['duration']!).reduce((a, b) => a > b ? a : b);
                }

                // Apply color for shortest and longest laps
                Color lapTextColor = textColor;
                if (lapDuration == shortestLap) {
                  lapTextColor = Colors.green;
                } else if (lapDuration == longestLap) {
                  lapTextColor = Colors.red;
                }

                return ListTile(
                  title: Text('Lap ${laps.length - index}', style: TextStyle(color: lapTextColor, fontSize: 16)),
                  trailing: Text('$minutes:$seconds.$milliseconds', style: TextStyle(color: lapTextColor, fontSize: 16)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
