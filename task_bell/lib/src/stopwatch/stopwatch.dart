import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StopwatchService {
  final List<Map<String, Duration>> laps = [];
  final StreamController<Duration> _elapsedTimeController = StreamController<Duration>.broadcast();
  final StreamController<List<Map<String, Duration>>> lapsController = StreamController<List<Map<String, Duration>>>.broadcast();
  final StreamController<Duration> _lapTimeController = StreamController<Duration>.broadcast();
  final StreamController<String> _stateController = StreamController<String>.broadcast();

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
      print('Initializing StopwatchService and loading state...');
    }
    _loadState();
  }

  Stream<Duration> get elapsedTimeStream => _elapsedTimeController.stream;
  Stream<List<Map<String, Duration>>> get lapsStream => lapsController.stream;
  Stream<Duration> get lapTimeStream => _lapTimeController.stream;
  Stream<String> get stateStream => _stateController.stream;

  String get currentState => _currentState;

  Future<void> start() async {
    final currentTimeEpoch = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode) {
      print('Starting stopwatch at epoch: $currentTimeEpoch');
    }
    if (_startTimeEpoch == null) {
      _startTimeEpoch = currentTimeEpoch;
      _lapStartTimeEpoch = currentTimeEpoch;
    } else if (_lastStopTimeEpoch != null) {
      final pausedTime = currentTimeEpoch - _lastStopTimeEpoch!;
      _pausedDuration += Duration(milliseconds: pausedTime);
      _lapPausedDuration += Duration(milliseconds: pausedTime);
      _lastStopTimeEpoch = null;
    }
    _currentState = 'running';
    _stateController.add(_currentState);
    await _saveState();
    _startTimer();
  }

  void stop() {
    _timer?.cancel();
    _lastStopTimeEpoch = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode) {
      print('Stopping stopwatch at epoch: $_lastStopTimeEpoch');
    }
    _currentState = 'paused';
    _stateController.add(_currentState);

    // Emit the current elapsed and lap durations
    final currentTimeEpoch = _lastStopTimeEpoch!;
    final adjustedElapsedTime = Duration(milliseconds: currentTimeEpoch - _startTimeEpoch! - _pausedDuration.inMilliseconds);
    final adjustedLapTime = Duration(milliseconds: currentTimeEpoch - _lapStartTimeEpoch! - _lapPausedDuration.inMilliseconds);

    _elapsedTimeController.add(adjustedElapsedTime);
    _lapTimeController.add(adjustedLapTime);

    _saveState();
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
    _currentState = 'stopped';
    _stateController.add(_currentState);
    _saveState();
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
    final lapDuration = Duration(
      milliseconds: currentLapEndTimeEpoch - _lapStartTimeEpoch! - _lapPausedDuration.inMilliseconds,
    );

    laps.add({
      'start': Duration(milliseconds: _lapStartTimeEpoch! - _startTimeEpoch! - _pausedDuration.inMilliseconds),
      'end': Duration(milliseconds: currentLapEndTimeEpoch - _startTimeEpoch! - _pausedDuration.inMilliseconds),
      'duration': lapDuration,
    });

    lapsController.add(List.from(laps));

    // Reset lap start time to current time for the next lap and clear lap paused duration
    _lapStartTimeEpoch = currentLapEndTimeEpoch;
    _lapPausedDuration = Duration.zero;
    _lapTimeController.add(Duration.zero);

    if (kDebugMode) {
      print('Lap recorded. Updated laps list: $laps');
    }
    _saveState();
  }

  void _startTimer() {
    _timer?.cancel();
    if (kDebugMode) {
      print('Starting timer for elapsed time and lap time updates...');
    }
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (_startTimeEpoch == null || _currentState != 'running') {
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
    try {
      final prefs = await SharedPreferences.getInstance();
      if (kDebugMode) {
        print('Saving state to SharedPreferences...');
      }

      // Convert laps to JSON
      final lapsJson = jsonEncode(laps.map((lap) => {
        'start': lap['start']!.inMilliseconds,
        'end': lap['end']!.inMilliseconds,
        'duration': lap['duration']!.inMilliseconds,
      }).toList());

      prefs.setString('laps', lapsJson);
      prefs.setInt('startTimeEpoch', _startTimeEpoch ?? 0);
      prefs.setInt('lapStartTimeEpoch', _lapStartTimeEpoch ?? 0);
      prefs.setInt('pausedDuration', _pausedDuration.inMilliseconds);
      prefs.setInt('lapPausedDuration', _lapPausedDuration.inMilliseconds);
      prefs.setString('currentState', _currentState);
      prefs.setInt('lastStopTimeEpoch', _lastStopTimeEpoch ?? 0);

      if (kDebugMode) {
        print('State saved: startTimeEpoch=$_startTimeEpoch, lapStartTimeEpoch=$_lapStartTimeEpoch, lastStopTimeEpoch=$_lastStopTimeEpoch, pausedDuration=$_pausedDuration, lapPausedDuration=$_lapPausedDuration, currentState=$_currentState, laps=$laps');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving state: $e');
      }
    }
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (kDebugMode) print('Loading state from SharedPreferences...');

      // Load laps
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
        lapsController.add(List.from(laps));
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

      // Restore the elapsed and lap times based on the current state
      if (_currentState == 'running' && _startTimeEpoch != null) {
        _startTimer();
      } else if (_currentState == 'paused' && _lastStopTimeEpoch != null) {
        final elapsedTime = Duration(milliseconds: _lastStopTimeEpoch! - _startTimeEpoch! - _pausedDuration.inMilliseconds);
        final lapTime = Duration(milliseconds: _lastStopTimeEpoch! - _lapStartTimeEpoch! - _lapPausedDuration.inMilliseconds);

        _elapsedTimeController.add(elapsedTime);
        _lapTimeController.add(lapTime);
      } else {
        _elapsedTimeController.add(Duration.zero);
        _lapTimeController.add(Duration.zero);
      }

      // Emit the current state
      _stateController.add(_currentState);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading state: $e');
      }
    }
  }

  Future<void> dispose() async {
    if (kDebugMode) {
      print('Saving state before disposing StopwatchService...');
    }
    await _saveState();
    if (kDebugMode) {
      print('Disposing StopwatchService...');
    }
    _elapsedTimeController.close();
    lapsController.close();
    _lapTimeController.close();
    _stateController.close();
    _timer?.cancel();
  }

  Future<void> clearSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (kDebugMode) {
        print("SharedPreferences cleared.");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing SharedPreferences: $e');
      }
    }
  }
}
