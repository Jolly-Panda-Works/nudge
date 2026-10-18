import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/l10n/l10n.dart';
import 'package:nudge/ui/time_format.dart';

void main() {
  final now = DateTime(2026, 10, 18, 12);

  setUp(() => L10n.setLanguage('fa'));
  tearDown(() => L10n.setLanguage('en'));

  test('relative times in Persian', () {
    expect(
      formatTimestamp(now.subtract(const Duration(seconds: 20)), now: now),
      'همین الان',
    );
    expect(
      formatTimestamp(now.subtract(const Duration(minutes: 5)), now: now),
      '۵ دقیقه پیش',
    );
    expect(formatTimestamp(DateTime(2026, 10, 18, 9, 5), now: now), '۰۹:۰۵');
    expect(
      formatTimestamp(DateTime(2026, 10, 17, 9, 5), now: now),
      'دیروز ۰۹:۰۵',
    );
  });

  test('older times use the Jalali date', () {
    // 23 September 2026 is 1 Mehr 1405.
    expect(
      formatTimestamp(DateTime(2026, 9, 23, 9, 5), now: now),
      '۱ مهر، ۰۹:۰۵',
    );
    // 21 March 2025 is 1 Farvardin 1404.
    expect(
      formatTimestamp(DateTime(2025, 3, 21, 9, 5), now: now),
      '۱۴۰۴/۰۱/۰۱',
    );
  });

  test('full, due and day formats', () {
    final time = DateTime(2026, 10, 18, 9, 0, 5);
    expect(formatFullTimestamp(time), '۱۴۰۵/۰۷/۲۶ ۰۹:۰۰:۰۵');
    expect(formatDue(time), '۱۴۰۵/۰۷/۲۶ ۰۹:۰۰');
    expect(formatDay(time), '۱۴۰۵/۰۷/۲۶');
    expect(formatTimeOfDay(time), '۰۹:۰۰');
  });

  test('English formats are unchanged', () {
    L10n.setLanguage('en');
    final time = DateTime(2026, 10, 18, 9, 0, 5);
    expect(formatFullTimestamp(time), '2026-10-18 09:00:05');
    expect(formatDue(time), '2026-10-18 09:00');
    expect(formatDay(time), '2026-10-18');
    expect(formatTimeOfDay(time), '09:00');
    expect(
      formatTimestamp(now.subtract(const Duration(minutes: 5)), now: now),
      '5 min ago',
    );
    expect(
      formatTimestamp(DateTime(2026, 10, 17, 9, 5), now: now),
      'Yesterday 09:05',
    );
  });

  test('file stamps never change', () {
    expect(formatFileStamp(DateTime(2026, 10, 18, 9, 0, 5)), '20261018-090005');
  });
}
