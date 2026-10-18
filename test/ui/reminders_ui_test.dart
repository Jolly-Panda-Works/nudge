import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/fixtures.dart';

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the Reminders section is hidden where alerts do not exist', (
    tester,
  ) async {
    final harness = AppHarness();
    await harness.pump(tester);
    await openSettings(tester);

    expect(find.text('Reminder alerts'), findsNothing);
    expect(find.text('Exact timing'), findsNothing);
  });

  testWidgets('shows that alerts and exact timing are allowed', (tester) async {
    final harness = AppHarness(remindersSupported: true);
    await harness.pump(tester);
    await openSettings(tester);

    expect(find.text('Reminder alerts'), findsOneWidget);
    expect(find.text('Exact timing'), findsOneWidget);
    expect(find.text('Allowed'), findsNWidgets(2));
  });

  testWidgets('blocked alerts offer a fix that asks, then opens settings', (
    tester,
  ) async {
    final harness = AppHarness(remindersSupported: true);
    harness.reminders.notificationsAllowed = false;
    await harness.pump(tester);
    await openSettings(tester);

    expect(find.text('Blocked: reminders will not be shown'), findsOneWidget);
    await tester.tap(find.text('Reminder alerts'));
    await tester.pumpAndSettle();

    expect(harness.reminders.permissionRequests, 1);
    expect(harness.reminders.notificationSettingsOpens, 1);
  });

  testWidgets('late exact alarms are explained and open their settings', (
    tester,
  ) async {
    final harness = AppHarness(remindersSupported: true);
    harness.reminders.exactAlarmsAllowed = false;
    await harness.pump(tester);
    await openSettings(tester);

    expect(
      find.text('Not allowed: alerts may arrive a few minutes late'),
      findsOneWidget,
    );
    await tester.tap(find.text('Exact timing'));
    await tester.pumpAndSettle();

    expect(harness.reminders.exactSettingsOpens, 1);
  });

  testWidgets('saving a reminder asks for the notification permission', (
    tester,
  ) async {
    final harness = AppHarness(remindersSupported: true);
    harness.reminders.notificationsAllowed = false;
    harness.notifications.add(captured());
    await harness.pump(tester);

    await tester.tap(find.text('Sara'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create reminder'));
    await tester.pumpAndSettle();
    // Choose a time: the date defaults to today.
    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(await harness.tasks.count(), 1);
    expect(harness.reminders.permissionRequests, 1);
  });
}
