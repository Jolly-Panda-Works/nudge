import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/domain/external_calendar.dart';
import 'package:nudge/domain/external_event.dart';
import 'package:nudge/domain/task_draft.dart';
import 'package:nudge/ui/calendar_page.dart';

import '../support/app_harness.dart';
import '../support/fake_calendar_platform.dart';

// 2026-10-18 is 26 Mehr 1405, a Sunday.
final DateTime fixedNow = DateTime(2026, 10, 18, 12);

Future<AppHarness> openCalendar(
  WidgetTester tester, {
  void Function(AppHarness harness)? prepare,
}) async {
  final harness = AppHarness(calendarsSupported: true);
  harness.deviceCalendars.granted = const CalendarPermissions(
    read: true,
    write: true,
  );
  harness.settings.calendarIntegration = true;
  harness.deviceCalendars.calendars = <ExternalCalendar>[
    calendar('1', name: 'Personal'),
  ];
  harness.deviceCalendars.events = <ExternalEvent>[
    event(
      'e1',
      title: 'Team meeting',
      start: DateTime(2026, 10, 18, 10),
      end: DateTime(2026, 10, 18, 11, 30),
      color: 0xFF2196F3,
    ),
    event(
      'e2',
      title: 'Holiday',
      start: DateTime(2026, 10, 20),
      end: DateTime(2026, 10, 21),
      allDay: true,
    ),
  ];
  prepare?.call(harness);
  await harness.pump(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: CalendarPage(services: harness.services, clock: () => fixedNow),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}

Future<void> choose(WidgetTester tester, String view) async {
  await tester.tap(find.text(view));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the selected day lists its events with time and calendar', (
    tester,
  ) async {
    await openCalendar(tester);

    expect(find.text('Team meeting'), findsOneWidget);
    expect(find.text('۱۰:۰۰ – ۱۱:۳۰ · Personal'), findsOneWidget);
    expect(find.text('No tasks on this day'), findsNothing);
  });

  testWidgets('an all-day event is labelled as such', (tester) async {
    await openCalendar(tester);

    // 20 October is 28 Mehr; 28 Shahrivar also shows in the first week.
    await tester.tap(find.text('۲۸').last);
    await tester.pumpAndSettle();

    expect(find.text('Holiday'), findsOneWidget);
    expect(find.text('All day · Personal'), findsOneWidget);
  });

  testWidgets('events and tasks are listed together on a day', (tester) async {
    final harness = AppHarness(calendarsSupported: true);
    harness.deviceCalendars.granted = const CalendarPermissions(
      read: true,
      write: true,
    );
    harness.settings.calendarIntegration = true;
    harness.deviceCalendars.calendars = <ExternalCalendar>[calendar('1')];
    harness.deviceCalendars.events = <ExternalEvent>[
      event('e1', title: 'Team meeting', start: DateTime(2026, 10, 18, 10)),
    ];
    await harness.tasks.create(
      TaskDraft(title: 'Call Sara', dueAt: DateTime(2026, 10, 18, 9)),
    );
    await harness.pump(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarPage(services: harness.services, clock: () => fixedNow),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Team meeting'), findsOneWidget);
    expect(find.text('Call Sara'), findsOneWidget);
    // Events are marked with a calendar icon, tasks with their own icon.
    expect(find.byIcon(Icons.event), findsOneWidget);
  });

  testWidgets('the week view shows the events of its days', (tester) async {
    await openCalendar(tester);

    await choose(tester, 'Week');

    expect(find.text('Team meeting'), findsOneWidget);
    expect(find.text('Holiday'), findsOneWidget);
  });

  testWidgets('the day view puts all-day events at the top', (tester) async {
    await openCalendar(tester);
    await choose(tester, 'Week');

    await tester.tap(find.byKey(const ValueKey<String>('day-2026-10-20')));
    await tester.pumpAndSettle();

    expect(find.text('All day'), findsOneWidget);
    expect(find.text('Holiday'), findsOneWidget);
  });

  testWidgets('the day view places a timed event under its hour', (
    tester,
  ) async {
    await openCalendar(tester);

    await choose(tester, 'Day');

    expect(find.text('Team meeting'), findsOneWidget);
    expect(find.text('۱۰:۰۰'), findsOneWidget);
  });

  testWidgets('the agenda lists events of the coming days', (tester) async {
    await openCalendar(tester);

    await choose(tester, 'Agenda');

    expect(find.text('Team meeting'), findsOneWidget);
    expect(find.text('Holiday'), findsOneWidget);
  });

  testWidgets('tapping an event shows it and can open the calendar app', (
    tester,
  ) async {
    final harness = await openCalendar(tester);

    await tester.tap(find.text('Team meeting'));
    await tester.pumpAndSettle();
    expect(find.text('Open in calendar app'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);

    await tester.tap(find.text('Open in calendar app'));
    await tester.pumpAndSettle();
    expect(harness.deviceCalendars.opened.single.eventId, 'e1');

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Open in calendar app'), findsNothing);
  });

  testWidgets('with the integration off no events are read', (tester) async {
    final harness = await openCalendar(
      tester,
      prepare: (h) => h.settings.calendarIntegration = false,
    );

    expect(find.text('Team meeting'), findsNothing);
    expect(harness.deviceCalendars.eventQueries, isEmpty);
  });

  testWidgets('a hidden calendar shows no events', (tester) async {
    await openCalendar(
      tester,
      prepare: (h) => h.settings.visibleCalendarIds = <String>{},
    );

    expect(find.text('Team meeting'), findsNothing);
  });

  testWidgets('a failing provider is reported and the rest keeps working', (
    tester,
  ) async {
    final harness = AppHarness(calendarsSupported: true);
    harness.deviceCalendars.granted = const CalendarPermissions(
      read: true,
      write: true,
    );
    harness.settings.calendarIntegration = true;
    harness.deviceCalendars.calendars = <ExternalCalendar>[calendar('1')];
    harness.deviceCalendars.eventsFail = true;
    await harness.tasks.create(
      TaskDraft(title: 'Call Sara', dueAt: DateTime(2026, 10, 18, 9)),
    );
    await harness.pump(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarPage(services: harness.services, clock: () => fixedNow),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Events of the device calendars could not be read.'),
      findsOneWidget,
    );
    expect(find.text('Call Sara'), findsOneWidget);
  });

  testWidgets('changing the month reads the events of the new range', (
    tester,
  ) async {
    final harness = await openCalendar(tester);
    final before = harness.deviceCalendars.eventQueries.length;

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();

    expect(harness.deviceCalendars.eventQueries.length, greaterThan(before));
  });
}
