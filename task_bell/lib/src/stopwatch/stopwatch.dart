import 'dart:async';

class StopwatchService {
  final List<Map<String, Duration>> _laps = [];
  final StreamController<Duration> _elapsedTimeController = StreamController<Duration>.broadcast();
  final StreamController<List<Map<String, Duration>>> _lapsController = StreamController<List<Map<String, Duration>>>.broadcast();
  final StreamController<Duration> _lapTimeController = StreamController<Duration>.broadcast();
  Timer? _timer;

  int? _startTimeEpoch; // Epoch time in ms when stopwatch started or resumed
  int? _lapStartTimeEpoch; // Epoch time in ms for the start of each lap
  int? _lastStopTimeEpoch; // Epoch time in ms when the stopwatch was last stopped
  Duration _pausedDuration = Duration.zero; // Total duration the stopwatch has been paused
  Duration _lapPausedDuration = Duration.zero; // Total paused duration specific to the current lap

  Stream<Duration> get elapsedTimeStream => _elapsedTimeController.stream;
  Stream<List<Map<String, Duration>>> get lapsStream => _lapsController.stream;
  Stream<Duration> get lapTimeStream => _lapTimeController.stream;

  void start() {
    final currentTimeEpoch = DateTime.now().millisecondsSinceEpoch;
    if (_startTimeEpoch == null) {
      // First start
      _startTimeEpoch = currentTimeEpoch;
      _lapStartTimeEpoch = currentTimeEpoch;
    } else if (_lastStopTimeEpoch != null) {
      // Resuming after pause
      _pausedDuration += Duration(milliseconds: currentTimeEpoch - _lastStopTimeEpoch!);
      _lapPausedDuration += Duration(milliseconds: currentTimeEpoch - _lastStopTimeEpoch!);
      _lastStopTimeEpoch = null;
    }
    _tick();
  }

  void stop() {
    _timer?.cancel();
    _lastStopTimeEpoch = DateTime.now().millisecondsSinceEpoch;
  }

  void reset() {
    _timer?.cancel();
    _startTimeEpoch = null;
    _lapStartTimeEpoch = null;
    _lastStopTimeEpoch = null;
    _pausedDuration = Duration.zero;
    _lapPausedDuration = Duration.zero;
    _laps.clear();
    _elapsedTimeController.add(Duration.zero);
    _lapsController.add(_laps);
    _lapTimeController.add(Duration.zero);
  }

  void recordLap() {
    if (_lapStartTimeEpoch == null || _startTimeEpoch == null) return;

    final currentLapEndTimeEpoch = DateTime.now().millisecondsSinceEpoch;
    final adjustedLapStartEpoch = _lapStartTimeEpoch! - _startTimeEpoch! - _pausedDuration.inMilliseconds;

    final lapDuration = Duration(milliseconds: currentLapEndTimeEpoch - _lapStartTimeEpoch! - _lapPausedDuration.inMilliseconds);

    _laps.add({
      'start': Duration(milliseconds: adjustedLapStartEpoch),
      'end': Duration(milliseconds: currentLapEndTimeEpoch - _startTimeEpoch! - _pausedDuration.inMilliseconds),
      'duration': lapDuration,
    });

    _lapsController.add(List.from(_laps));

    // Reset lap start time to current time for the next lap and clear lap paused duration
    _lapStartTimeEpoch = currentLapEndTimeEpoch;
    _lapPausedDuration = Duration.zero;
    _lapTimeController.add(Duration.zero); // Reset lap time displayed
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (_startTimeEpoch == null || _lastStopTimeEpoch != null) {
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

  void dispose() {
    _elapsedTimeController.close();
    _lapsController.close();
    _lapTimeController.close();
    _timer?.cancel();
  }
}
