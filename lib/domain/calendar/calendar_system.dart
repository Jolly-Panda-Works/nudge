import 'calendar_date.dart';

/// A way of writing dates. Tasks and reminders always store real instants
/// (UTC); a calendar system only decides how a local day is named and laid
/// out. External calendars (Android, Google) always receive Gregorian
/// dates, so every conversion goes through [fromDate] and [toDate].
abstract interface class CalendarSystem {
  /// Stable identifier: `gregorian` or `jalali`.
  String get id;

  int get monthsPerYear;

  /// The first day of the week as `DateTime.weekday` (1 = Monday ... 7 = Sunday).
  int get defaultWeekStart;

  /// Names the local calendar day of [date] (its year, month and day fields).
  CalendarDate fromDate(DateTime date);

  /// The local midnight that starts [date].
  DateTime toDate(CalendarDate date);

  int monthLength(int year, int month);

  bool isLeapYear(int year);

  bool isValid(CalendarDate date);
}
