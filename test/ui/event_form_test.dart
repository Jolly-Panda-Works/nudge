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

const allowed = CalendarPermissions(read: true, write: true);

AppHarness harnessWithCalendars({
  List<ExternalCalendar>? calendars,
  List<ExternalEvent>? events,
}) {
  final harness = AppHarness(calendarsSupported: true);
  harness.deviceCalendars.granted = allowed;
  harness.settings.calendarIntegration = true;
  harness.deviceCalendars.calendars =
      calendars ??
      <ExternalCalendar>[
        calendar('1', name: 'Personal'),
        calendar('2', name: 'Holidays', canWrite: false, isOwner: false),
      ];
  harness.deviceCalendars.events = events ?? <ExternalEvent>[];
  return harness;
}

Future<void> openCalendar(WidgetTester tester, AppHarness harness) async {
  await harness.pump(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: CalendarPage(services: harness.services, clock: () => fixedNow),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openNewEvent(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  await tester.tap(find.text('New event'));
  await tester.pumpAndSettle();
}

Future<void> openEventDetails(WidgetTester tester, String title) async {
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('without device calendars the button still makes a task', (
    tester,
  ) async {
    final harness = AppHarness();
    await openCalendar(tester, harness);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('New task'), findsOneWidget);
    expect(find.text('New event'), findsNothing);
  });

  testWidgets('with device calendars the button offers a task or an event', (
    tester,
  ) async {
    final harness = harnessWithCalendars();
    await openCalendar(tester, harness);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('New task'), findsOneWidget);
    expect(find.text('New event'), findsOneWidget);
  });

  testWidgets('a new event is saved in the default calendar and shown', (
    tester,
  ) async {
    final harness = harnessWithCalendars();
    await openCalendar(tester, harness);

    await openNewEvent(tester);
    expect(find.text('New event'), findsWidgets);
    await tester.enterText(find.byType(TextFormField), 'Team lunch');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final created = harness.deviceCalendars.created.single;
    expect(created.title, 'Team lunch');
    expect(created.calendarId, '1');
    expect(created.allDay, isFalse);
    expect(created.start, DateTime(2026, 10, 18, 9));
    expect(created.end, DateTime(2026, 10, 18, 10));
    // Back on the calendar, the new event is listed for the selected day.
    expect(find.text('Team lunch'), findsOneWidget);
  });

  testWidgets('a title is required', (tester) async {
    final harness = harnessWithCalendars();
    await openCalendar(tester, harness);

    await openNewEvent(tester);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a title'), findsOneWidget);
    expect(harness.deviceCalendars.created, isEmpty);
  });

  testWidgets('an all-day event hides the times and is saved as all day', (
    tester,
  ) async {
    final harness = harnessWithCalendars();
    await openCalendar(tester, harness);

    await openNewEvent(tester);
    expect(find.text('09:00'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.text('09:00'), findsNothing);
    await tester.enterText(find.byType(TextFormField), 'Holiday');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final created = harness.deviceCalendars.created.single;
    expect(created.allDay, isTrue);
    expect(created.start, DateTime(2026, 10, 18));
    expect(created.end, DateTime(2026, 10, 18));
  });

  testWidgets('only writable calendars can be chosen', (tester) async {
    final harness = harnessWithCalendars();
    await openCalendar(tester, harness);

    await openNewEvent(tester);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    expect(find.textContaining('Personal ·'), findsWidgets);
    expect(find.textContaining('Holidays ·'), findsNothing);
  });

  testWidgets('with no writable calendar the form says so', (tester) async {
    final harness = harnessWithCalendars(
      calendars: <ExternalCalendar>[
        calendar('2', name: 'Holidays', canWrite: false, isOwner: false),
      ],
    );
    await openCalendar(tester, harness);

    await openNewEvent(tester);

    expect(
      find.text(
        'There is no calendar to save events to. Choose one in Settings > Calendars.',
      ),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField), 'Lunch');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(harness.deviceCalendars.created, isEmpty);
  });

  testWidgets('a failing provider is reported and the form stays', (
    tester,
  ) async {
    final harness = harnessWithCalendars();
    harness.deviceCalendars.writeFails = true;
    await openCalendar(tester, harness);

    await openNewEvent(tester);
    await tester.enterText(find.byType(TextFormField), 'Lunch');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('The change could not be saved.'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('an event can be edited from its details', (tester) async {
    final harness = harnessWithCalendars(
      events: <ExternalEvent>[
        event('e1', title: 'Team meeting', start: DateTime(2026, 10, 18, 10)),
      ],
    );
    await openCalendar(tester, harness);

    await openEventDetails(tester, 'Team meeting');
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit event'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Team sync');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(harness.deviceCalendars.updated.single.$1, 'e1');
    expect(harness.deviceCalendars.updated.single.$2.title, 'Team sync');
    expect(find.text('Team sync'), findsOneWidget);
    expect(find.text('Team meeting'), findsNothing);
  });

  testWidgets('an event can be deleted after confirming', (tester) async {
    final harness = harnessWithCalendars(
      events: <ExternalEvent>[
        event('e1', title: 'Team meeting', start: DateTime(2026, 10, 18, 10)),
      ],
    );
    await openCalendar(tester, harness);

    await openEventDetails(tester, 'Team meeting');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete event?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(harness.deviceCalendars.deleted, <String>['e1']);
    expect(find.text('Team meeting'), findsNothing);
  });

  testWidgets('cancelling the delete keeps the event', (tester) async {
    final harness = harnessWithCalendars(
      events: <ExternalEvent>[
        event('e1', title: 'Team meeting', start: DateTime(2026, 10, 18, 10)),
      ],
    );
    await openCalendar(tester, harness);

    await openEventDetails(tester, 'Team meeting');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(harness.deviceCalendars.deleted, isEmpty);
    expect(find.text('Team meeting'), findsOneWidget);
  });

  testWidgets('a repeating event cannot be edited here', (tester) async {
    final harness = harnessWithCalendars(
      events: <ExternalEvent>[
        event(
          'r1',
          title: 'Standup',
          start: DateTime(2026, 10, 18, 10),
          recurring: true,
        ),
      ],
    );
    await openCalendar(tester, harness);

    await openEventDetails(tester, 'Standup');

    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    expect(
      find.text('Repeating events are changed in the calendar app.'),
      findsOneWidget,
    );
    expect(find.text('Open in calendar app'), findsOneWidget);
  });

  testWidgets('an event of a read-only calendar cannot be edited', (
    tester,
  ) async {
    final harness = harnessWithCalendars(
      events: <ExternalEvent>[
        event(
          'h1',
          calendarId: '2',
          title: 'Public holiday',
          start: DateTime(2026, 10, 18),
          end: DateTime(2026, 10, 19),
          allDay: true,
        ),
      ],
    );
    await openCalendar(tester, harness);

    await openEventDetails(tester, 'Public holiday');

    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    expect(find.text('This calendar is read only.'), findsOneWidget);
  });

  group('tasks in the calendar', () {
    Future<AppHarness> openTask(WidgetTester tester, {DateTime? due}) async {
      final harness = harnessWithCalendars();
      await harness.tasks.create(TaskDraft(title: 'Call Sara', dueAt: due));
      await harness.pump(tester);
      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Call Sara'));
      await tester.pumpAndSettle();
      return harness;
    }

    testWidgets('a task with a time can be added once', (tester) async {
      final harness = await openTask(tester, due: DateTime(2026, 10, 20, 9));
      expect(find.text('Add to calendar'), findsOneWidget);

      await tester.tap(find.text('Add to calendar'));
      await tester.pumpAndSettle();

      expect(harness.deviceCalendars.created.single.title, 'Call Sara');
      expect(find.text('Added to your calendar'), findsOneWidget);
      expect(find.text('In your calendar'), findsOneWidget);
      expect(find.text('Add to calendar'), findsNothing);
    });

    testWidgets('opening the task again does not offer it twice', (
      tester,
    ) async {
      final harness = await openTask(tester, due: DateTime(2026, 10, 20, 9));
      await tester.tap(find.text('Add to calendar'));
      await tester.pumpAndSettle();

      // Back to the list and into the task again.
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Call Sara'));
      await tester.pumpAndSettle();

      expect(find.text('In your calendar'), findsOneWidget);
      expect(harness.deviceCalendars.created, hasLength(1));
    });

    testWidgets('a task without a time has no button', (tester) async {
      await openTask(tester);

      expect(find.text('Add to calendar'), findsNothing);
      expect(find.text('In your calendar'), findsNothing);
    });

    testWidgets('a failing provider is reported', (tester) async {
      final harness = await openTask(tester, due: DateTime(2026, 10, 20, 9));
      harness.deviceCalendars.writeFails = true;

      await tester.tap(find.text('Add to calendar'));
      await tester.pumpAndSettle();

      expect(find.text('The change could not be saved.'), findsOneWidget);
      expect(find.text('Add to calendar'), findsOneWidget);
    });

    testWidgets('deleting the task forgets its link', (tester) async {
      final harness = await openTask(tester, due: DateTime(2026, 10, 20, 9));
      await tester.tap(find.text('Add to calendar'));
      await tester.pumpAndSettle();
      expect(harness.settings.taskEventLinks, isNotEmpty);

      await tester.tap(find.byTooltip('Delete task'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(harness.settings.taskEventLinks, isEmpty);
      // The event itself stays in the calendar.
      expect(harness.deviceCalendars.events, hasLength(1));
    });
  });
}
