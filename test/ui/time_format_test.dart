import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/ui/time_format.dart';

void main() {
  final now = DateTime(2026, 10, 13, 12, 0, 30);

  group('formatTimestamp', () {
    test('recent times are relative', () {
      expect(formatTimestamp(DateTime(2026, 10, 13, 12, 0, 0), now: now), 'just now');
      expect(formatTimestamp(DateTime(2026, 10, 13, 11, 45, 30), now: now), '15 min ago');
    });

    test('a future time is shown as just now', () {
      expect(formatTimestamp(DateTime(2026, 10, 13, 12, 5), now: now), 'just now');
    });

    test('earlier today shows the clock time', () {
      expect(formatTimestamp(DateTime(2026, 10, 13, 8, 5), now: now), '08:05');
    });

    test('yesterday is labelled', () {
      expect(formatTimestamp(DateTime(2026, 10, 12, 23, 10), now: now), 'Yesterday 23:10');
    });

    test('earlier this year shows month and day', () {
      expect(formatTimestamp(DateTime(2026, 3, 5, 9, 7), now: now), 'Mar 5, 09:07');
    });

    test('other years show the date', () {
      expect(formatTimestamp(DateTime(2025, 12, 31, 23, 59), now: now), '2025-12-31');
    });
  });

  test('formatFullTimestamp includes seconds', () {
    expect(formatFullTimestamp(DateTime(2026, 1, 2, 3, 4, 5)), '2026-01-02 03:04:05');
  });
}
