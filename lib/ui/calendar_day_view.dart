import 'package:flutter/material.dart';

import '../domain/calendar/calendar_names.dart';
import '../domain/external_event.dart';
import '../domain/task.dart';
import '../l10n/l10n.dart';
import 'calendar_event_tile.dart';
import 'calendar_widgets.dart';

/// One day as a list of hours, with each task under the hour it is due.
class CalendarDayView extends StatefulWidget {
  const CalendarDayView({
    required this.tasks,
    required this.persian,
    required this.onOpenTask,
    this.day,
    this.events = const <ExternalEvent>[],
    this.onOpenEvent,
    super.key,
  });

  /// The tasks of the day, ordered by time.
  final List<TaskItem> tasks;
  final bool persian;
  final ValueChanged<TaskItem> onOpenTask;

  /// The day shown (local midnight); events that started earlier are placed
  /// in the first hour.
  final DateTime? day;

  /// The events of the day: all-day ones first, then by start.
  final List<ExternalEvent> events;
  final ValueChanged<ExternalEvent>? onOpenEvent;

  @override
  State<CalendarDayView> createState() => _CalendarDayViewState();
}

class _CalendarDayViewState extends State<CalendarDayView> {
  static const double _hourHeight = 56;

  /// Starts near the morning instead of at midnight.
  late final ScrollController _controller = ScrollController(
    initialScrollOffset: 7 * _hourHeight,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _hourLabel(int hour) {
    final text = '${hour.toString().padLeft(2, '0')}:00';
    return widget.persian ? CalendarNames.toPersianDigits(text) : text;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final byHour = <int, List<TaskItem>>{};
    for (final task in widget.tasks) {
      byHour
          .putIfAbsent(task.remindAt!.toLocal().hour, () => <TaskItem>[])
          .add(task);
    }
    final allDay = <ExternalEvent>[
      for (final e in widget.events)
        if (e.allDay) e,
    ];
    final eventsByHour = <int, List<ExternalEvent>>{};
    final day = widget.day;
    for (final event in widget.events) {
      if (event.allDay) continue;
      final startsToday = day == null || !event.start.isBefore(day);
      final hour = startsToday ? event.start.hour : 0;
      eventsByHour.putIfAbsent(hour, () => <ExternalEvent>[]).add(event);
    }
    final hours = ListView.builder(
      controller: _controller,
      itemCount: 24,
      itemBuilder: (context, hour) {
        final tasks = byHour[hour] ?? const <TaskItem>[];
        return Container(
          constraints: const BoxConstraints(minHeight: _hourHeight),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: scheme.outlineVariant, width: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      _hourLabel(hour),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    for (final event
                        in eventsByHour[hour] ?? const <ExternalEvent>[])
                      CalendarEventTile(
                        event: event,
                        persian: widget.persian,
                        onTap: () => widget.onOpenEvent?.call(event),
                      ),
                    for (final task in tasks)
                      CalendarTaskTile(
                        task: task,
                        persian: widget.persian,
                        showTime: false,
                        onTap: () => widget.onOpenTask(task),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    if (allDay.isEmpty) return hours;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('All day'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              for (final event in allDay)
                CalendarEventTile(
                  event: event,
                  persian: widget.persian,
                  showTime: false,
                  onTap: () => widget.onOpenEvent?.call(event),
                ),
            ],
          ),
        ),
        Expanded(child: hours),
      ],
    );
  }
}
