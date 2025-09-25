import 'dart:async';

class ScaleSimulator {
  final List<double> _weights = [5.7, 6.1, 48.1, 105.2, 414.9, 822.1];
  int _index = 0;
  final _controller = StreamController<double>.broadcast();

  Stream<double> get stream => _controller.stream;

  Timer? _timer;

  void start() {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _controller.add(_weights[_index]);
      _index = (_index + 1) % _weights.length;
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
