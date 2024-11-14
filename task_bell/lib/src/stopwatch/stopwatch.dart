import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StopwatchService {
  final List<Map<String, Duration>> laps = [];
  final StreamController<Duration> _elapsedTimeController = StreamController<Duration>.broadcast();
  final StreamController<List<Map<String, Duration>>> lapsController = StreamController<List<Map<String, Duration>>>.broadcast();
  final StreamController<Duration> _lapTimeController = StreamController<Duration>.broadcast();
  final StreamController<String> _stateController = StreamController<String>.broadcast(); // Stream for state changes
  Timer? _timer;

  int? _startTimeEpoch; // Epoch time in ms when stopwatch started or resumed
  int? _lapStartTimeEpoch; // Epoch time in ms for the start of each lap
  int? _lastStopTimeEpoch; // Epoch time in ms when the stopwatch was last stopped
  Duration _pausedDuration = Duration.zero; // Total duration the stopwatch has been paused
  Duration _lapPausedDuration = Duration.zero; // Total paused duration specific to the current lap
  String _currentState = 'stopped'; // Default state

  String get initialState => _currentState;

  StopwatchService() {
    if (kDebugMode) {
      if (kDebugMode) print('Initializing StopwatchService and loading state...');
    }
    _loadState();
  }

  Stream<Duration> get elapsedTimeStream => _elapsedTimeController.stream;
  Stream<List<Map<String, Duration>>> get lapsStream => lapsController.stream;
  Stream<Duration> get lapTimeStream => _lapTimeController.stream;
  Stream<String> get stateStream => _stateController.stream; // Expose state stream for UI

  String get currentState => _currentState;

  void setElapsedAndLapTime(Duration elapsed, Duration lap) {
    _elapsedTimeController.add(elapsed);
    _lapTimeController.add(lap);
  }

  Future<void> start() async {
    final currentTimeEpoch = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode) {
      print('Starting stopwatch at epoch: $currentTimeEpoch');
    }
    if (_startTimeEpoch == null) {
      if (kDebugMode) {
        print('First start detected, setting start time and lap start time to current epoch');
      }
      _startTimeEpoch = currentTimeEpoch;
      _lapStartTimeEpoch = currentTimeEpoch;
    } else if (_lastStopTimeEpoch != null) {
      if (kDebugMode) {
        print('Resuming stopwatch, adding paused duration to both total and lap durations');
      }
      _pausedDuration += Duration(milliseconds: currentTimeEpoch - _lastStopTimeEpoch!);
      _lapPausedDuration += Duration(milliseconds: currentTimeEpoch - _lastStopTimeEpoch!);
      _lastStopTimeEpoch = null;
    }
    _currentState = 'running'; // Update state to running
    _stateController.add(_currentState); // Notify UI of state change
    await _saveState(); // Save state on start or resume
    _tick();
  }

  void stop() {
    _timer?.cancel();
    _lastStopTimeEpoch = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode) {
      print('Stopping stopwatch at epoch: $_lastStopTimeEpoch');
    }
    _currentState = 'paused'; // Update state to paused
    _stateController.add(_currentState); // Notify UI of state change
    _saveState(); // Save state on stop
  }

  void reset() {
    if (kDebugMode) {
      print('Resetting stopwatch...');
    }
    _timer?.cancel();
    _startTimeEpoch = null;
    _lapStartTimeEpoch = null;
    _lastStopTimeEpoch = null;
    _pausedDuration = Duration.zero;
    _lapPausedDuration = Duration.zero;
    laps.clear();
    _currentState = 'stopped'; // Update state to stopped
    _stateController.add(_currentState); // Notify UI of state change
    _saveState(); // Save reset state
    _elapsedTimeController.add(Duration.zero);
    lapsController.add(laps);
    _lapTimeController.add(Duration.zero);
  }


  void recordLap() {
    if (_lapStartTimeEpoch == null || _startTimeEpoch == null) {
      if (kDebugMode) {
        print('Cannot record lap: lap start time or start time is null');
      }
      return;
    }

    final currentLapEndTimeEpoch = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode) {
      print('Recording lap at epoch: $currentLapEndTimeEpoch');
    }
    final adjustedLapStartEpoch = _lapStartTimeEpoch! - _startTimeEpoch! - _pausedDuration.inMilliseconds;

    final lapDuration = Duration(milliseconds: currentLapEndTimeEpoch - _lapStartTimeEpoch! - _lapPausedDuration.inMilliseconds);

    laps.add({
      'start': Duration(milliseconds: adjustedLapStartEpoch),
      'end': Duration(milliseconds: currentLapEndTimeEpoch - _startTimeEpoch! - _pausedDuration.inMilliseconds),
      'duration': lapDuration,
    });

    lapsController.add(List.from(laps));

    // Reset lap start time to current time for the next lap and clear lap paused duration
    _lapStartTimeEpoch = currentLapEndTimeEpoch;
    _lapPausedDuration = Duration.zero;
    _lapTimeController.add(Duration.zero); // Reset lap time displayed

    if (kDebugMode) {
      print('Lap recorded. Updated laps list: $laps');
    }
    _saveState(); // Save state after recording lap
  }

  void _tick() {
    _timer?.cancel();
    if (kDebugMode) {
      print('Starting tick timer for elapsed time and lap time updates...');
    }
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (_startTimeEpoch == null || _lastStopTimeEpoch != null) {
        if (kDebugMode) {
          print('Stopping tick timer because stopwatch is either not started or paused');
        }
        timer.cancel();
        return;
      }

      final currentTimeEpoch = DateTime.now().millisecondsSinceEpoch;
      final adjustedElapsedTime = Duration(milliseconds: currentTimeEpoch - _startTimeEpoch! - _pausedDuration.inMilliseconds);
      final adjustedLapTime = Duration(milliseconds: currentTimeEpoch - _lapStartTimeEpoch! - _lapPausedDuration.inMilliseconds);

      _elapsedTimeController.add(adjustedElapsedTime);
      _lapTimeController.add(adjustedLapTime);
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    if (kDebugMode) {
      print('Saving state to SharedPreferences...');
    }

    // Convert `_laps` to a JSON string
    final lapsJson = jsonEncode(laps.map((lap) => {
      'start': lap['start']!.inMilliseconds,
      'end': lap['end']!.inMilliseconds,
      'duration': lap['duration']!.inMilliseconds,
    }).toList());

    prefs.setString('laps', lapsJson); // Save laps list as JSON
    prefs.setInt('lapCount', laps.length); // Save the lap count

    // Save other state information
    prefs.setInt('startTimeEpoch', _startTimeEpoch ?? 0);
    prefs.setInt('lapStartTimeEpoch', _lapStartTimeEpoch ?? 0);
    prefs.setInt('pausedDuration', _pausedDuration.inMilliseconds);
    prefs.setInt('lapPausedDuration', _lapPausedDuration.inMilliseconds);
    prefs.setString('currentState', _currentState);

    if (_lastStopTimeEpoch != null) {
      prefs.setInt('lastStopTimeEpoch', _lastStopTimeEpoch!);
    } else {
      prefs.remove('lastStopTimeEpoch');
    }

    if (kDebugMode) {
      print('State saved: startTimeEpoch=$_startTimeEpoch, lapStartTimeEpoch=$_lapStartTimeEpoch, lastStopTimeEpoch=$_lastStopTimeEpoch, pausedDuration=$_pausedDuration, lapPausedDuration=$_lapPausedDuration, currentState=$_currentState, laps=$laps');
    }
  }


  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    if (kDebugMode) print('Loading state from SharedPreferences...');

    // Load laps list from JSON string and parse it
    final lapsJson = prefs.getString('laps');
    if (lapsJson != null) {
      final List<dynamic> lapsList = jsonDecode(lapsJson);
      laps.clear();
      for (var lapData in lapsList) {
        laps.add({
          'start': Duration(milliseconds: lapData['start']),
          'end': Duration(milliseconds: lapData['end']),
          'duration': Duration(milliseconds: lapData['duration']),
        });
      }
      // Add loaded laps directly to stream
      lapsController.add(List.from(laps));
    }


    // Load lap count (for debugging or UI display purposes)
    final lapCount = prefs.getInt('lapCount') ?? 0;
    if (kDebugMode) {
      print('Loaded lap count: $lapCount');
    }

    // Load other state information
    _startTimeEpoch = prefs.getInt('startTimeEpoch');
    if (_startTimeEpoch == 0) _startTimeEpoch = null;

    _lapStartTimeEpoch = prefs.getInt('lapStartTimeEpoch');
    if (_lapStartTimeEpoch == 0) _lapStartTimeEpoch = null;

    _lastStopTimeEpoch = prefs.getInt('lastStopTimeEpoch');
    if (_lastStopTimeEpoch == 0) _lastStopTimeEpoch = null;

    _pausedDuration = Duration(milliseconds: prefs.getInt('pausedDuration') ?? 0);
    _lapPausedDuration = Duration(milliseconds: prefs.getInt('lapPausedDuration') ?? 0);
    _currentState = prefs.getString('currentState') ?? 'stopped';

    if (kDebugMode) {
      print('State loaded: startTimeEpoch=$_startTimeEpoch, lapStartTimeEpoch=$_lapStartTimeEpoch, lastStopTimeEpoch=$_lastStopTimeEpoch, pausedDuration=$_pausedDuration, lapPausedDuration=$_lapPausedDuration, currentState=$_currentState, laps=$laps');
    }

    // Apply the loaded state to update the UI correctly
    if (_currentState == 'running' && _startTimeEpoch != null) {
      final currentTimeEpoch = DateTime.now().millisecondsSinceEpoch;
      final adjustedElapsedTime = Duration(milliseconds: currentTimeEpoch - _startTimeEpoch! - _pausedDuration.inMilliseconds);
      final adjustedLapTime = Duration(milliseconds: currentTimeEpoch - _lapStartTimeEpoch! - _lapPausedDuration.inMilliseconds);

      _elapsedTimeController.add(adjustedElapsedTime);
      _lapTimeController.add(adjustedLapTime);
      _tick();
    } else if (_currentState == 'paused') {
      final elapsedTime = Duration(milliseconds: _lastStopTimeEpoch! - _startTimeEpoch! - _pausedDuration.inMilliseconds);
      final lapTime = Duration(milliseconds: _lastStopTimeEpoch! - _lapStartTimeEpoch! - _lapPausedDuration.inMilliseconds);

      _elapsedTimeController.add(elapsedTime);
      _lapTimeController.add(lapTime);
    } else {
      _elapsedTimeController.add(Duration.zero);
      _lapTimeController.add(Duration.zero);
    }
  }


  Future<void> dispose() async {
    if (kDebugMode) {
      print('Saving state before disposing StopwatchService...');
    }
    await _saveState(); // Ensure state is saved completely before disposal
    if (kDebugMode) {
      print('Disposing StopwatchService...');
    }
    _elapsedTimeController.close();
    lapsController.close();
    _lapTimeController.close();
    _stateController.close(); // Close state stream controller
    _timer?.cancel();
  }


  Future<void> clearSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (kDebugMode) {
      print("SharedPreferences cleared.");
    }
  }

  void updateElapsedAndLapTime(Duration elapsedTime, Duration lapTime) {
    _elapsedTimeController.add(elapsedTime);
    _lapTimeController.add(lapTime);
  }

}
