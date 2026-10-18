import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/domain/calendar/calendar_date.dart';
import 'package:nudge/domain/calendar/calendar_names.dart';
import 'package:nudge/domain/calendar/gregorian_calendar.dart';
import 'package:nudge/domain/calendar/jalali_calendar.dart';
import 'package:nudge/domain/calendar/month_grid.dart';

void main() {
  const jalali = JalaliCalendar();
  const gregorian = GregorianCalendar();

  test('Mehr 1405 starts on a Saturday-first grid with 5 weeks', () {
    final grid = MonthGrid.build(system: jalali, year: 1405, month: 7);

    expect(grid.weekStart, DateTime.saturday);
    expect(grid.weeks, hasLength(5));
    expect(grid.weeks.every((week) => week.length == 7), isTrue);
    // 1 Mehr is Wednesday 2026-09-23, the fifth column.
    expect(grid.weeks.first.first.date, DateTime(2026, 9, 19));
    expect(grid.weeks.first[4].date, DateTime(2026, 9, 23));
    expect(grid.weeks.first[4].calendarDate, const CalendarDate(1405, 7, 1));
    expect(grid.weeks.last.last.date, DateTime(2026, 10, 23));
    expect(grid.weeks.expand((w) => w).where((c) => c.inMonth).length, 30);
    expect(grid.weeks.first.first.inMonth, isFalse);
    expect(grid.weeks.first[4].inMonth, isTrue);
  });

  test('a month that starts late in the week needs 6 weeks', () {
    final grid = MonthGrid.build(system: jalali, year: 1405, month: 3);
    expect(grid.weeks, hasLength(6));
  });

  test('a month that starts on the first column fits its weeks exactly', () {
    final grid = MonthGrid.build(system: jalali, year: 1405, month: 1);
    expect(grid.weeks.first.first.date, DateTime(2026, 3, 21));
    expect(grid.weeks.first.first.inMonth, isTrue);
    expect(grid.weeks, hasLength(5));
  });

  test('Gregorian October 2026 with Monday first', () {
    final grid = MonthGrid.build(system: gregorian, year: 2026, month: 10);

    expect(grid.weekStart, DateTime.monday);
    expect(grid.weeks, hasLength(5));
    expect(grid.weeks.first.first.date, DateTime(2026, 9, 28));
    expect(grid.weeks.last.last.date, DateTime(2026, 11, 1));
    expect(grid.weeks.expand((w) => w).where((c) => c.inMonth).length, 31);
  });

  test('a month can take exactly 4 weeks', () {
    final grid = MonthGrid.build(system: gregorian, year: 2027, month: 2);
    expect(grid.weeks, hasLength(4));
  });

  test('the week start can be chosen', () {
    final grid = MonthGrid.build(
      system: gregorian,
      year: 2026,
      month: 10,
      weekStart: DateTime.sunday,
    );
    expect(grid.weeks.first.first.date, DateTime(2026, 9, 27));
    expect(grid.columnWeekdays.first, DateTime.sunday);
    expect(grid.columnWeekdays.last, DateTime.saturday);
  });

  test('column weekdays follow the week start', () {
    final grid = MonthGrid.build(system: jalali, year: 1405, month: 7);
    expect(grid.columnWeekdays, <int>[6, 7, 1, 2, 3, 4, 5]);
  });

  test('previous and next cross the year boundary', () {
    final first = MonthGrid.build(system: jalali, year: 1405, month: 1);
    expect(first.previous, (1404, 12));
    final last = MonthGrid.build(system: jalali, year: 1405, month: 12);
    expect(last.next, (1406, 1));
    final middle = MonthGrid.build(system: jalali, year: 1405, month: 7);
    expect(middle.previous, (1405, 6));
    expect(middle.next, (1405, 8));
  });

  test('every cell is one day after the previous one', () {
    for (var month = 1; month <= 12; month++) {
      final grid = MonthGrid.build(system: jalali, year: 1403, month: month);
      final cells = grid.weeks.expand((w) => w).toList();
      for (var i = 1; i < cells.length; i++) {
        final before = cells[i - 1].date;
        expect(
          cells[i].date,
          DateTime(before.year, before.month, before.day + 1),
        );
      }
    }
  });

  test('names and digits', () {
    expect(CalendarNames.month('jalali', 7, persian: true), 'مهر');
    expect(CalendarNames.month('jalali', 7, persian: false), 'Mehr');
    expect(CalendarNames.month('gregorian', 10, persian: false), 'October');
    expect(CalendarNames.weekday(6, persian: true), 'شنبه');
    expect(CalendarNames.weekday(6, persian: false, short: true), 'Sat');
    expect(CalendarNames.weekday(2, persian: true), 'سه\u200Cشنبه');
    expect(CalendarNames.toPersianDigits('1405/07/26'), '۱۴۰۵/۰۷/۲۶');
    expect(CalendarNames.toPersianDigits('Mehr 5'), 'Mehr ۵');
    expect(CalendarNames.number(2026, persian: true), '۲۰۲۶');
    expect(CalendarNames.number(2026, persian: false), '2026');
    expect(
      () => CalendarNames.month('jalali', 13, persian: true),
      throwsRangeError,
    );
  });
}
