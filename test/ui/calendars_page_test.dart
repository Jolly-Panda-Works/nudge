import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/domain/external_calendar.dart';

import '../support/app_harness.dart';
import '../support/fake_calendar_platform.dart';

const allowed = CalendarPermissions(read: true, write: true);

Future<AppHarness> openCalendars(
  WidgetTester tester, {
  bool supported = true,
  void Function(AppHarness harness)? prepare,
}) async {
  final harness = AppHarness(calendarsSupported: supported);
  prepare?.call(harness);
  await harness.pump(tester);
  await tester.tap(find.byIcon(Icons.settings));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Calendars'));
  await tester.pumpAndSettle();
  return harness;
}

/// What happens when the user comes back from the system permission dialog.
Future<void> comeBack(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpAndSettle();
}

void prepareTwoCalendars(AppHarness harness) {
  harness.deviceCalendars.granted = allowed;
  harness.settings.calendarIntegration = true;
  harness.deviceCalendars.calendars = <ExternalCalendar>[
    calendar('1', name: 'Personal'),
    calendar('2', name: 'Work'),
    calendar(
      '3',
      name: 'Holidays',
      account: 'holidays@example.com',
      canWrite: false,
      isOwner: false,
    ),
  ];
}

void main() {
  testWidgets('Settings links to the Calendars screen', (tester) async {
    await openCalendars(tester);

    expect(find.text('Show device calendars'), findsOneWidget);
  });

  testWidgets('a platform without calendars says so', (tester) async {
    await openCalendars(tester, supported: false);

    expect(
      find.text('Calendars on this device are available on Android.'),
      findsOneWidget,
    );
    expect(find.text('Show device calendars'), findsNothing);
  });

  testWidgets('nothing is requested or read until the switch is turned on', (
    tester,
  ) async {
    final harness = await openCalendars(tester);

    expect(harness.deviceCalendars.permissionRequests, 0);
    expect(harness.deviceCalendars.listCalls, 0);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse);
  });

  testWidgets('turning it on asks, then lists the calendars', (tester) async {
    final harness = await openCalendars(
      tester,
      prepare: (h) {
        h.deviceCalendars.allowOnRequest = true;
        h.deviceCalendars.calendars = <ExternalCalendar>[
          calendar('1', name: 'Personal'),
        ];
      },
    );

    await tester.tap(find.text('Show device calendars'));
    await tester.pumpAndSettle();
    expect(harness.deviceCalendars.permissionRequests, 1);
    expect(find.text('Personal'), findsNothing);

    await comeBack(tester);

    expect(harness.settings.calendarIntegration, isTrue);
    // Listed once, and once more as the default for new events.
    expect(find.text('Personal'), findsWidgets);
    expect(find.text('Google · me@example.com'), findsOneWidget);
  });

  testWidgets('a refused permission offers the system settings', (
    tester,
  ) async {
    final harness = await openCalendars(tester);

    await tester.tap(find.text('Show device calendars'));
    await tester.pumpAndSettle();
    await comeBack(tester);

    expect(harness.settings.calendarIntegration, isFalse);
    expect(find.text('Calendar access was not allowed'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(harness.deviceCalendars.settingsOpens, 1);
  });

  testWidgets('calendars are grouped by account with their access', (
    tester,
  ) async {
    await openCalendars(tester, prepare: prepareTwoCalendars);

    expect(find.text('Google · me@example.com'), findsOneWidget);
    expect(find.text('Google · holidays@example.com'), findsOneWidget);
    expect(find.text('Personal'), findsWidgets);
    expect(find.text('Holidays'), findsOneWidget);
    expect(find.text('Read only'), findsOneWidget);
  });

  testWidgets('showing and hiding a calendar is stored', (tester) async {
    final harness = await openCalendars(tester, prepare: prepareTwoCalendars);

    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();

    expect(harness.settings.visibleCalendarIds, <String>{'1', '3'});
  });

  testWidgets('the default calendar for new events can be chosen', (
    tester,
  ) async {
    final harness = await openCalendars(tester, prepare: prepareTwoCalendars);

    // The first own writable calendar is the default until one is chosen.
    expect(find.text('Personal'), findsWidgets);
    await tester.tap(find.text('Save new events to'));
    await tester.pumpAndSettle();
    // Only writable calendars are offered.
    expect(find.textContaining('Holidays ·'), findsNothing);
    await tester.tap(find.text('Work · me@example.com'));
    await tester.pumpAndSettle();

    expect(harness.settings.defaultCalendarId, '2');
  });

  testWidgets('a lost permission is shown with a way to fix it', (
    tester,
  ) async {
    final harness = await openCalendars(
      tester,
      prepare: (h) {
        h.settings.calendarIntegration = true;
        h.deviceCalendars.calendars = <ExternalCalendar>[calendar('1')];
      },
    );

    expect(find.text('Calendar permission was turned off'), findsOneWidget);
    expect(find.text('Personal'), findsNothing);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(harness.deviceCalendars.settingsOpens, 1);
  });

  testWidgets('turning it off stops listing the calendars', (tester) async {
    final harness = await openCalendars(tester, prepare: prepareTwoCalendars);
    expect(find.text('Personal'), findsWidgets);

    await tester.tap(find.text('Show device calendars'));
    await tester.pumpAndSettle();

    expect(harness.settings.calendarIntegration, isFalse);
    expect(find.text('Personal'), findsNothing);
  });
}
