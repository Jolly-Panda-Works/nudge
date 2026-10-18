import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/domain/calendar/calendar_date.dart';
import 'package:nudge/domain/calendar/jalali_calendar.dart';

void main() {
  const jalali = JalaliCalendar();

  // Pairs checked against an independent library (jdatetime).
  final known = <DateTime, CalendarDate>{
    DateTime(2026, 10, 18): const CalendarDate(1405, 7, 26),
    DateTime(2026, 3, 21): const CalendarDate(1405, 1, 1),
    DateTime(2026, 3, 20): const CalendarDate(1404, 12, 29),
    DateTime(2025, 3, 21): const CalendarDate(1404, 1, 1),
    DateTime(2025, 3, 20): const CalendarDate(1403, 12, 30),
    DateTime(2024, 3, 20): const CalendarDate(1403, 1, 1),
    DateTime(2021, 3, 20): const CalendarDate(1399, 12, 30),
    DateTime(2021, 3, 21): const CalendarDate(1400, 1, 1),
    DateTime(2000, 1, 1): const CalendarDate(1378, 10, 11),
    DateTime(1970, 1, 1): const CalendarDate(1348, 10, 11),
    DateTime(2026, 12, 31): const CalendarDate(1405, 10, 10),
    DateTime(1900, 1, 1): const CalendarDate(1278, 10, 11),
    DateTime(2200, 12, 31): const CalendarDate(1579, 10, 10),
    DateTime(1799, 3, 21): const CalendarDate(1178, 1, 1),
    DateTime(2254, 3, 20): const CalendarDate(1632, 12, 29),
  };

  test('converts known Gregorian dates to Jalali', () {
    known.forEach((gregorian, expected) {
      expect(jalali.fromDate(gregorian), expected, reason: '$gregorian');
    });
  });

  test('converts known Jalali dates to Gregorian midnights', () {
    known.forEach((gregorian, jalaliDate) {
      expect(jalali.toDate(jalaliDate), gregorian, reason: '$jalaliDate');
    });
  });

  test('every supported day round-trips and advances by one', () {
    // 1 Farvardin 1178 to 29 Esfand 1632.
    var day = DateTime(1799, 3, 21);
    final end = DateTime(2254, 3, 20);
    var previous = jalali.fromDate(day);
    expect(jalali.toDate(previous), day);
    while (day.isBefore(end)) {
      day = DateTime(day.year, day.month, day.day + 1);
      final current = jalali.fromDate(day);
      expect(jalali.toDate(current), day, reason: '$day');
      if (current.year == previous.year && current.month == previous.month) {
        expect(current.day, previous.day + 1, reason: '$day');
      } else {
        expect(current.day, 1, reason: '$day');
        expect(
          previous.day,
          jalali.monthLength(previous.year, previous.month),
          reason: '$day',
        );
      }
      previous = current;
    }
  });

  test('leap years', () {
    const leap = <int>[1395, 1399, 1403, 1408, 1412];
    for (var year = 1395; year < 1415; year++) {
      expect(jalali.isLeapYear(year), leap.contains(year), reason: '$year');
    }
  });

  test('month lengths', () {
    for (var month = 1; month <= 6; month++) {
      expect(jalali.monthLength(1405, month), 31);
    }
    for (var month = 7; month <= 11; month++) {
      expect(jalali.monthLength(1405, month), 30);
    }
    expect(jalali.monthLength(1405, 12), 29);
    expect(jalali.monthLength(1403, 12), 30);
  });

  test('validity', () {
    expect(jalali.isValid(const CalendarDate(1403, 12, 30)), isTrue);
    expect(jalali.isValid(const CalendarDate(1404, 12, 30)), isFalse);
    expect(jalali.isValid(const CalendarDate(1405, 13, 1)), isFalse);
    expect(jalali.isValid(const CalendarDate(1405, 1, 0)), isFalse);
    expect(jalali.isValid(const CalendarDate(1177, 1, 1)), isFalse);
    expect(jalali.isValid(const CalendarDate(1633, 1, 1)), isFalse);
    expect(jalali.isValid(const CalendarDate(1632, 12, 29)), isTrue);
    expect(jalali.isValid(const CalendarDate(1632, 12, 30)), isFalse);
  });

  test('invalid input throws instead of returning a wrong date', () {
    expect(
      () => jalali.toDate(const CalendarDate(1404, 12, 30)),
      throwsRangeError,
    );
    expect(() => jalali.monthLength(1405, 0), throwsRangeError);
    expect(() => jalali.monthLength(1700, 1), throwsRangeError);
    expect(() => jalali.isLeapYear(1177), throwsRangeError);
  });
}
