import 'dart:async';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../application/calendar_integration.dart';
import '../domain/event_draft.dart';
import '../domain/external_calendar.dart';
import '../domain/external_event.dart';
import '../l10n/l10n.dart';
import 'content_width.dart';
import 'dialogs.dart';
import 'time_format.dart';

/// The message for a calendar change that was not made.
String calendarWriteMessage(CalendarWriteProblem problem) => switch (problem) {
  CalendarWriteProblem.notEnabled => tr(
    'Turn on device calendars in Settings > Calendars first.',
  ),
  CalendarWriteProblem.noWritePermission => tr(
    'Nudge is not allowed to change your calendars. Allow it in the app settings.',
  ),
  CalendarWriteProblem.noWritableCalendar => tr(
    'There is no calendar to save events to. Choose one in Settings > Calendars.',
  ),
  CalendarWriteProblem.readOnly => tr('This calendar is read only.'),
  CalendarWriteProblem.recurring => tr(
    'Repeating events are changed in the calendar app.',
  ),
  CalendarWriteProblem.noTime => tr('Give the task a date and time first.'),
  CalendarWriteProblem.failed => tr('The change could not be saved.'),
};

/// Creates or edits an event of a device calendar. Pops `true` when something
/// was saved or deleted.
///
/// Modes: [event] given = edit (the calendar cannot change); otherwise a new
/// event on [initialDay] in the default calendar (or the one picked).
class EventFormPage extends StatefulWidget {
  const EventFormPage({
    required this.services,
    this.event,
    this.initialDay,
    super.key,
  });

  final AppServices services;
  final ExternalEvent? event;
  final DateTime? initialDay;

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late bool _allDay;
  late DateTime _startDay;
  late TimeOfDay _startTime;
  late DateTime _endDay;
  late TimeOfDay _endTime;
  CalendarState? _state;
  String? _calendarId;
  String? _rangeError;
  bool _saving = false;

  ExternalEvent? get _editing => widget.event;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    if (event != null) {
      _title = TextEditingController(text: event.title);
      _allDay = event.allDay;
      _startDay = DateTime(event.start.year, event.start.month, event.start.day);
      _startTime = TimeOfDay(hour: event.start.hour, minute: event.start.minute);
      // An all-day event's end is the midnight after its last day.
      final last = event.allDay
          ? event.end.subtract(const Duration(days: 1))
          : event.end;
      _endDay = DateTime(last.year, last.month, last.day);
      _endTime = TimeOfDay(hour: event.end.hour, minute: event.end.minute);
      _calendarId = event.calendarId;
    } else {
      final day = widget.initialDay ?? DateTime.now();
      _title = TextEditingController();
      _allDay = false;
      _startDay = DateTime(day.year, day.month, day.day);
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endDay = _startDay;
      _endTime = const TimeOfDay(hour: 10, minute: 0);
      unawaited(_loadCalendars());
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _loadCalendars() async {
    try {
      final state = await widget.services.calendars.load();
      if (!mounted) return;
      setState(() {
        _state = state;
        _calendarId = state.defaultId;
      });
    } on Exception {
      if (mounted) setState(() => _state = CalendarState.unsupportedState);
    }
  }

  DateTime _at(DateTime day, TimeOfDay time) =>
      DateTime(day.year, day.month, day.day, time.hour, time.minute);

  Future<void> _pickDay({required bool start}) async {
    final current = start ? _startDay : _endDay;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 5),
      lastDate: DateTime(current.year + 10),
    );
    if (picked == null) return;
    setState(() {
      _rangeError = null;
      if (start) {
        _startDay = picked;
        // An end before the new start moves to the start.
        if (_endDay.isBefore(picked)) _endDay = picked;
      } else {
        _endDay = picked;
      }
    });
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() {
      _rangeError = null;
      if (start) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  EventDraft? _draft() {
    final calendarId = _calendarId;
    if (calendarId == null) return null;
    return EventDraft(
      calendarId: calendarId,
      title: _title.text,
      allDay: _allDay,
      start: _allDay ? _startDay : _at(_startDay, _startTime),
      end: _allDay ? _endDay : _at(_endDay, _endTime),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final draft = _draft();
    if (draft == null) {
      showMessage(
        context,
        calendarWriteMessage(CalendarWriteProblem.noWritableCalendar),
      );
      return;
    }
    if (draft.problem == 'range') {
      setState(() => _rangeError = tr('The end must be after the start'));
      return;
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    try {
      final service = widget.services.calendars;
      final editing = _editing;
      if (editing != null) {
        await service.updateEvent(editing, draft);
      } else {
        await service.createEvent(draft);
      }
      navigator.pop(true);
    } on CalendarWriteException catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        showMessage(context, calendarWriteMessage(error.problem));
      }
    } on Exception {
      if (mounted) {
        setState(() => _saving = false);
        showMessage(context, calendarWriteMessage(CalendarWriteProblem.failed));
      }
    }
  }

  Future<void> _delete() async {
    final editing = _editing;
    if (editing == null) return;
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
    final navigator = Navigator.of(context);
    try {
      await widget.services.calendars.deleteEvent(editing);
      navigator.pop(true);
    } on CalendarWriteException catch (error) {
      if (mounted) showMessage(context, calendarWriteMessage(error.problem));
    } on Exception {
      if (mounted) {
        showMessage(context, calendarWriteMessage(CalendarWriteProblem.failed));
      }
    }
  }

  List<ExternalCalendar> get _writable =>
      _state?.writable ?? const <ExternalCalendar>[];

  @override
  Widget build(BuildContext context) {
    final editing = _editing;
    final loading = editing == null && _state == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing == null ? tr('New event') : tr('Edit event')),
        actions: [
          if (editing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: tr('Delete event'),
              onPressed: _delete,
            ),
          TextButton(
            onPressed: (_saving || loading) ? null : _save,
            child: Text(tr('Save')),
          ),
        ],
      ),
      body: ContentWidth(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Form(key: _formKey, child: _fields(context)),
      ),
    );
  }

  Widget _fields(BuildContext context) {
    final editing = _editing;
    final scheme = Theme.of(context).colorScheme;
    String dayText(DateTime d) => formatDay(d);
    String timeText(TimeOfDay t) =>
        formatTimeOfDay(DateTime(2000, 1, 1, t.hour, t.minute));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextFormField(
          controller: _title,
          decoration: InputDecoration(
            labelText: tr('Title'),
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? tr('Enter a title') : null,
        ),
        const SizedBox(height: 16),
        if (editing != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(editing.calendarLabel),
            subtitle: Text(tr('The calendar of an event cannot be changed')),
          )
        else if (_writable.isEmpty)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.warning_amber, color: scheme.error),
            title: Text(
              calendarWriteMessage(
                _state?.enabled == true
                    ? CalendarWriteProblem.noWritableCalendar
                    : CalendarWriteProblem.notEnabled,
              ),
            ),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: _calendarId,
            decoration: InputDecoration(
              labelText: tr('Calendar'),
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final c in _writable)
                DropdownMenuItem<String>(
                  value: c.id,
                  child: Text(
                    '${c.label} · ${c.accountName}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (id) => setState(() => _calendarId = id),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(tr('All day')),
          value: _allDay,
          onChanged: (on) => setState(() {
            _allDay = on;
            _rangeError = null;
          }),
        ),
        _DateTimeRow(
          label: tr('Starts'),
          day: dayText(_startDay),
          time: _allDay ? null : timeText(_startTime),
          onDay: () => _pickDay(start: true),
          onTime: () => _pickTime(start: true),
        ),
        _DateTimeRow(
          label: tr('Ends'),
          day: dayText(_endDay),
          time: _allDay ? null : timeText(_endTime),
          onDay: () => _pickDay(start: false),
          onTime: () => _pickTime(start: false),
        ),
        if (_rangeError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_rangeError!, style: TextStyle(color: scheme.error)),
          ),
      ],
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({
    required this.label,
    required this.day,
    required this.onDay,
    required this.onTime,
    this.time,
  });

  final String label;
  final String day;
  final String? time;
  final VoidCallback onDay;
  final VoidCallback onTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 72, child: Text(label)),
          Expanded(
            child: OutlinedButton(onPressed: onDay, child: Text(day)),
          ),
          if (time != null) ...[
            const SizedBox(width: 8),
            OutlinedButton(onPressed: onTime, child: Text(time!)),
          ],
        ],
      ),
    );
  }
}
