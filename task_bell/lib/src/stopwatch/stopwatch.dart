import 'dart:async';

class StopwatchService {
  final Stopwatch _stopwatch = Stopwatch();
  final List<Duration> _laps = [];
  final StreamController<Duration> _elapsedTimeController = StreamController<Duration>.broadcast();
  final StreamController<List<Duration>> _lapsController = StreamController<List<Duration>>.broadcast();
  final StreamController<Duration> _lapTimeController = StreamController<Duration>.broadcast();
  Timer? _timer;
  Duration _lapTime = Duration.zero;

  Stream<Duration> get elapsedTimeStream => _elapsedTimeController.stream;
  Stream<List<Duration>> get lapsStream => _lapsController.stream;
  Stream<Duration> get lapTimeStream => _lapTimeController.stream;

  void start() {
    _stopwatch.start();
    _tick();
  }

  void stop() {
    _stopwatch.stop();
    _timer?.cancel();
  }

  void reset() {
    _stopwatch.reset();
    _laps.clear();
    _lapTime = Duration.zero;
    _elapsedTimeController.add(_stopwatch.elapsed);
    _lapsController.add(_laps);
    _lapTimeController.add(_lapTime);
  }

  void recordLap() {
    _laps.add(_lapTime);
    _lapsController.add(List.from(_laps));
    _lapTime = Duration.zero;
    _lapTimeController.add(_lapTime);
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (!_stopwatch.isRunning) {
        timer.cancel();
      }
      _elapsedTimeController.add(_stopwatch.elapsed);
      _lapTime += const Duration(milliseconds: 10);
      _lapTimeController.add(_lapTime);
    });
  }

  void dispose() {
    _elapsedTimeController.close();
    _lapsController.close();
    _lapTimeController.close();
    _timer?.cancel();
  }
}