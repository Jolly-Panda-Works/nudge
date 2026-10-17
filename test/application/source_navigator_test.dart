import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/application/source_navigator.dart';
import 'package:nudge/platform/noop_capture_platform.dart';

import '../support/fake_capture_platform.dart';

void main() {
  late FakeCapturePlatform platform;
  late SourceNavigator navigator;

  setUp(() {
    platform = FakeCapturePlatform();
    navigator = SourceNavigator(platform);
  });

  test('uses the live notification action first', () async {
    platform.liveKeys.add('k1');
    platform.launchablePackages.add('com.chat');

    final outcome = await navigator.open(
      packageName: 'com.chat',
      notificationKey: 'k1',
    );

    expect(outcome, SourceOpenOutcome.openedOriginal);
    expect(platform.openCalls, <String>['live:k1']);
  });

  test('falls back to the app launch intent when the action is gone', () async {
    platform.launchablePackages.add('com.chat');

    final outcome = await navigator.open(
      packageName: 'com.chat',
      notificationKey: 'k1',
    );

    expect(outcome, SourceOpenOutcome.openedApp);
    expect(platform.openCalls, <String>['live:k1', 'app:com.chat']);
  });

  test('reports unavailable when nothing can be opened', () async {
    final outcome = await navigator.open(
      packageName: 'com.chat',
      notificationKey: 'k1',
    );

    expect(outcome, SourceOpenOutcome.unavailable);
    expect(platform.openCalls, <String>['live:k1', 'app:com.chat']);
  });

  test('skips the live step without a notification key', () async {
    platform.launchablePackages.add('com.chat');

    final outcome = await navigator.open(packageName: 'com.chat');

    expect(outcome, SourceOpenOutcome.openedApp);
    expect(platform.openCalls, <String>['app:com.chat']);
  });

  test('an empty package makes the app step unavailable', () async {
    final outcome = await navigator.open(packageName: '');

    expect(outcome, SourceOpenOutcome.unavailable);
    expect(platform.openCalls, isEmpty);
  });

  test('does nothing on a platform without support', () async {
    final outcome = await SourceNavigator(
      const NoopCapturePlatform(),
    ).open(packageName: 'com.chat', notificationKey: 'k1');

    expect(outcome, SourceOpenOutcome.unavailable);
  });
}
