import 'capture_event.dart';
import 'capture_signal.dart';

/// Bridge to the native notification listener. Implementations: the Android
/// method channel, and a no-op for platforms without notification capture.
abstract interface class CapturePlatform {
  Future<String> packageName();

  Future<bool> isAccessGranted();

  Future<bool> isServiceConnected();

  /// Opens Android's Notification Access settings. False if unavailable.
  Future<bool> openAccessSettings();

  Future<void> requestRebind();

  /// Oldest queued events first, without removing them.
  Future<List<CaptureEvent>> peek({int max = 100});

  /// Removes every event with a sequence number up to [upToSeq].
  Future<void> ack(int upToSeq);

  Stream<CaptureSignal> get signals;
}
