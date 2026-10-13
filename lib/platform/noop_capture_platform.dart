import 'capture_event.dart';
import 'capture_platform.dart';
import 'capture_signal.dart';

/// Used on platforms without notification capture (for example Windows).
final class NoopCapturePlatform implements CapturePlatform {
  const NoopCapturePlatform();

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
  Future<List<CaptureEvent>> peek({int max = 100}) async =>
      const <CaptureEvent>[];

  @override
  Future<void> ack(int upToSeq) async {}

  @override
  Stream<CaptureSignal> get signals => const Stream<CaptureSignal>.empty();
}
