import 'package:flutter/material.dart';

import '../domain/calendar/calendar_names.dart';
import '../domain/calendar/calendar_system.dart';
import '../domain/task.dart';
import 'time_format.dart';

/// "26 Mehr 1405" (or "۲۶ مهر ۱۴۰۵") for the local day of [date].
String calendarDayText(
  CalendarSystem system,
  DateTime date, {
  required bool persian,
}) {
  final named = system.fromDate(date);
  return '${CalendarNames.number(named.day, persian: persian)} '
      '${CalendarNames.month(system.id, named.month, persian: persian)} '
      '${CalendarNames.number(named.year, persian: persian)}';
}

/// A day heading with its weekday: "Sunday 18 October 2026".
String calendarHeading(
  CalendarSystem system,
  DateTime date, {
  required bool persian,
}) =>
    '${CalendarNames.weekday(date.weekday, persian: persian)} '
    '${calendarDayText(system, date, persian: persian)}';

/// The first day of the week that contains [day], using [weekStart] as
/// `DateTime.weekday` of the first column.
DateTime startOfWeek(DateTime day, int weekStart) {
  final offset = (day.weekday - weekStart + 7) % 7;
  return DateTime(day.year, day.month, day.day - offset);
}

/// One task or reminder in a list of the calendar.
class CalendarTaskTile extends StatelessWidget {
  const CalendarTaskTile({
    required this.task,
    required this.persian,
    required this.onTap,
    this.showTime = true,
    super.key,
  });

  final TaskItem task;
  final bool persian;
  final VoidCallback onTap;

  /// False where the time is already shown by the surrounding layout.
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final done = task.status == TaskStatus.done;
    final time = formatTimeOfDay(task.remindAt!);
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Icon(
        task.kind == TaskKind.reminder
            ? Icons.alarm
            : (done ? Icons.check_circle : Icons.radio_button_unchecked),
      ),
      title: Text(
        task.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: done
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: showTime
          ? Text(persian ? CalendarNames.toPersianDigits(time) : time)
          : null,
    );
  }
}
