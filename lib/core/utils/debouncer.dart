import 'dart:async';

/// Simple debouncer used to prevent rapid emotion flicker.
class Debouncer {
  Debouncer({required this.duration});
  final Duration duration;
  Timer? _timer;

  void call(void Function() action) {
    _timer?.cancel();
    if (duration == Duration.zero) {
      action();
      return;
    }
    _timer = Timer(duration, action);
  }

  void dispose() => _timer?.cancel();
}
