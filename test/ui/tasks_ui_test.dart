import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/domain/task.dart';

import '../support/app_harness.dart';
import '../support/fixtures.dart';

Future<void> openDetail(WidgetTester tester) async {
  await tester.tap(find.text('Sara'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('creates a task from a notification and links it', (
    tester,
  ) async {
    final harness = AppHarness()..notifications.add(captured());
    await harness.pump(tester);
    await openDetail(tester);

    expect(find.text('Create task'), findsOneWidget);
    expect(find.text('Create reminder'), findsOneWidget);

    await tester.tap(find.text('Create task'));
    await tester.pumpAndSettle();
    expect(find.text('New task'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final all = await harness.tasks.listAll();
    expect(all, hasLength(1));
    expect(all.single.title, 'Sara');
    expect(all.single.source?.notificationKey, captured().key);
    expect(find.text('View task'), findsOneWidget);
    expect(find.text('Create task'), findsNothing);
  });

  testWidgets('a reminder cannot be saved without a date', (tester) async {
    final harness = AppHarness()..notifications.add(captured());
    await harness.pump(tester);
    await openDetail(tester);

    await tester.tap(find.text('Create reminder'));
    await tester.pumpAndSettle();
    expect(find.text('New reminder'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('A reminder needs a date and time'), findsOneWidget);
    expect(await harness.tasks.count(), 0);
  });

  testWidgets('the task list completes and archives tasks', (tester) async {
    final harness = AppHarness()..notifications.add(captured());
    final result = await harness.tasks.createFromNotification(captured());
    await harness.pump(tester);

    await tester.tap(find.byIcon(Icons.checklist));
    await tester.pumpAndSettle();
    expect(find.text('Tasks'), findsWidgets);
    expect(find.text('Sara'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('No open tasks'), findsOneWidget);
    expect(
      (await harness.tasks.findById(result.task.id))?.status,
      TaskStatus.done,
    );

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Sara'), findsOneWidget);

    await tester.tap(find.text('Sara'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(find.text('Restore'), findsOneWidget);
    expect(
      (await harness.tasks.findById(result.task.id))?.status,
      TaskStatus.archived,
    );
  });

  testWidgets('Open original uses the live action first', (tester) async {
    final n = captured();
    final harness = AppHarness()..notifications.add(n);
    harness.platform.liveKeys.add(n.key);
    await harness.pump(tester);
    await openDetail(tester);

    await tester.tap(find.text('Open original'));
    await tester.pumpAndSettle();

    expect(harness.platform.openCalls, <String>['live:${n.key}']);
    expect(find.text('Opened the original notification'), findsOneWidget);
  });

  testWidgets('Open original falls back, then says it is unavailable', (
    tester,
  ) async {
    final n = captured();
    final harness = AppHarness()..notifications.add(n);
    await harness.pump(tester);
    await openDetail(tester);

    await tester.tap(find.text('Open original'));
    await tester.pumpAndSettle();

    expect(harness.platform.openCalls, <String>[
      'live:${n.key}',
      'app:com.chat',
    ]);
    expect(
      find.text('The original is not available. The saved content is kept here.'),
      findsOneWidget,
    );
  });

  testWidgets('a task detail offers Open original for its source', (
    tester,
  ) async {
    final n = captured();
    final harness = AppHarness()..notifications.add(n);
    harness.platform.launchablePackages.add('com.chat');
    await harness.tasks.createFromNotification(n);
    await harness.pump(tester);

    await tester.tap(find.byIcon(Icons.checklist));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sara'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open original'));
    await tester.pumpAndSettle();

    expect(
      find.text('The notification is gone, so the app was opened instead'),
      findsOneWidget,
    );
  });
}
