import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/application/capture_status_controller.dart';

import '../support/fake_capture_platform.dart';

class ThrowingPlatform extends FakeCapturePlatform {
  @override
  Future<bool> isAccessGranted() async => throw Exception('channel failure');
}

void main() {
  test('refresh publishes the current access and listener state', () async {
    final platform = FakeCapturePlatform()
      ..accessGranted = true
      ..connected = false;
    final controller = CaptureStatusController(platform);
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);

    expect(controller.status, isNull);
    await controller.refresh();

    expect(controller.status!.accessGranted, isTrue);
    expect(controller.status!.listenerConnected, isFalse);
    expect(notifications, 1);

    platform.connected = true;
    await controller.refresh();
    expect(controller.status!.listenerConnected, isTrue);
    expect(notifications, 2);
  });

  test('exposes whether the platform is supported', () {
    final controller = CaptureStatusController(
      FakeCapturePlatform()..supported = false,
    );
    addTearDown(controller.dispose);
    expect(controller.isSupported, isFalse);
  });

  test('a failing platform keeps the previous status', () async {
    final controller = CaptureStatusController(ThrowingPlatform());
    addTearDown(controller.dispose);

    await controller.refresh();
    expect(controller.status, isNull);
  });
}
