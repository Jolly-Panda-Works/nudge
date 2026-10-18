import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/domain/task_draft.dart';
import 'package:nudge/ui/calendar_page.dart';

import '../support/app_harness.dart';

// 2026-10-18 is 26 Mehr 1405, a Sunday.
final DateTime fixedNow = DateTime(2026, 10, 18, 12);

Future<AppHarness> openCalendar(
  WidgetTester tester, {
  void Function(AppHarness harness)? prepare,
}) async {
  final harness = AppHarness();
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
  testWidgets('the week view names the week and steps by weeks', (
    tester,
  ) async {
    await openCalendar(tester);

    await choose(tester, 'Week');
    // Saturday 25 Mehr to Friday 1 Aban.
    expect(find.text('۲۵ مهر – ۱ آبان ۱۴۰۵'), findsOneWidget);

    await tester.tap(find.byTooltip('Next week'));
    await tester.pumpAndSettle();
    expect(find.text('۲ – ۸ آبان ۱۴۰۵'), findsOneWidget);

    await tester.tap(find.byTooltip('Today'));
    await tester.pumpAndSettle();
    expect(find.text('۲۵ مهر – ۱ آبان ۱۴۰۵'), findsOneWidget);
  });

  testWidgets('the Gregorian week starts on Monday', (tester) async {
    await openCalendar(
      tester,
      prepare: (harness) => harness.settings.calendarSystemId = 'gregorian',
    );

    await choose(tester, 'Week');

    expect(find.text('12 – 18 October 2026'), findsOneWidget);
  });

  testWidgets('a task shows in the week view and its date opens the day', (
    tester,
  ) async {
    final harness = AppHarness();
    await harness.tasks.create(
      TaskDraft(title: 'Call Sara', dueAt: DateTime(2026, 10, 20, 9)),
    );
    await harness.pump(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarPage(services: harness.services, clock: () => fixedNow),
      ),
    );
    await tester.pumpAndSettle();

    await choose(tester, 'Week');
    expect(find.text('Call Sara'), findsOneWidget);
    expect(find.text('۰۹:۰۰'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('day-2026-10-20')));
    await tester.pumpAndSettle();

    // 20 October is 28 Mehr; the day view lists hours.
    expect(find.text('۲۸ مهر ۱۴۰۵'), findsOneWidget);
    expect(find.text('Call Sara'), findsOneWidget);
    expect(find.text('۰۹:۰۰'), findsOneWidget);
    expect(find.text('۰۸:۰۰'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous day'));
    await tester.pumpAndSettle();
    expect(find.text('۲۷ مهر ۱۴۰۵'), findsOneWidget);
    expect(find.text('Call Sara'), findsNothing);
  });

  testWidgets('opening a task from the day view shows its details', (
    tester,
  ) async {
    final harness = AppHarness();
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

    await choose(tester, 'Day');
    await tester.tap(find.text('Call Sara'));
    await tester.pumpAndSettle();

    expect(find.text('Mark done'), findsOneWidget);
  });

  testWidgets('the agenda lists the days that have tasks', (tester) async {
    final harness = AppHarness();
    await harness.tasks.create(
      TaskDraft(title: 'Call Sara', dueAt: DateTime(2026, 10, 18, 9)),
    );
    await harness.tasks.create(
      TaskDraft(title: 'Pay rent', dueAt: DateTime(2026, 10, 25, 10)),
    );
    await harness.pump(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarPage(services: harness.services, clock: () => fixedNow),
      ),
    );
    await tester.pumpAndSettle();

    await choose(tester, 'Agenda');

    expect(find.text('یکشنبه ۲۶ مهر ۱۴۰۵'), findsOneWidget);
    expect(find.text('یکشنبه ۳ آبان ۱۴۰۵'), findsOneWidget);
    expect(find.text('Call Sara'), findsOneWidget);
    expect(find.text('Pay rent'), findsOneWidget);
  });

  testWidgets('an empty agenda says so', (tester) async {
    await openCalendar(tester);

    await choose(tester, 'Agenda');

    expect(find.text('Nothing planned in the next 60 days'), findsOneWidget);
  });

  testWidgets('a day picked in the month view carries over to the day view', (
    tester,
  ) async {
    await openCalendar(tester);

    await tester.tap(find.text('۱۵'));
    await tester.pumpAndSettle();
    await choose(tester, 'Day');

    expect(find.text('۱۵ مهر ۱۴۰۵'), findsOneWidget);
  });

  testWidgets('the week view opens on the month that was on screen', (
    tester,
  ) async {
    await openCalendar(tester);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('آذر ۱۴۰۵'), findsOneWidget);
    await choose(tester, 'Week');

    // 1 Azar is Sunday 22 November; its week starts Saturday 30 Aban.
    expect(find.text('۳۰ آبان – ۶ آذر ۱۴۰۵'), findsOneWidget);
  });

  testWidgets('going back to the month view shows the month of the day', (
    tester,
  ) async {
    await openCalendar(tester);

    await choose(tester, 'Week');
    await tester.tap(find.byTooltip('Next week'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next week'));
    await tester.pumpAndSettle();
    await choose(tester, 'Month');

    // Two weeks after 26 Mehr is 10 Aban.
    expect(find.text('آبان ۱۴۰۵'), findsOneWidget);
  });
}
