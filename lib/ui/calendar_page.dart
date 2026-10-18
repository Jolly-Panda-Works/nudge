import 'dart:async';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../application/tasks_by_day.dart';
import '../domain/calendar/calendar_date.dart';
import '../domain/calendar/calendar_names.dart';
import '../domain/calendar/calendar_system.dart';
import '../domain/calendar/calendar_systems.dart';
import '../domain/calendar/month_grid.dart';
import '../domain/task.dart';
import 'dialogs.dart';
import 'task_detail_page.dart';
import 'task_form_page.dart';
import 'time_format.dart';

/// Month view with an agenda for the selected day. Jalali dates are shown
/// right to left with Persian names and digits; Gregorian dates left to right.
/// Tasks and reminders appear as dots on their day.
class CalendarPage extends StatefulWidget {
  const CalendarPage({required this.services, this.clock, super.key});

  final AppServices services;

  /// The current time; tests pass a fixed one.
  final DateTime Function()? clock;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarSystem? _system;
  int _year = 0;
  int _month = 1;
  late DateTime _selected = _today;
  bool _failed = false;

  late final Stream<List<TaskItem>> _tasks = widget.services.tasks.watchTasks(
    statuses: <TaskStatus>{TaskStatus.open, TaskStatus.done},
  );

  DateTime get _now => (widget.clock ?? DateTime.now)();

  DateTime get _today {
    final now = _now;
    return DateTime(now.year, now.month, now.day);
  }

  bool get _persian => _system?.id == 'jalali';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// The date named in [system], or null when it is outside the supported
  /// years of that system.
  CalendarDate? _name(CalendarSystem system, DateTime date) {
    try {
      final named = system.fromDate(date);
      return system.isValid(CalendarDate(named.year, named.month, 1))
          ? named
          : null;
    } on RangeError {
      return null;
    }
  }

  Future<void> _load() async {
    try {
      final id = await widget.services.settings.getCalendarSystemId();
      if (!mounted) return;
      _show(CalendarSystems.byId(id), _selected);
    } on Exception {
      if (mounted) setState(() => _failed = true);
    }
  }

  /// Shows the month that contains [day] in [system], falling back to
  /// Gregorian when [day] is outside the years Jalali supports.
  void _show(CalendarSystem system, DateTime day) {
    var chosen = system;
    var named = _name(chosen, day);
    if (named == null) {
      chosen = CalendarSystems.gregorian;
      named = chosen.fromDate(day);
    }
    final shown = named;
    setState(() {
      _system = chosen;
      _year = shown.year;
      _month = shown.month;
      _selected = day;
      _failed = false;
    });
  }

  Future<void> _toggleSystem() async {
    final current = _system;
    if (current == null) return;
    final next = current.id == 'jalali'
        ? CalendarSystems.gregorian
        : CalendarSystems.jalali;
    _show(next, _selected);
    try {
      await widget.services.settings.setCalendarSystemId(
        _system?.id ?? next.id,
      );
    } on Exception {
      if (mounted) showMessage(context, 'Could not save this choice.');
    }
  }

  (int, int) _neighbour({required bool next}) {
    final system = _system!;
    if (next) {
      return _month == system.monthsPerYear ? (_year + 1, 1) : (_year, _month + 1);
    }
    return _month == 1 ? (_year - 1, system.monthsPerYear) : (_year, _month - 1);
  }

  bool _canGo({required bool next}) {
    final system = _system;
    if (system == null) return false;
    final target = _neighbour(next: next);
    return system.isValid(CalendarDate(target.$1, target.$2, 1));
  }

  void _go({required bool next}) {
    if (!_canGo(next: next)) return;
    final target = _neighbour(next: next);
    setState(() {
      _year = target.$1;
      _month = target.$2;
    });
  }

  void _goToday() {
    final system = _system;
    if (system == null) return;
    _show(system, _today);
  }

  Future<void> _addTask() async {
    await Navigator.of(context).push<TaskItem>(
      MaterialPageRoute<TaskItem>(
        builder: (_) =>
            TaskFormPage(services: widget.services, initialDate: _selected),
      ),
    );
  }

  void _openTask(TaskItem task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            TaskDetailPage(task: task, services: widget.services),
      ),
    );
  }

  void _onSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 200) return;
    final rtl = _persian;
    // Dragging toward the start edge of the reading direction goes forward.
    final forward = rtl ? velocity > 0 : velocity < 0;
    _go(next: forward);
  }

  String _num(int value) =>
      CalendarNames.number(value, persian: _persian);

  String _monthTitle() =>
      '${CalendarNames.month(_system!.id, _month, persian: _persian)} '
      '${_num(_year)}';

  String _dayText(CalendarSystem system, DateTime date, {required bool persian}) {
    final named = system.fromDate(date);
    return '${CalendarNames.number(named.day, persian: persian)} '
        '${CalendarNames.month(system.id, named.month, persian: persian)} '
        '${CalendarNames.number(named.year, persian: persian)}';
  }

  @override
  Widget build(BuildContext context) {
    final system = _system;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Today',
            onPressed: system == null ? null : _goToday,
          ),
          IconButton(
            icon: const Icon(Icons.translate),
            tooltip: _persian ? 'Show Gregorian dates' : 'Show Jalali dates',
            onPressed: system == null ? null : _toggleSystem,
          ),
        ],
      ),
      floatingActionButton: system == null
          ? null
          : FloatingActionButton(
              onPressed: _addTask,
              tooltip: 'New task on the selected day',
              child: const Icon(Icons.add),
            ),
      body: _failed
          ? Center(
              child: FilledButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            )
          : system == null
          ? const Center(child: CircularProgressIndicator())
          : Directionality(
              textDirection: _persian ? TextDirection.rtl : TextDirection.ltr,
              child: StreamBuilder<List<TaskItem>>(
                stream: _tasks,
                builder: (context, snapshot) {
                  final byDay = groupTasksByDay(
                    snapshot.data ?? const <TaskItem>[],
                  );
                  return _body(context, system, byDay);
                },
              ),
            ),
    );
  }

  Widget _body(
    BuildContext context,
    CalendarSystem system,
    Map<DateTime, List<TaskItem>> byDay,
  ) {
    final grid = MonthGrid.build(system: system, year: _year, month: _month);
    final scheme = Theme.of(context).colorScheme;
    final today = _today;
    final rtl = _persian;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(rtl ? Icons.chevron_right : Icons.chevron_left),
                tooltip: 'Previous month',
                onPressed: _canGo(next: false) ? () => _go(next: false) : null,
              ),
              Expanded(
                child: Text(
                  _monthTitle(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: Icon(rtl ? Icons.chevron_left : Icons.chevron_right),
                tooltip: 'Next month',
                onPressed: _canGo(next: true) ? () => _go(next: true) : null,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              for (final weekday in grid.columnWeekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      CalendarNames.weekday(
                        weekday,
                        persian: _persian,
                        short: true,
                      ),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: _isWeekend(weekday)
                            ? scheme.error
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: _onSwipe,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  for (final week in grid.weeks)
                    Expanded(
                      child: Row(
                        children: [
                          for (final cell in week)
                            Expanded(
                              child: _DayCell(
                                cell: cell,
                                persian: _persian,
                                isToday: cell.date == today,
                                isSelected: cell.date == _selected,
                                isWeekend: _isWeekend(cell.date.weekday),
                                tasks: byDay[cell.date] ?? const <TaskItem>[],
                                label: _semanticLabel(
                                  system,
                                  cell,
                                  byDay[cell.date]?.length ?? 0,
                                ),
                                onTap: () => setState(() {
                                  _selected = cell.date;
                                  if (!cell.inMonth) {
                                    _year = cell.calendarDate.year;
                                    _month = cell.calendarDate.month;
                                  }
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(flex: 2, child: _agenda(context, system, byDay)),
      ],
    );
  }

  /// Friday is the weekend day of the Jalali calendar.
  bool _isWeekend(int weekday) => _persian && weekday == DateTime.friday;

  String _semanticLabel(CalendarSystem system, GridCell cell, int count) {
    final weekday = CalendarNames.weekday(cell.date.weekday, persian: false);
    final date = _dayText(system, cell.date, persian: false);
    final tasks = count == 0 ? '' : ', $count ${count == 1 ? 'task' : 'tasks'}';
    return '$weekday, $date$tasks';
  }

  Widget _agenda(
    BuildContext context,
    CalendarSystem system,
    Map<DateTime, List<TaskItem>> byDay,
  ) {
    final tasks = byDay[_selected] ?? const <TaskItem>[];
    final other = system.id == 'jalali'
        ? CalendarSystems.gregorian
        : CalendarSystems.jalali;
    final alternate = _name(other, _selected) == null
        ? null
        : _dayText(other, _selected, persian: other.id == 'jalali');
    final textTheme = Theme.of(context).textTheme;
    final heading =
        '${CalendarNames.weekday(_selected.weekday, persian: _persian)} '
        '${_dayText(system, _selected, persian: _persian)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(heading, style: textTheme.titleSmall),
              if (alternate != null)
                Text(alternate, style: textTheme.bodySmall),
            ],
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? const Center(child: Text('No tasks on this day'))
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final done = task.status == TaskStatus.done;
                    final time = formatTimeOfDay(task.remindAt!);
                    return ListTile(
                      dense: true,
                      onTap: () => _openTask(task),
                      leading: Icon(
                        task.kind == TaskKind.reminder
                            ? Icons.alarm
                            : (done
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked),
                      ),
                      title: Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: done
                            ? const TextStyle(
                                decoration: TextDecoration.lineThrough,
                              )
                            : null,
                      ),
                      subtitle: Text(
                        _persian ? CalendarNames.toPersianDigits(time) : time,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.cell,
    required this.persian,
    required this.isToday,
    required this.isSelected,
    required this.isWeekend,
    required this.tasks,
    required this.label,
    required this.onTap,
  });

  final GridCell cell;
  final bool persian;
  final bool isToday;
  final bool isSelected;
  final bool isWeekend;
  final List<TaskItem> tasks;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color textColor;
    if (isSelected) {
      textColor = scheme.onPrimary;
    } else if (!cell.inMonth) {
      textColor = scheme.onSurface.withValues(alpha: 0.38);
    } else if (isWeekend) {
      textColor = scheme.error;
    } else {
      textColor = scheme.onSurface;
    }
    final hasOpen = tasks.any((t) => t.status == TaskStatus.open);
    final dotColor = isSelected
        ? scheme.onPrimary
        : (hasOpen ? scheme.tertiary : scheme.outline);
    final dots = tasks.length > 3 ? 3 : tasks.length;
    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          // Scales down instead of overflowing when a cell is very small.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? scheme.primary : null,
                  border: isToday && !isSelected
                      ? Border.all(color: scheme.primary, width: 1.5)
                      : null,
                ),
                child: Text(
                  CalendarNames.number(cell.calendarDate.day, persian: persian),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < dots; i++)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
