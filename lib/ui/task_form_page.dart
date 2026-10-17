import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/captured_notification.dart';
import '../domain/task.dart';
import '../domain/task_draft.dart';
import 'dialogs.dart';
import 'time_format.dart';

/// Creates or edits a task or reminder. Pops with the saved [TaskItem], or
/// null when the user leaves without saving.
///
/// Modes: [task] given = edit; [notification] given = create from it;
/// neither = a stand-alone task.
class TaskFormPage extends StatefulWidget {
  const TaskFormPage({
    required this.services,
    this.notification,
    this.task,
    this.initialKind = TaskKind.task,
    super.key,
  });

  final AppServices services;
  final CapturedNotification? notification;
  final TaskItem? task;
  final TaskKind initialKind;

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late TaskKind _kind;
  DateTime? _date;
  TimeOfDay? _time;
  bool _saving = false;
  String? _dueError;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    final notification = widget.notification;
    if (task != null) {
      _title = TextEditingController(text: task.title);
      _notes = TextEditingController(text: task.notes ?? '');
      _kind = task.kind;
      final due = task.dueAt?.toLocal();
      if (due != null) {
        _date = DateTime(due.year, due.month, due.day);
        _time = TimeOfDay(hour: due.hour, minute: due.minute);
      }
    } else if (notification != null) {
      final draft = TaskDraft.fromNotification(
        notification,
        kind: widget.initialKind,
      );
      _title = TextEditingController(text: draft.title);
      _notes = TextEditingController(text: draft.notes ?? '');
      _kind = widget.initialKind;
    } else {
      _title = TextEditingController();
      _notes = TextEditingController();
      _kind = widget.initialKind;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  DateTime? get _dueAt {
    final date = _date;
    if (date == null) return null;
    final time = _time ?? const TimeOfDay(hour: 9, minute: 0);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _date ?? DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dueError = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      final now = DateTime.now();
      setState(() {
        _time = picked;
        _date ??= DateTime(now.year, now.month, now.day);
        _dueError = null;
      });
    }
  }

  void _clearDue() {
    setState(() {
      _date = null;
      _time = null;
      _dueError = null;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final dueAt = _dueAt;
    if (_kind == TaskKind.reminder && dueAt == null) {
      setState(() => _dueError = 'A reminder needs a date and time');
      return;
    }
    final draft = TaskDraft(
      title: _title.text,
      notes: _notes.text,
      kind: _kind,
      dueAt: dueAt,
      calendarId: widget.task?.calendarId,
    );
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final tasks = widget.services.tasks;
      final existing = widget.task;
      final notification = widget.notification;
      final TaskItem? saved;
      if (existing != null) {
        saved = await tasks.updateDetails(existing.id, draft);
      } else if (notification != null) {
        final result = await tasks.createFromNotification(
          notification,
          draft: draft,
        );
        if (!result.created) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('This notification already has a task'),
            ),
          );
        }
        saved = result.task;
      } else {
        saved = await tasks.create(draft);
      }
      navigator.pop(saved);
    } on Exception {
      if (mounted) {
        setState(() => _saving = false);
        showMessage(context, 'Could not save the task.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.task != null;
    final date = _date;
    final time = _time;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing
              ? 'Edit task'
              : (_kind == TaskKind.reminder ? 'New reminder' : 'New task'),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              maxLength: TaskDraft.maxTitleLength,
              textInputAction: TextInputAction.next,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter a title'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 8,
            ),
            const SizedBox(height: 16),
            SegmentedButton<TaskKind>(
              segments: const [
                ButtonSegment<TaskKind>(
                  value: TaskKind.task,
                  label: Text('Task'),
                  icon: Icon(Icons.check_circle_outline),
                ),
                ButtonSegment<TaskKind>(
                  value: TaskKind.reminder,
                  label: Text('Reminder'),
                  icon: Icon(Icons.alarm),
                ),
              ],
              selected: <TaskKind>{_kind},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => setState(() {
                _kind = selection.first;
                _dueError = null;
              }),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(
                date == null
                    ? 'Date'
                    : '${date.year}-${date.month.toString().padLeft(2, '0')}-'
                          '${date.day.toString().padLeft(2, '0')}',
              ),
              subtitle: date == null ? const Text('Not set') : null,
              onTap: _pickDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(
                time == null
                    ? (date == null ? 'Time' : '09:00 (default)')
                    : '${time.hour.toString().padLeft(2, '0')}:'
                          '${time.minute.toString().padLeft(2, '0')}',
              ),
              onTap: _pickTime,
            ),
            if (date != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _clearDue,
                  child: const Text('Clear date and time'),
                ),
              ),
            if (_dueError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _dueError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_dueAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Due ${formatDue(_dueAt!)}'),
              ),
            const SizedBox(height: 8),
            Text(
              'Reminder alerts at the chosen time arrive in a later version; '
              'for now the time is saved and shown.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
