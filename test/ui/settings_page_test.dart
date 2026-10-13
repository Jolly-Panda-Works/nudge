import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/domain/ingest_policy.dart';

import '../support/app_harness.dart';
import '../support/fixtures.dart';

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows access state, counts and version', (tester) async {
    final harness = AppHarness()..notifications.add(captured());
    await harness.pump(tester);
    await openSettings(tester);

    expect(find.text('Access: granted'), findsOneWidget);
    expect(find.text('Listener: connected'), findsOneWidget);
    expect(find.text('Stored notifications: 1'), findsOneWidget);
    expect(find.text('1 active'), findsOneWidget);
    expect(find.textContaining('Nudge v'), findsOneWidget);
  });

  testWidgets('unsupported platforms say so', (tester) async {
    final harness = AppHarness(supported: false);
    await harness.pump(tester);
    await openSettings(tester);

    expect(find.text('Not available on this platform'), findsOneWidget);
  });

  testWidgets('toggles are saved', (tester) async {
    final harness = AppHarness();
    await harness.pump(tester);
    await openSettings(tester);

    await tester.tap(find.text('Ongoing notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Group summaries'));
    await tester.pumpAndSettle();

    expect(harness.settings.captureOngoing, isTrue);
    expect(harness.settings.captureGroupSummaries, isTrue);
  });

  testWidgets('capture mode can be changed from the dialog', (tester) async {
    final harness = AppHarness();
    await harness.pump(tester);
    await openSettings(tester);

    await tester.tap(find.text('Capture mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Only selected apps'));
    await tester.pumpAndSettle();

    expect(harness.settings.mode, FilterMode.allowlist);
    expect(find.text('Only selected apps'), findsOneWidget);
  });

  testWidgets('apps seen so far can be selected for the filter', (
    tester,
  ) async {
    final harness = AppHarness()..notifications.add(captured());
    harness.settings.mode = FilterMode.allowlist;
    await harness.pump(tester);
    await openSettings(tester);

    await tester.tap(find.text('Choose apps'));
    await tester.pumpAndSettle();

    expect(find.text('Only the selected apps are captured.'), findsOneWidget);
    await tester.tap(find.widgetWithText(SwitchListTile, 'Chat'));
    await tester.pumpAndSettle();

    expect(harness.settings.rules.keys, contains('com.chat'));
  });

  testWidgets('a package name can be added manually and is validated', (
    tester,
  ) async {
    final harness = AppHarness();
    harness.settings.mode = FilterMode.blocklist;
    await harness.pump(tester);
    await openSettings(tester);

    await tester.tap(find.text('Choose apps'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add by package name'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'not a package');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a package name such as com.example.app'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'com.example.app');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(harness.settings.rules.keys, contains('com.example.app'));
    expect(find.text('com.example.app'), findsOneWidget);
  });
}
