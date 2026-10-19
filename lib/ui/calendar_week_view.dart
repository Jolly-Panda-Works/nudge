import 'package:flutter/material.dart';

import '../domain/calendar/calendar_names.dart';
import '../domain/calendar/calendar_system.dart';
import '../domain/external_event.dart';
import '../domain/task.dart';
import 'calendar_event_tile.dart';
import 'calendar_widgets.dart';
import 'content_width.dart';

/// The seven days of one week, one row per day, with that day's tasks under
/// its date. Tapping a date opens that day in the day view.
class CalendarWeekView extends StatelessWidget {
  const CalendarWeekView({
    required this.system,
    required this.weekStart,
    required this.byDay,
    required this.selected,
    required this.today,
    required this.persian,
    required this.onOpenDay,
    required this.onOpenTask,
    this.eventsByDay = const <DateTime, List<ExternalEvent>>{},
    this.onOpenEvent,
    super.key,
  });

  final CalendarSystem system;

  /// The first day of the week (local midnight).
  final DateTime weekStart;
  final Map<DateTime, List<TaskItem>> byDay;
  final DateTime selected;
  final DateTime today;
  final bool persian;
  final ValueChanged<DateTime> onOpenDay;
  final ValueChanged<TaskItem> onOpenTask;
  final Map<DateTime, List<ExternalEvent>> eventsByDay;
  final ValueChanged<ExternalEvent>? onOpenEvent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= wideBreakpoint
          ? _wide(context)
          : _narrow(context),
    );
  }

  /// Wide windows: the seven days side by side, each a column of tasks.
  Widget _wide(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Builder(
                builder: (context) {
                  final day = DateTime(
                    weekStart.year,
                    weekStart.month,
                    weekStart.day + i,
                  );
                  final named = system.fromDate(day);
                  final tasks = byDay[day] ?? const <TaskItem>[];
                  final events = eventsByDay[day] ?? const <ExternalEvent>[];
                  final isToday = day == today;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Material(
                      color: day == selected
                          ? scheme.primaryContainer.withValues(alpha: 0.5)
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            key: ValueKey<String>(
                              'day-${day.year}-${day.month}-${day.day}',
                            ),
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => onOpenDay(day),
                            child: SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      CalendarNames.weekday(
                                        day.weekday,
                                        persian: persian,
                                        short: true,
                                      ),
                                      style: textTheme.labelMedium?.copyWith(
                                        color:
                                            persian &&
                                                day.weekday == DateTime.friday
                                            ? scheme.error
                                            : scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 36,
                                      height: 36,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: isToday
                                            ? Border.all(
                                                color: scheme.primary,
                                                width: 1.5,
                                              )
                                            : null,
                                      ),
                                      child: Text(
                                        CalendarNames.number(
                                          named.day,
                                          persian: persian,
                                        ),
                                        style: textTheme.titleSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView(
                              children: [
                                for (final event in events)
                                  CalendarEventTile(
                                    event: event,
                                    persian: persian,
                                    onTap: () => onOpenEvent?.call(event),
                                  ),
                                for (final task in tasks)
                                  CalendarTaskTile(
                                    task: task,
                                    persian: persian,
                                    onTap: () => onOpenTask(task),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Narrow screens: one row per day.
  Widget _narrow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (var i = 0; i < 7; i++)
          Builder(
            builder: (context) {
              final day = DateTime(
                weekStart.year,
                weekStart.month,
                weekStart.day + i,
              );
              final named = system.fromDate(day);
              final tasks = byDay[day] ?? const <TaskItem>[];
              final events = eventsByDay[day] ?? const <ExternalEvent>[];
              final isToday = day == today;
              final isSelected = day == selected;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Material(
                  color: isSelected
                      ? scheme.primaryContainer.withValues(alpha: 0.5)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        key: ValueKey<String>(
                          'day-${day.year}-${day.month}-${day.day}',
                        ),
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onOpenDay(day),
                        child: SizedBox(
                          width: 64,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              children: [
                                Text(
                                  CalendarNames.weekday(
                                    day.weekday,
                                    persian: persian,
                                    short: true,
                                  ),
                                  style: textTheme.labelMedium?.copyWith(
                                    color:
                                        persian &&
                                            day.weekday == DateTime.friday
                                        ? scheme.error
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: isToday
                                        ? Border.all(
                                            color: scheme.primary,
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                  child: Text(
                                    CalendarNames.number(
                                      named.day,
                                      persian: persian,
                                    ),
                                    style: textTheme.titleSmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: tasks.isEmpty && events.isEmpty
                            ? const SizedBox(height: 56)
                            : Column(
                                children: [
                                  for (final event in events)
                                    CalendarEventTile(
                                      event: event,
                                      persian: persian,
                                      onTap: () => onOpenEvent?.call(event),
                                    ),
                                  for (final task in tasks)
                                    CalendarTaskTile(
                                      task: task,
                                      persian: persian,
                                      onTap: () => onOpenTask(task),
                                    ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
