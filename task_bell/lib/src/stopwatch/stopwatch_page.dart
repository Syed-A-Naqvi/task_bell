import 'package:flutter/material.dart';
import '../settings/settings_view.dart';
import 'stopwatch.dart';

class StopwatchPage extends StatefulWidget {
  const StopwatchPage({super.key});

  @override
  _StopwatchPageState createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage> {
  final StopwatchService _stopwatchService = StopwatchService();
  bool _isRunning = false;

  @override
  void dispose() {
    _stopwatchService.dispose();
    super.dispose();
  }

  void _toggleStartStop() {
    setState(() {
      if (_isRunning) {
        _stopwatchService.stop();
      } else {
        _stopwatchService.start();
      }
      _isRunning = !_isRunning;
    });
  }

  void _reset() {
    setState(() {
      _stopwatchService.reset();
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: _isRunning ? _stopwatchService.recordLap : _reset,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(24),
                    fixedSize: const Size(100, 100),
                    backgroundColor: _isRunning ? Colors.grey : Colors.grey.shade700,
                    foregroundColor: textColor,
                  ),
                  child: Text(
                    _isRunning ? 'Lap' : 'Reset',
                    style: const TextStyle(fontSize: 20)
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
            child: StreamBuilder<List<Duration>>(
              stream: _stopwatchService.lapsStream,
              builder: (context, snapshot) {
                final laps = snapshot.data ?? [];
                if (laps.isEmpty) {
                  return const Center(child: Text('No laps recorded'));
                }

                Duration? fastestLap;
                Duration? slowestLap;
                if (laps.length > 1) {
                  fastestLap = laps.reduce((a, b) => a < b ? a : b);
                  slowestLap = laps.reduce((a, b) => a > b ? a : b);
                }

                return ListView.builder(
                  itemCount: laps.length,
                  itemBuilder: (context, index) {
                    final lap = laps[laps.length - 1 - index];
                    final minutes = lap.inMinutes.remainder(60).toString().padLeft(2, '0');
                    final seconds = lap.inSeconds.remainder(60).toString().padLeft(2, '0');
                    final milliseconds = (lap.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
                    Color lapTextColor = textColor;
                    if (lap == fastestLap) {
                      lapTextColor = Colors.green;
                    } else if (lap == slowestLap) {
                      lapTextColor = Colors.red;
                    }
                    return ListTile(
                      title: Text('Lap ${laps.length - index}'),
                      trailing: Text('$minutes:$seconds.$milliseconds', style: TextStyle(color: lapTextColor)),
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