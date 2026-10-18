import 'calendar_date.dart';
import 'calendar_system.dart';

final class GregorianCalendar implements CalendarSystem {
  const GregorianCalendar();

  @override
  String get id => 'gregorian';

  @override
  int get monthsPerYear => 12;

  @override
  int get defaultWeekStart => DateTime.monday;

  @override
  CalendarDate fromDate(DateTime date) =>
      CalendarDate(date.year, date.month, date.day);

  @override
  DateTime toDate(CalendarDate date) =>
      DateTime(date.year, date.month, date.day);

  @override
  bool isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  @override
  int monthLength(int year, int month) {
    if (month < 1 || month > 12) {
      throw RangeError.range(month, 1, 12, 'month');
    }
    const lengths = <int>[31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return month == 2 && isLeapYear(year) ? 29 : lengths[month - 1];
  }

  @override
  bool isValid(CalendarDate date) =>
      date.month >= 1 &&
      date.month <= 12 &&
      date.day >= 1 &&
      date.day <= monthLength(date.year, date.month);
}
