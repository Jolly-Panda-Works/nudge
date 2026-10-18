import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/domain/task_draft.dart';
import 'package:nudge/ui/calendar_page.dart';
import 'package:nudge/ui/settings_page.dart';
import 'package:nudge/ui/tasks_page.dart';

import '../support/app_harness.dart';

// 2026-10-18 is 26 Mehr 1405, a Sunday.
final DateTime fixedNow = DateTime(2026, 10, 18, 12);

void setScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<AppHarness> openCalendar(WidgetTester tester) async {
  final harness = AppHarness();
  await harness.tasks.create(
    TaskDraft(
      title: 'A very long task title that has to wrap onto several lines',
      dueAt: DateTime(2026, 10, 20, 9),
    ),
  );
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
  group('wide layouts', () {
    testWidgets('the month and the day list sit side by side', (tester) async {
      setScreen(tester, const Size(1400, 900));
      await openCalendar(tester);

      expect(find.byType(VerticalDivider), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a narrow screen stacks them', (tester) async {
      setScreen(tester, const Size(800, 2400));
      await openCalendar(tester);

      expect(find.byType(VerticalDivider), findsNothing);
    });

    testWidgets('the week shows its days side by side', (tester) async {
      setScreen(tester, const Size(1400, 900));
      await openCalendar(tester);

      await choose(tester, 'Week');

      final a = tester.getCenter(
        find.byKey(const ValueKey<String>('day-2026-10-20')),
      );
      final b = tester.getCenter(
        find.byKey(const ValueKey<String>('day-2026-10-21')),
      );
      expect(a.dy, b.dy);
      expect(a.dx, isNot(b.dx));
      expect(tester.takeException(), isNull);
    });

    testWidgets('on a narrow screen the week days are stacked', (tester) async {
      setScreen(tester, const Size(800, 2400));
      await openCalendar(tester);

      await choose(tester, 'Week');

      final a = tester.getCenter(
        find.byKey(const ValueKey<String>('day-2026-10-20')),
      );
      final b = tester.getCenter(
        find.byKey(const ValueKey<String>('day-2026-10-21')),
      );
      expect(a.dx, b.dx);
      expect(a.dy, isNot(b.dy));
    });

    testWidgets('settings keep a readable width on a wide window', (
      tester,
    ) async {
      setScreen(tester, const Size(1400, 900));
      final harness = AppHarness();
      await tester.pumpWidget(
        MaterialApp(home: SettingsPage(services: harness.services)),
      );
      await tester.pumpAndSettle();

      final tile = find.widgetWithText(ListTile, 'Language');
      expect(tile, findsOneWidget);
      expect(tester.getSize(tile).width, lessThanOrEqualTo(720));
    });
  });

  group('large text', () {
    Future<void> scale(WidgetTester tester, double factor) async {
      tester.platformDispatcher.textScaleFactorTestValue = factor;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    for (final view in <String>['Month', 'Week', 'Day', 'Agenda']) {
      testWidgets('the $view view fits at double text size', (tester) async {
        setScreen(tester, const Size(400, 800));
        await scale(tester, 2.0);
        await openCalendar(tester);

        await choose(tester, view);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the Jalali month fits at double text size', (tester) async {
      setScreen(tester, const Size(400, 800));
      await scale(tester, 2.0);
      await openCalendar(tester);

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Settings and Tasks fit at 1.5 times text size', (
      tester,
    ) async {
      setScreen(tester, const Size(400, 800));
      await scale(tester, 1.5);
      final harness = AppHarness();
      await harness.tasks.create(
        const TaskDraft(title: 'A long title that wraps at a larger text size'),
      );

      await tester.pumpWidget(
        MaterialApp(home: SettingsPage(services: harness.services)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        MaterialApp(home: TasksPage(services: harness.services)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
