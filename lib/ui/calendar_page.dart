import 'dart:async';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../application/calendar_integration.dart';
import '../application/events_by_day.dart';
import '../application/tasks_by_day.dart';
import '../domain/calendar/calendar_date.dart';
import '../domain/calendar/calendar_names.dart';
import '../domain/calendar/calendar_system.dart';
import '../domain/calendar/calendar_systems.dart';
import '../domain/calendar/month_grid.dart';
import '../domain/external_event.dart';
import '../domain/task.dart';
import 'calendar_agenda_view.dart';
import 'calendar_day_view.dart';
import 'calendar_event_tile.dart';
import 'calendar_week_view.dart';
import 'event_form_page.dart';
import 'calendar_widgets.dart';
import 'content_width.dart';
import 'dialogs.dart';
import 'task_detail_page.dart';
import 'task_form_page.dart';
import '../l10n/l10n.dart';

/// The ways the calendar can show time.
enum CalendarViewMode { month, week, day, agenda }

/// The calendar: month, week, day and agenda views over the same tasks and
/// reminders. Jalali dates are shown right to left with Persian names and
/// digits; Gregorian dates left to right.
class CalendarPage extends StatefulWidget {
  const CalendarPage({required this.services, this.clock, super.key});

  final AppServices services;

  /// The current time; tests pass a fixed one.
  final DateTime Function()? clock;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with WidgetsBindingObserver {
  CalendarSystem? _system;
  CalendarViewMode _view = CalendarViewMode.month;
  int _year = 0;
  int _month = 1;
  late DateTime _selected = _today;
  bool _failed = false;

  /// Events of the device calendars for the range on screen.
  Map<DateTime, List<ExternalEvent>> _eventsByDay =
      const <DateTime, List<ExternalEvent>>{};
  bool _eventsFailed = false;
  ({DateTime from, DateTime to})? _requestedRange;

  late final Stream<List<TaskItem>> _tasks = widget.services.tasks.watchTasks(
    statuses: <TaskStatus>{TaskStatus.open, TaskStatus.done},
  );

  DateTime get _now => (widget.clock ?? DateTime.now)();

  DateTime get _today {
    final now = _now;
    return DateTime(now.year, now.month, now.day);
  }

  /// Persian names and digits: for Jalali dates, and whenever the app
  /// language is Persian.
  bool get _persian => _system?.id == 'jalali' || L10n.isPersian;

  /// Jalali is laid out right to left, Gregorian left to right.
  bool get _rtl => _system?.id == 'jalali';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Events may have changed in the calendar app: read them again.
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() => _requestedRange = null);
    }
  }

  /// The days on screen in the current view (local midnights, end exclusive).
  ({DateTime from, DateTime to}) _visibleRange(CalendarSystem system) {
    DateTime after(DateTime d, int days) =>
        DateTime(d.year, d.month, d.day + days);
    switch (_view) {
      case CalendarViewMode.month:
        final grid = MonthGrid.build(
          system: system,
          year: _year,
          month: _month,
        );
        return (
          from: grid.weeks.first.first.date,
          to: after(grid.weeks.last.last.date, 1),
        );
      case CalendarViewMode.week:
        final start = startOfWeek(_selected, system.defaultWeekStart);
        return (from: start, to: after(start, 7));
      case CalendarViewMode.day:
        return (from: _selected, to: after(_selected, 1));
      case CalendarViewMode.agenda:
        return (from: _selected, to: after(_selected, 60));
    }
  }

  void _scheduleEvents(({DateTime from, DateTime to}) range) {
    if (_requestedRange == range) return;
    _requestedRange = range;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_loadEvents(range)),
    );
  }

  Future<void> _loadEvents(({DateTime from, DateTime to}) range) async {
    try {
      final found = await widget.services.calendars.events(
        from: range.from,
        to: range.to,
      );
      if (!mounted || _requestedRange != range) return;
      setState(() {
        _eventsByDay = groupEventsByDay(found);
        _eventsFailed = false;
      });
    } on Exception {
      if (!mounted || _requestedRange != range) return;
      setState(() {
        _eventsByDay = const <DateTime, List<ExternalEvent>>{};
        _eventsFailed = true;
      });
    }
  }

  void _openEvent(ExternalEvent event) {
    unawaited(
      showEventDetails(
        context,
        event,
        onOpenInCalendarApp: () => widget.services.calendars.openEvent(event),
        onEdit: event.editable ? () => unawaited(_editEvent(event)) : null,
        onDelete: event.editable ? () => unawaited(_deleteEvent(event)) : null,
      ),
    );
  }

  /// Reads the events again after a change.
  void _eventsChanged() {
    if (mounted) setState(() => _requestedRange = null);
  }

  Future<void> _editEvent(ExternalEvent event) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EventFormPage(services: widget.services, event: event),
      ),
    );
    if (changed ?? false) _eventsChanged();
  }

  Future<void> _deleteEvent(ExternalEvent event) async {
    final confirmed = await confirmAction(
      context,
      title: tr('Delete event?'),
      message: tr(
        'The event is removed from its calendar on this device (and from the '
        'account it syncs with).',
      ),
      action: tr('Delete'),
    );
    if (!confirmed || !mounted) return;
    try {
      await widget.services.calendars.deleteEvent(event);
      _eventsChanged();
    } on CalendarWriteException catch (error) {
      if (mounted) showMessage(context, calendarWriteMessage(error.problem));
    } on Exception {
      if (mounted) {
        showMessage(context, calendarWriteMessage(CalendarWriteProblem.failed));
      }
    }
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
      if (mounted) showMessage(context, tr('Could not save this choice.'));
    }
  }

  void _setView(CalendarViewMode mode) {
    final system = _system;
    if (system == null || mode == _view) return;
    // Leaving the month view: make sure the selected day is in the month
    // that was on screen, so the other views open where the user was looking.
    var day = _selected;
    final named = _name(system, day);
    if (named != null && (named.year != _year || named.month != _month)) {
      day = system.toDate(CalendarDate(_year, _month, 1));
      final today = _today;
      final todayNamed = _name(system, today);
      if (todayNamed != null &&
          todayNamed.year == _year &&
          todayNamed.month == _month) {
        day = today;
      }
    }
    setState(() {
      _view = mode;
      _selected = day;
    });
  }

  (int, int) _neighbour({required bool next}) {
    final system = _system!;
    if (next) {
      return _month == system.monthsPerYear
          ? (_year + 1, 1)
          : (_year, _month + 1);
    }
    return _month == 1
        ? (_year - 1, system.monthsPerYear)
        : (_year, _month - 1);
  }

  /// How far a step moves in the current view, in days (0 for the month view).
  int get _stepDays => switch (_view) {
    CalendarViewMode.month => 0,
    CalendarViewMode.day => 1,
    CalendarViewMode.week || CalendarViewMode.agenda => 7,
  };

  DateTime _steppedDay({required bool next}) {
    final days = next ? _stepDays : -_stepDays;
    return DateTime(_selected.year, _selected.month, _selected.day + days);
  }

  bool _canStep({required bool next}) {
    final system = _system;
    if (system == null) return false;
    if (_view == CalendarViewMode.month) {
      final target = _neighbour(next: next);
      return system.isValid(CalendarDate(target.$1, target.$2, 1));
    }
    return _name(system, _steppedDay(next: next)) != null;
  }

  void _step({required bool next}) {
    final system = _system;
    if (system == null || !_canStep(next: next)) return;
    if (_view == CalendarViewMode.month) {
      final target = _neighbour(next: next);
      setState(() {
        _year = target.$1;
        _month = target.$2;
      });
      return;
    }
    final day = _steppedDay(next: next);
    final named = _name(system, day)!;
    setState(() {
      _selected = day;
      _year = named.year;
      _month = named.month;
    });
  }

  void _goToday() {
    final system = _system;
    if (system == null) return;
    _show(system, _today);
  }

  void _openDay(DateTime day) {
    final system = _system;
    if (system == null) return;
    final named = _name(system, day);
    setState(() {
      _selected = day;
      _view = CalendarViewMode.day;
      if (named != null) {
        _year = named.year;
        _month = named.month;
      }
    });
  }

  Future<void> _newTask() async {
    await Navigator.of(context).push<TaskItem>(
      MaterialPageRoute<TaskItem>(
        builder: (_) =>
            TaskFormPage(services: widget.services, initialDate: _selected),
      ),
    );
  }

  Future<void> _newEvent() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            EventFormPage(services: widget.services, initialDay: _selected),
      ),
    );
    if (saved ?? false) _eventsChanged();
  }

  /// With device calendars available the button offers a task or an event;
  /// otherwise it creates a task.
  Future<void> _add() async {
    if (!widget.services.calendars.isSupported) {
      await _newTask();
      return;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_task),
              title: Text(tr('New task')),
              onTap: () => Navigator.of(sheetContext).pop('task'),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: Text(tr('New event')),
              onTap: () => Navigator.of(sheetContext).pop('event'),
            ),
          ],
        ),
      ),
    );
    if (choice == 'task') {
      await _newTask();
    } else if (choice == 'event') {
      await _newEvent();
    }
  }

  void _openTask(TaskItem task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailPage(task: task, services: widget.services),
      ),
    );
  }

  void _onSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 200) return;
    // Dragging toward the start edge of the reading direction goes forward.
    final forward = _rtl ? velocity > 0 : velocity < 0;
    _step(next: forward);
  }

  String _num(int value) => CalendarNames.number(value, persian: _persian);

  String _monthTitle() =>
      '${CalendarNames.month(_system!.id, _month, persian: _persian)} '
      '${_num(_year)}';

  /// "25 Mehr - 1 Aban 1405": the title of a week.
  String _weekTitle() {
    final system = _system!;
    final first = startOfWeek(_selected, system.defaultWeekStart);
    final last = DateTime(first.year, first.month, first.day + 6);
    final a = system.fromDate(first);
    final b = system.fromDate(last);
    String month(int m) => CalendarNames.month(system.id, m, persian: _persian);
    if (a.year == b.year && a.month == b.month) {
      return '${_num(a.day)} – ${_num(b.day)} ${month(b.month)} ${_num(b.year)}';
    }
    if (a.year == b.year) {
      return '${_num(a.day)} ${month(a.month)} – '
          '${_num(b.day)} ${month(b.month)} ${_num(b.year)}';
    }
    return '${calendarDayText(system, first, persian: _persian)} – '
        '${calendarDayText(system, last, persian: _persian)}';
  }

  String _title() => switch (_view) {
    CalendarViewMode.month => _monthTitle(),
    CalendarViewMode.week => _weekTitle(),
    CalendarViewMode.day || CalendarViewMode.agenda => calendarDayText(
      _system!,
      _selected,
      persian: _persian,
    ),
  };

  String _stepTooltip({required bool next}) {
    return switch (_view) {
      CalendarViewMode.month => next ? tr('Next month') : tr('Previous month'),
      CalendarViewMode.week ||
      CalendarViewMode.agenda => next ? tr('Next week') : tr('Previous week'),
      CalendarViewMode.day => next ? tr('Next day') : tr('Previous day'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final system = _system;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Calendar')),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: tr('Today'),
            onPressed: system == null ? null : _goToday,
          ),
          IconButton(
            icon: const Icon(Icons.translate),
            tooltip: _rtl
                ? tr('Show Gregorian dates')
                : tr('Show Jalali dates'),
            onPressed: system == null ? null : _toggleSystem,
          ),
        ],
      ),
      floatingActionButton: system == null
          ? null
          : FloatingActionButton(
              onPressed: _add,
              tooltip: tr('New task on the selected day'),
              child: const Icon(Icons.add),
            ),
      body: _failed
          ? Center(
              child: FilledButton(onPressed: _load, child: Text(tr('Retry'))),
            )
          : system == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<CalendarViewMode>(
                      segments: [
                        ButtonSegment<CalendarViewMode>(
                          value: CalendarViewMode.month,
                          label: Text(tr('Month')),
                        ),
                        ButtonSegment<CalendarViewMode>(
                          value: CalendarViewMode.week,
                          label: Text(tr('Week')),
                        ),
                        ButtonSegment<CalendarViewMode>(
                          value: CalendarViewMode.day,
                          label: Text(tr('Day')),
                        ),
                        ButtonSegment<CalendarViewMode>(
                          value: CalendarViewMode.agenda,
                          label: Text(tr('Agenda')),
                        ),
                      ],
                      selected: <CalendarViewMode>{_view},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) =>
                          _setView(selection.first),
                    ),
                  ),
                ),
                Expanded(
                  child: Directionality(
                    textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
                    child: StreamBuilder<List<TaskItem>>(
                      stream: _tasks,
                      builder: (context, snapshot) {
                        final byDay = groupTasksByDay(
                          snapshot.data ?? const <TaskItem>[],
                        );
                        return _content(context, system, byDay);
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _content(
    BuildContext context,
    CalendarSystem system,
    Map<DateTime, List<TaskItem>> byDay,
  ) {
    final rtl = _rtl;
    final today = _today;
    _scheduleEvents(_visibleRange(system));
    return Column(
      children: [
        if (_eventsFailed)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              tr('Events of the device calendars could not be read.'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(rtl ? Icons.chevron_right : Icons.chevron_left),
                tooltip: _stepTooltip(next: false),
                onPressed: _canStep(next: false)
                    ? () => _step(next: false)
                    : null,
              ),
              Expanded(
                child: Text(
                  _title(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: Icon(rtl ? Icons.chevron_left : Icons.chevron_right),
                tooltip: _stepTooltip(next: true),
                onPressed: _canStep(next: true)
                    ? () => _step(next: true)
                    : null,
              ),
            ],
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: _onSwipe,
            child: switch (_view) {
              CalendarViewMode.month => _monthView(
                context,
                system,
                byDay,
                today,
              ),
              CalendarViewMode.week => CalendarWeekView(
                system: system,
                weekStart: startOfWeek(_selected, system.defaultWeekStart),
                byDay: byDay,
                selected: _selected,
                today: today,
                persian: _persian,
                onOpenDay: _openDay,
                onOpenTask: _openTask,
                eventsByDay: _eventsByDay,
                onOpenEvent: _openEvent,
              ),
              CalendarViewMode.day => CalendarDayView(
                key: ValueKey<DateTime>(_selected),
                tasks: byDay[_selected] ?? const <TaskItem>[],
                persian: _persian,
                onOpenTask: _openTask,
                day: _selected,
                events: _eventsByDay[_selected] ?? const <ExternalEvent>[],
                onOpenEvent: _openEvent,
              ),
              CalendarViewMode.agenda => CalendarAgendaView(
                system: system,
                from: _selected,
                byDay: byDay,
                persian: _persian,
                onOpenTask: _openTask,
                eventsByDay: _eventsByDay,
                onOpenEvent: _openEvent,
              ),
            },
          ),
        ),
      ],
    );
  }

  /// Friday is the weekend day of the Jalali calendar.
  bool _isWeekend(int weekday) => _persian && weekday == DateTime.friday;

  Widget _monthView(
    BuildContext context,
    CalendarSystem system,
    Map<DateTime, List<TaskItem>> byDay,
    DateTime today,
  ) {
    final grid = MonthGrid.build(system: system, year: _year, month: _month);
    final scheme = Theme.of(context).colorScheme;
    final weekdayRow = Padding(
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
    );
    final cells = Padding(
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
                        events:
                            _eventsByDay[cell.date] ?? const <ExternalEvent>[],
                        label: _semanticLabel(
                          system,
                          cell,
                          byDay[cell.date]?.length ?? 0,
                          _eventsByDay[cell.date]?.length ?? 0,
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
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final agenda = _dayAgenda(context, system, byDay);
        if (constraints.maxWidth >= wideBreakpoint) {
          // Wide windows: the month on one side, the day's list on the other.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    weekdayRow,
                    Expanded(child: cells),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(flex: 2, child: agenda),
            ],
          );
        }
        return Column(
          children: [
            weekdayRow,
            Expanded(flex: 3, child: cells),
            const Divider(height: 1),
            Expanded(flex: 2, child: agenda),
          ],
        );
      },
    );
  }

  String _semanticLabel(
    CalendarSystem system,
    GridCell cell,
    int count,
    int eventCount,
  ) {
    final weekday = CalendarNames.weekday(cell.date.weekday, persian: _persian);
    final date = calendarDayText(system, cell.date, persian: _persian);
    final tasks = count == 0
        ? ''
        : (count == 1
              ? ', ${tr('1 task')}'
              : ', ${tr('{count} tasks', {'count': count})}');
    final events = eventCount == 0
        ? ''
        : (eventCount == 1
              ? ', ${tr('1 event')}'
              : ', ${tr('{count} events', {'count': eventCount})}');
    return '$weekday, $date$tasks$events';
  }

  /// The tasks of the selected day, under the month grid.
  Widget _dayAgenda(
    BuildContext context,
    CalendarSystem system,
    Map<DateTime, List<TaskItem>> byDay,
  ) {
    final tasks = byDay[_selected] ?? const <TaskItem>[];
    final events = _eventsByDay[_selected] ?? const <ExternalEvent>[];
    final other = system.id == 'jalali'
        ? CalendarSystems.gregorian
        : CalendarSystems.jalali;
    final alternate = _name(other, _selected) == null
        ? null
        : calendarDayText(
            other,
            _selected,
            persian: other.id == 'jalali' || L10n.isPersian,
          );
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                calendarHeading(system, _selected, persian: _persian),
                style: textTheme.titleSmall,
              ),
              if (alternate != null)
                Text(alternate, style: textTheme.bodySmall),
            ],
          ),
        ),
        Expanded(
          child: tasks.isEmpty && events.isEmpty
              ? Center(child: Text(tr('No tasks on this day')))
              : ListView(
                  children: [
                    for (final event in events)
                      CalendarEventTile(
                        event: event,
                        persian: _persian,
                        onTap: () => _openEvent(event),
                      ),
                    for (final task in tasks)
                      CalendarTaskTile(
                        task: task,
                        persian: _persian,
                        onTap: () => _openTask(task),
                      ),
                  ],
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
    required this.events,
    required this.label,
    required this.onTap,
  });

  final GridCell cell;
  final bool persian;
  final bool isToday;
  final bool isSelected;
  final bool isWeekend;
  final List<TaskItem> tasks;
  final List<ExternalEvent> events;
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
    // Tasks are round dots, events are small squares in their calendar's
    // colour, so the two are told apart without relying on colour alone.
    final taskDots = tasks.length > (events.isEmpty ? 3 : 2)
        ? (events.isEmpty ? 3 : 2)
        : tasks.length;
    final eventMarks = events.length > (tasks.isEmpty ? 3 : 2)
        ? (tasks.isEmpty ? 3 : 2)
        : events.length;
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
                    CalendarNames.number(
                      cell.calendarDate.day,
                      persian: persian,
                    ),
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
                      for (var i = 0; i < taskDots; i++)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dotColor,
                          ),
                        ),
                      for (var i = 0; i < eventMarks; i++)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1.5),
                            color: isSelected
                                ? scheme.onPrimary
                                : eventColor(events[i]),
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
