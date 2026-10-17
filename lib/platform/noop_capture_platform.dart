import 'capture_event.dart';
import 'capture_platform.dart';
import 'capture_signal.dart';

/// Used on platforms without notification capture (for example Windows).
final class NoopCapturePlatform implements CapturePlatform {
  const NoopCapturePlatform();

  @override
  bool get isSupported => false;

  @override
  Future<String> packageName() async => '';

  @override
  Future<bool> isAccessGranted() async => false;

  @override
  Future<bool> isServiceConnected() async => false;

  @override
  Future<bool> openAccessSettings() async => false;

  @override
  Future<void> requestRebind() async {}

  @override
  Future<bool> openLiveContent(String notificationKey) async => false;

  @override
  Future<bool> openSourceApp(String packageName) async => false;

  @override
  Future<List<CaptureEvent>> peek({int max = 100}) async =>
      const <CaptureEvent>[];

  @override
  Future<void> clearQueue() async {}

  @override
  Future<void> ack(int upToSeq) async {}

  @override
  Stream<CaptureSignal> get signals => const Stream<CaptureSignal>.empty();
}
