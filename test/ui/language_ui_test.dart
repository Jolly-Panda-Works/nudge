import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/l10n/l10n.dart';

import '../support/app_harness.dart';

void main() {
  tearDown(() => L10n.setLanguage('en'));

  testWidgets('the app opens in Persian when that is the setting', (
    tester,
  ) async {
    final harness = AppHarness();
    harness.settings.language = 'fa';
    await harness.services.language.load();
    await harness.pump(tester);

    expect(find.byTooltip('تنظیمات'), findsOneWidget);
    expect(find.byTooltip('تقویم'), findsOneWidget);
    expect(find.text('هنوز اعلانی نیست'), findsOneWidget);
    // The whole app is laid out right to left.
    final context = tester.element(find.byTooltip('تنظیمات'));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('changing the language in Settings rebuilds every screen', (
    tester,
  ) async {
    final harness = AppHarness();
    await harness.pump(tester);
    expect(find.text('No notifications yet'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('فارسی'));
    await tester.pumpAndSettle();

    expect(harness.settings.language, 'fa');
    expect(L10n.language, 'fa');
    expect(find.text('هنوز اعلانی نیست'), findsOneWidget);
    expect(find.text('No notifications yet'), findsNothing);
  });

  testWidgets('the language dialog marks System default', (tester) async {
    final harness = AppHarness();
    await harness.pump(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.text('System default'), findsOneWidget);
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    expect(find.text('Choose language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('فارسی'), findsOneWidget);
  });

  testWidgets('a Persian app shows Gregorian dates with Persian names', (
    tester,
  ) async {
    final harness = AppHarness();
    harness.settings.language = 'fa';
    harness.settings.calendarSystemId = 'gregorian';
    await harness.services.language.load();
    await harness.pump(tester);

    await tester.tap(find.byTooltip('تقویم'));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    expect(find.text('ماه'), findsOneWidget);
    expect(find.byTooltip('ماه بعد'), findsOneWidget);
    // Persian digits appear in the header, not Latin ones.
    expect(
      find.textContaining(RegExp('[۰-۹]{4}')),
      findsWidgets,
      reason: 'year ${now.year} in Persian digits',
    );
  });
}
