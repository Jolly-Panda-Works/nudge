import 'package:flutter/material.dart';

import '../app_services.dart';
import '../application/source_navigator.dart';
import '../domain/task.dart';
import 'dialogs.dart';
import 'task_form_page.dart';
import 'time_format.dart';

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({required this.task, required this.services, super.key});

  final TaskItem task;
  final AppServices services;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late TaskItem _task = widget.task;

  /// Runs a change; null from the repository means the task is gone.
  Future<void> _apply(Future<TaskItem?> Function() change) async {
    try {
      final updated = await change();
      if (!mounted) return;
      if (updated == null) {
        Navigator.of(context).pop();
      } else {
        setState(() => _task = updated);
      }
    } on Exception {
      if (mounted) showMessage(context, 'Could not update the task.');
    }
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<TaskItem>(
      MaterialPageRoute<TaskItem>(
        builder: (_) => TaskFormPage(services: widget.services, task: _task),
      ),
    );
    if (saved != null && mounted) setState(() => _task = saved);
  }

  Future<void> _snooze() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 9);
    final options = <String, DateTime>{
      'In 15 minutes': now.add(const Duration(minutes: 15)),
      'In 1 hour': now.add(const Duration(hours: 1)),
      'In 3 hours': now.add(const Duration(hours: 3)),
      'Tomorrow at 09:00': tomorrow,
    };
    final choice = await showDialog<DateTime>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Snooze until'),
        children: [
          for (final entry in options.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(entry.value),
              child: Text(entry.key),
            ),
        ],
      ),
    );
    if (choice == null) return;
    await _apply(() => widget.services.tasks.snooze(_task.id, choice));
  }

  Future<void> _delete() async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete task?',
      message:
          'The task is removed from Nudge. The notification it came '
          'from is not affected.',
      action: 'Delete',
    );
    if (!confirmed || !mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.services.tasks.delete(_task.id);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Task deleted')));
    } on Exception {
      if (mounted) showMessage(context, 'Could not delete the task.');
    }
  }

  Future<void> _openOriginal() async {
    final source = _task.source;
    if (source == null) return;
    final outcome = await widget.services.sourceNavigator.open(
      packageName: source.packageName,
      notificationKey: source.notificationKey,
    );
    if (!mounted) return;
    showMessage(context, sourceOutcomeMessage(outcome));
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    final tasks = widget.services.tasks;
    final source = task.source;
    final remindAt = task.remindAt;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(task.kind == TaskKind.reminder ? 'Reminder' : 'Task'),
        actions: [
          if (task.status != TaskStatus.archived)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: _edit,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete task',
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SelectableText(task.title, style: textTheme.titleLarge),
          if (task.notes != null) ...[
            const SizedBox(height: 12),
            SelectableText(task.notes!),
          ],
          const SizedBox(height: 16),
          _Row(label: 'Status', value: _statusLabel(task.status)),
          if (task.dueAt != null)
            _Row(label: 'Due', value: formatDue(task.dueAt!)),
          if (task.snoozedUntil != null)
            _Row(label: 'Snoozed until', value: formatDue(task.snoozedUntil!)),
          if (remindAt == null && task.kind == TaskKind.reminder)
            const _Row(label: 'Due', value: 'Not set'),
          if (source != null)
            _Row(label: 'From', value: source.appLabel ?? source.packageName),
          _Row(label: 'Created', value: formatFullTimestamp(task.createdAt)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (task.status == TaskStatus.open)
                FilledButton.icon(
                  onPressed: () => _apply(() => tasks.markDone(task.id)),
                  icon: const Icon(Icons.check),
                  label: const Text('Mark done'),
                ),
              if (task.status == TaskStatus.done)
                FilledButton.icon(
                  onPressed: () => _apply(() => tasks.reopen(task.id)),
                  icon: const Icon(Icons.undo),
                  label: const Text('Reopen'),
                ),
              if (task.status == TaskStatus.open)
                OutlinedButton.icon(
                  onPressed: _snooze,
                  icon: const Icon(Icons.snooze),
                  label: const Text('Snooze'),
                ),
              if (task.status == TaskStatus.archived)
                OutlinedButton.icon(
                  onPressed: () => _apply(() => tasks.restore(task.id)),
                  icon: const Icon(Icons.unarchive_outlined),
                  label: const Text('Restore'),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => _apply(() => tasks.archive(task.id)),
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Archive'),
                ),
              if (source != null)
                OutlinedButton.icon(
                  onPressed: _openOriginal,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open original'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _statusLabel(TaskStatus status) => switch (status) {
  TaskStatus.open => 'Open',
  TaskStatus.done => 'Done',
  TaskStatus.archived => 'Archived',
};

/// Plain-language result of "Open original", shared by every screen that has
/// the action.
String sourceOutcomeMessage(SourceOpenOutcome outcome) => switch (outcome) {
  SourceOpenOutcome.openedOriginal => 'Opened the original notification',
  SourceOpenOutcome.openedApp =>
    'The notification is gone, so the app was opened instead',
  SourceOpenOutcome.unavailable =>
    'The original is not available. The saved content is kept here.',
};

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
