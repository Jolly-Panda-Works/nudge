/// Lightweight notifications from the native side. Data itself is never sent
/// through signals; it is read from the native queue.
sealed class CaptureSignal {
  const CaptureSignal();
}

/// Something new was queued natively; drain the queue.
final class WakeSignal extends CaptureSignal {
  const WakeSignal();
}

/// The listener service connected or disconnected.
final class StateSignal extends CaptureSignal {
  const StateSignal({required this.connected});

  final bool connected;
}
