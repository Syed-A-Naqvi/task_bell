import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../settings/settings_view.dart';
import 'stopwatch.dart';

class StopwatchPage extends StatefulWidget {
  const StopwatchPage({super.key});

  @override
  StopwatchPageState createState() => StopwatchPageState();
}

class StopwatchPageState extends State<StopwatchPage> {
  late StopwatchService _stopwatchService;

  @override
  void initState() {
    super.initState();
    _stopwatchService = StopwatchService(); // Initialize the service
  }

  @override
  void dispose() {
    _stopwatchService.dispose();
    super.dispose();
  }

  void _toggleStartStop() {
    if (_stopwatchService.currentState == 'running') {
      if (kDebugMode) print("Stop button pressed");
      _stopwatchService.stop();
    } else {
      if (kDebugMode) print("Start button pressed");
      _stopwatchService.start();
    }
  }

  void _reset() {
    if (kDebugMode) print("Reset button pressed");
    _stopwatchService.reset();
  }

  void _recordLap() {
    _stopwatchService.recordLap();
  }

  @override
  Widget build(BuildContext context) {
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
              if (kDebugMode) print("Current state: ${_stopwatchService.currentState}");
            },
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Elapsed Time Display
          StreamBuilder<Duration>(
            stream: _stopwatchService.elapsedTimeStream,
            initialData: Duration.zero,
            builder: (context, snapshot) {
              final elapsed = snapshot.data ?? Duration.zero;
              final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
              final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
              final milliseconds = (elapsed.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
              return Text('$minutes:$seconds.$milliseconds', style: TextStyle(fontSize: 64, color: textColor));
            },
          ),
          // Lap Time Display
          StreamBuilder<Duration>(
            stream: _stopwatchService.lapTimeStream,
            initialData: Duration.zero,
            builder: (context, snapshot) {
              final lapTime = snapshot.data ?? Duration.zero;
              final minutes = lapTime.inMinutes.remainder(60).toString().padLeft(2, '0');
              final seconds = lapTime.inSeconds.remainder(60).toString().padLeft(2, '0');
              final milliseconds = (lapTime.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
              return Text('$minutes:$seconds.$milliseconds', style: TextStyle(fontSize: 24, color: lapTextColor));
            },
          ),
          // Start/Stop and Lap/Reset Buttons
          StreamBuilder<String>(
            stream: _stopwatchService.stateStream,
            initialData: _stopwatchService.currentState,
            builder: (context, snapshot) {
              final currentState = snapshot.data ?? 'stopped';
              final isRunning = currentState == 'running';

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Lap or Reset Button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: isRunning ? _recordLap : _reset,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24),
                        fixedSize: const Size(100, 100),
                        backgroundColor: isRunning ? Colors.grey : Colors.grey.shade700,
                        foregroundColor: textColor,
                      ),
                      child: Text(
                        isRunning ? 'Lap' : 'Reset',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  // Start or Stop Button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _toggleStartStop,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24),
                        fixedSize: const Size(100, 100),
                        backgroundColor: isRunning ? Colors.red : Colors.green,
                        foregroundColor: textColor,
                      ),
                      child: Text(
                        isRunning ? 'Stop' : 'Start',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Laps List
          Expanded(
            child: StreamBuilder<List<Map<String, Duration>>>(
              stream: _stopwatchService.lapsStream,
              initialData: _stopwatchService.laps,
              builder: (context, snapshot) {
                final laps = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: laps.length,
                  itemBuilder: (context, index) {
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
