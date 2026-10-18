import 'package:flutter/material.dart';

import '../domain/calendar/calendar_system.dart';
import '../domain/task.dart';
import '../l10n/l10n.dart';
import 'calendar_widgets.dart';

/// The days that have something to do, from [from] on, one heading per day.
class CalendarAgendaView extends StatelessWidget {
  const CalendarAgendaView({
    required this.system,
    required this.from,
    required this.byDay,
    required this.persian,
    required this.onOpenTask,
    this.days = defaultDays,
    super.key,
  });

  static const int defaultDays = 60;

  final CalendarSystem system;

  /// The first day looked at (local midnight).
  final DateTime from;
  final Map<DateTime, List<TaskItem>> byDay;
  final bool persian;
  final ValueChanged<TaskItem> onOpenTask;

  /// How many days from [from] are looked at.
  final int days;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final entries = <Widget>[];
    for (var i = 0; i < days; i++) {
      final day = DateTime(from.year, from.month, from.day + i);
      final tasks = byDay[day];
      if (tasks == null || tasks.isEmpty) continue;
      entries.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            calendarHeading(system, day, persian: persian),
            style: textTheme.titleSmall?.copyWith(color: scheme.primary),
          ),
        ),
      );
      for (final task in tasks) {
        entries.add(
          CalendarTaskTile(
            task: task,
            persian: persian,
            onTap: () => onOpenTask(task),
          ),
        );
      }
    }
    if (entries.isEmpty) {
      return Center(
        child: Text(
          tr('Nothing planned in the next {days} days', {'days': days}),
        ),
      );
    }
    return ListView(children: entries);
  }
}
