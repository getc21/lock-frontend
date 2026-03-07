import 'dart:async';

/// Utility class for debouncing actions (e.g., search input).
/// Delays execution until [duration] has passed without new calls.
class Debouncer {
  final Duration duration;
  Timer? _timer;

  Debouncer({this.duration = const Duration(milliseconds: 300)});

  /// Run [action] after the debounce delay.
  /// Cancels any previously scheduled action.
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Cancel any pending action.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Whether a debounced action is currently pending.
  bool get isPending => _timer?.isActive ?? false;

  /// Dispose of the debouncer. Call this in [State.dispose].
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
