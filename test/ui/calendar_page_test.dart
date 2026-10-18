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

void main() {
  testWidgets('opens on the current Jalali month with Persian text', (
    tester,
  ) async {
    await openCalendar(tester);

    expect(find.text('مهر ۱۴۰۵'), findsOneWidget);
    expect(find.text('۲۶'), findsOneWidget);
    expect(find.text('ش'), findsOneWidget);
    expect(find.text('No tasks on this day'), findsOneWidget);
    // The agenda also names the day in the other calendar.
    expect(find.text('18 October 2026'), findsOneWidget);
  });

  testWidgets('the Jalali grid runs right to left, Saturday first', (
    tester,
  ) async {
    await openCalendar(tester);

    final saturday = tester.getCenter(find.text('ش'));
    final friday = tester.getCenter(find.text('ج'));
    expect(saturday.dx, greaterThan(friday.dx));
  });

  testWidgets('next and previous change the month', (tester) async {
    await openCalendar(tester);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('آبان ۱۴۰۵'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('شهریور ۱۴۰۵'), findsOneWidget);

    await tester.tap(find.byTooltip('Today'));
    await tester.pumpAndSettle();
    expect(find.text('مهر ۱۴۰۵'), findsOneWidget);
  });

  testWidgets('switching to Gregorian shows October 2026 and is saved', (
    tester,
  ) async {
    final harness = await openCalendar(tester);

    await tester.tap(find.byTooltip('Show Gregorian dates'));
    await tester.pumpAndSettle();

    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(harness.settings.calendarSystemId, 'gregorian');
    expect(find.byTooltip('Show Jalali dates'), findsOneWidget);
  });

  testWidgets('a saved Gregorian choice is used on opening', (tester) async {
    await openCalendar(
      tester,
      prepare: (harness) => harness.settings.calendarSystemId = 'gregorian',
    );

    expect(find.text('October 2026'), findsOneWidget);
  });

  testWidgets('a task shows in the agenda of its day and opens', (
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

    expect(find.text('Call Sara'), findsOneWidget);
    expect(find.text('۰۹:۰۰'), findsOneWidget);
    expect(find.text('No tasks on this day'), findsNothing);

    await tester.tap(find.text('Call Sara'));
    await tester.pumpAndSettle();
    expect(find.text('Task'), findsOneWidget);
  });

  testWidgets('selecting a day without tasks shows the empty message', (
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

    await tester.tap(find.text('۱۵'));
    await tester.pumpAndSettle();

    expect(find.text('Call Sara'), findsNothing);
    expect(find.text('No tasks on this day'), findsOneWidget);
  });

  testWidgets('the add button creates a task on the selected day', (
    tester,
  ) async {
    final harness = await openCalendar(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('New task'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Pay rent');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final all = await harness.tasks.listAll();
    expect(all, hasLength(1));
    final due = all.single.dueAt!.toLocal();
    expect((due.year, due.month, due.day), (2026, 10, 18));
    expect(find.text('Pay rent'), findsOneWidget);
  });

  testWidgets('the inbox opens the calendar', (tester) async {
    final harness = AppHarness();
    await harness.pump(tester);

    await tester.tap(find.byIcon(Icons.calendar_month));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Next month'), findsOneWidget);
  });
}
