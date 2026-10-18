import 'calendar_date.dart';
import 'calendar_system.dart';

/// The Jalali (Persian, Solar Hijri) calendar.
///
/// The arithmetic follows the well-known `jalaali-js` algorithm (a table of
/// leap-cycle breaks, accurate for the years 1178 to 1632). Integer division
/// truncates toward zero and `remainder` is used instead of `%`, exactly as
/// in the original. [toDate], [monthLength] and [isLeapYear] throw a
/// [RangeError] for years outside the supported range.
/// The port was checked against an independent library for every day from
/// 1900 to 2200 (Gregorian) before it was written in Dart.
final class JalaliCalendar implements CalendarSystem {
  const JalaliCalendar();

  /// First and last supported Jalali years (about 1799 to 2254 Gregorian).
  static const int minYear = 1178;
  static const int maxYear = 1632;

  static const List<int> _breaks = <int>[
    -61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, //
    1210, 1635, 2060, 2097, 2192, 2262, 2324, 2394, 2456, 3178,
  ];

  @override
  String get id => 'jalali';

  @override
  int get monthsPerYear => 12;

  /// Saturday.
  @override
  int get defaultWeekStart => DateTime.saturday;

  @override
  CalendarDate fromDate(DateTime date) {
    final jdn = _gregorianToDay(date.year, date.month, date.day);
    return _dayToJalali(jdn);
  }

  @override
  DateTime toDate(CalendarDate date) {
    if (!isValid(date)) {
      throw RangeError('Not a valid Jalali date: $date');
    }
    final jdn = _jalaliToDay(date.year, date.month, date.day);
    final g = _dayToGregorian(jdn);
    return DateTime(g.$1, g.$2, g.$3);
  }

  @override
  bool isLeapYear(int year) {
    _checkYear(year);
    return _cal(year, withoutLeap: false).leap == 0;
  }

  @override
  int monthLength(int year, int month) {
    if (month < 1 || month > 12) {
      throw RangeError.range(month, 1, 12, 'month');
    }
    _checkYear(year);
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return isLeapYear(year) ? 30 : 29;
  }

  @override
  bool isValid(CalendarDate date) =>
      date.year >= minYear &&
      date.year <= maxYear &&
      date.month >= 1 &&
      date.month <= 12 &&
      date.day >= 1 &&
      date.day <= monthLength(date.year, date.month);

  static void _checkYear(int year) {
    if (year < minYear || year > maxYear) {
      throw RangeError.range(year, minYear, maxYear, 'year');
    }
  }

  static ({int gy, int march, int leap}) _cal(
    int jy, {
    required bool withoutLeap,
  }) {
    // The table covers more years than the calendar supports in the UI; the
    // last days of the last supported year need the year after it.
    if (jy < _breaks.first || jy >= _breaks.last) {
      throw RangeError.range(jy, _breaks.first, _breaks.last - 1, 'year');
    }
    final gy = jy + 621;
    var leapJ = -14;
    var jp = _breaks[0];
    var jump = 0;
    for (var i = 1; i < _breaks.length; i++) {
      final jm = _breaks[i];
      jump = jm - jp;
      if (jy < jm) break;
      leapJ += (jump ~/ 33) * 8 + (jump.remainder(33) ~/ 4);
      jp = jm;
    }
    var n = jy - jp;
    leapJ += (n ~/ 33) * 8 + ((n.remainder(33) + 3) ~/ 4);
    if (jump.remainder(33) == 4 && jump - n == 4) leapJ += 1;
    final leapG = (gy ~/ 4) - (((gy ~/ 100) + 1) * 3 ~/ 4) - 150;
    final march = 20 + leapJ - leapG;
    if (withoutLeap) return (gy: gy, march: march, leap: -1);
    if (jump - n < 6) n = n - jump + ((jump + 4) ~/ 33) * 33;
    var leap = (n + 1).remainder(33) - 1;
    leap = leap.remainder(4);
    if (leap == -1) leap = 4;
    return (gy: gy, march: march, leap: leap);
  }

  static int _gregorianToDay(int gy, int gm, int gd) {
    var d =
        ((gy + (gm - 8) ~/ 6 + 100100) * 1461 ~/ 4) +
        ((153 * (gm + 9).remainder(12) + 2) ~/ 5) +
        gd -
        34840408;
    d = d - (((gy + 100100 + (gm - 8) ~/ 6) ~/ 100) * 3 ~/ 4) + 752;
    return d;
  }

  static (int, int, int) _dayToGregorian(int jdn) {
    var j = 4 * jdn + 139361631;
    j = j + (((4 * jdn + 183187720) ~/ 146097) * 3 ~/ 4) * 4 - 3908;
    final i = (j.remainder(1461) ~/ 4) * 5 + 308;
    final gd = (i.remainder(153) ~/ 5) + 1;
    final gm = (i ~/ 153).remainder(12) + 1;
    final gy = (j ~/ 1461) - 100100 + (8 - gm) ~/ 6;
    return (gy, gm, gd);
  }

  static int _jalaliToDay(int jy, int jm, int jd) {
    final r = _cal(jy, withoutLeap: true);
    return _gregorianToDay(r.gy, 3, r.march) +
        (jm - 1) * 31 -
        (jm ~/ 7) * (jm - 7) +
        jd -
        1;
  }

  static CalendarDate _dayToJalali(int jdn) {
    final gy = _dayToGregorian(jdn).$1;
    var jy = gy - 621;
    final r = _cal(jy, withoutLeap: false);
    final jdn1f = _gregorianToDay(gy, 3, r.march);
    var k = jdn - jdn1f;
    if (k >= 0) {
      if (k <= 185) {
        return CalendarDate(jy, 1 + k ~/ 31, k.remainder(31) + 1);
      }
      k -= 186;
    } else {
      jy -= 1;
      k += 179;
      if (r.leap == 1) k += 1;
    }
    return CalendarDate(jy, 7 + k ~/ 30, k.remainder(30) + 1);
  }
}
