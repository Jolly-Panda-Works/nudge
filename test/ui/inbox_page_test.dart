import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/fixtures.dart';

void main() {
  testWidgets('empty inbox explains what will happen', (tester) async {
    final harness = AppHarness();
    await harness.pump(tester);

    expect(find.text('No notifications yet'), findsOneWidget);
    expect(
      find.text('New notifications from other apps will appear here.'),
      findsOneWidget,
    );
    expect(find.text('Notification access is off'), findsNothing);
  });

  testWidgets('banner and hint appear when access is off', (tester) async {
    final harness = AppHarness(accessGranted: false, connected: false);
    await harness.pump(tester);

    expect(find.text('Notification access is off'), findsOneWidget);
    expect(
      find.text('Enable Notification Access to start capturing.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Enable'));
    await tester.pumpAndSettle();
    expect(harness.platform.settingsOpens, 1);
  });

  testWidgets('banner offers reconnect when the listener is down', (
    tester,
  ) async {
    final harness = AppHarness(connected: false);
    await harness.pump(tester);

    expect(find.text('Listener not connected'), findsOneWidget);
    await tester.tap(find.text('Reconnect'));
    await tester.pumpAndSettle();
    expect(harness.platform.rebindRequests, 1);
  });

  testWidgets('unsupported platforms show no banner', (tester) async {
    final harness = AppHarness(
      accessGranted: false,
      connected: false,
      supported: false,
    );
    await harness.pump(tester);

    expect(find.text('Notification access is off'), findsNothing);
    expect(
      find.text('Notification capture is available on Android.'),
      findsOneWidget,
    );
  });

  testWidgets('lists a notification and opens its details', (tester) async {
    final harness = AppHarness()
      ..notifications.add(captured(title: 'Sara', text: 'Hello there'));
    await harness.pump(tester);

    expect(find.text('Sara'), findsOneWidget);
    expect(find.text('Hello there'), findsOneWidget);
    expect(find.textContaining('Chat'), findsWidgets);

    await tester.tap(find.text('Sara'));
    await tester.pumpAndSettle();

    expect(find.text('Notification details'), findsOneWidget);
    expect(find.text('com.chat'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('redacted notifications show a hidden-content title', (
    tester,
  ) async {
    final harness = AppHarness()
      ..notifications.add(captured(title: null, text: null));
    await harness.pump(tester);

    expect(find.text('Content hidden'), findsOneWidget);
  });

  testWidgets('dismissed notifications appear only under All', (tester) async {
    final harness = AppHarness();
    final notification = captured(title: 'Sara');
    harness.notifications.add(notification);
    await harness.notifications.markRemoved(notification.key);
    await harness.pump(tester);

    expect(find.text('No notifications yet'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.text('Sara'), findsOneWidget);
    expect(find.text('Dismissed'), findsOneWidget);
  });

  testWidgets('new notifications appear without reopening the screen', (
    tester,
  ) async {
    final harness = AppHarness();
    await harness.pump(tester);
    expect(find.text('No notifications yet'), findsOneWidget);

    harness.notifications.add(captured(title: 'Fresh'));
    await tester.pumpAndSettle();

    expect(find.text('Fresh'), findsOneWidget);
  });
}
