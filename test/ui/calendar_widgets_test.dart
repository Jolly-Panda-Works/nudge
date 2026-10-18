import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/domain/calendar/calendar_systems.dart';
import 'package:nudge/ui/calendar_widgets.dart';

void main() {
  final sunday = DateTime(2026, 10, 18);

  test('startOfWeek follows the first weekday', () {
    expect(startOfWeek(sunday, DateTime.saturday), DateTime(2026, 10, 17));
    expect(startOfWeek(sunday, DateTime.monday), DateTime(2026, 10, 12));
    expect(startOfWeek(sunday, DateTime.sunday), DateTime(2026, 10, 18));
    expect(
      startOfWeek(DateTime(2026, 10, 17), DateTime.saturday),
      DateTime(2026, 10, 17),
    );
  });

  test('startOfWeek crosses month and year boundaries', () {
    expect(
      startOfWeek(DateTime(2027, 1, 1), DateTime.monday),
      DateTime(2026, 12, 28),
    );
  });

  test('day text in both calendars', () {
    expect(
      calendarDayText(CalendarSystems.jalali, sunday, persian: true),
      '۲۶ مهر ۱۴۰۵',
    );
    expect(
      calendarDayText(CalendarSystems.jalali, sunday, persian: false),
      '26 Mehr 1405',
    );
    expect(
      calendarDayText(CalendarSystems.gregorian, sunday, persian: false),
      '18 October 2026',
    );
  });

  test('headings add the weekday', () {
    expect(
      calendarHeading(CalendarSystems.jalali, sunday, persian: true),
      'یکشنبه ۲۶ مهر ۱۴۰۵',
    );
    expect(
      calendarHeading(CalendarSystems.gregorian, sunday, persian: false),
      'Sunday 18 October 2026',
    );
  });
}
