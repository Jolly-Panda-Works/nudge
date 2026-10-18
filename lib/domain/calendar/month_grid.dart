import 'calendar_date.dart';
import 'calendar_system.dart';

/// One day in a month grid.
final class GridCell {
  const GridCell({
    required this.date,
    required this.calendarDate,
    required this.inMonth,
  });

  /// The local midnight of this day.
  final DateTime date;

  /// The same day named in the grid's calendar system.
  final CalendarDate calendarDate;

  /// False for the days of the neighbouring months that fill the first and
  /// last week.
  final bool inMonth;
}

/// The weeks that make up one month in a [CalendarSystem], with the days of
/// the neighbouring months filling the first and last week. The grid has as
/// many weeks as the month needs (4 to 6).
final class MonthGrid {
  const MonthGrid._({
    required this.system,
    required this.year,
    required this.month,
    required this.weekStart,
    required this.weeks,
  });

  factory MonthGrid.build({
    required CalendarSystem system,
    required int year,
    required int month,
    int? weekStart,
  }) {
    final start = weekStart ?? system.defaultWeekStart;
    if (start < 1 || start > 7) {
      throw RangeError.range(start, 1, 7, 'weekStart');
    }
    final length = system.monthLength(year, month);
    final first = system.toDate(CalendarDate(year, month, 1));
    final offset = (first.weekday - start + 7) % 7;
    final weekCount = (offset + length + 6) ~/ 7;
    final weeks = <List<GridCell>>[];
    for (var w = 0; w < weekCount; w++) {
      final row = <GridCell>[];
      for (var d = 0; d < 7; d++) {
        final date = DateTime(
          first.year,
          first.month,
          first.day - offset + w * 7 + d,
        );
        final named = system.fromDate(date);
        row.add(
          GridCell(
            date: date,
            calendarDate: named,
            inMonth: named.year == year && named.month == month,
          ),
        );
      }
      weeks.add(List<GridCell>.unmodifiable(row));
    }
    return MonthGrid._(
      system: system,
      year: year,
      month: month,
      weekStart: start,
      weeks: List<List<GridCell>>.unmodifiable(weeks),
    );
  }

  final CalendarSystem system;
  final int year;
  final int month;

  /// The first column's weekday as `DateTime.weekday`.
  final int weekStart;

  final List<List<GridCell>> weeks;

  /// The weekdays of the columns, left to right, as `DateTime.weekday`.
  List<int> get columnWeekdays => <int>[
    for (var i = 0; i < 7; i++) (weekStart - 1 + i) % 7 + 1,
  ];

  /// The previous month as (year, month), crossing the year boundary.
  (int, int) get previous =>
      month == 1 ? (year - 1, system.monthsPerYear) : (year, month - 1);

  /// The next month as (year, month), crossing the year boundary.
  (int, int) get next =>
      month == system.monthsPerYear ? (year + 1, 1) : (year, month + 1);
}
