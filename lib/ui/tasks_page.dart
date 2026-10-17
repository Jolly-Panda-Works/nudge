import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/task.dart';
import 'dialogs.dart';
import 'task_detail_page.dart';
import 'task_form_page.dart';
import 'time_format.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({required this.services, super.key});

  final AppServices services;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  TaskStatus _status = TaskStatus.open;
  late Stream<List<TaskItem>> _stream = _openStream();

  Stream<List<TaskItem>> _openStream() =>
      widget.services.tasks.watchTasks(statuses: <TaskStatus>{_status});

  void _setStatus(TaskStatus status) {
    setState(() {
      _status = status;
      _stream = _openStream();
    });
  }

  void _retry() => setState(() => _stream = _openStream());

  Future<void> _add() async {
    await Navigator.of(context).push<TaskItem>(
      MaterialPageRoute<TaskItem>(
        builder: (_) => TaskFormPage(services: widget.services),
      ),
    );
  }

  void _open(TaskItem task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailPage(task: task, services: widget.services),
      ),
    );
  }

  Future<void> _toggle(TaskItem task) async {
    try {
      final tasks = widget.services.tasks;
      if (task.status == TaskStatus.open) {
        await tasks.markDone(task.id);
      } else if (task.status == TaskStatus.done) {
        await tasks.reopen(task.id);
      }
    } on Exception {
      if (mounted) showMessage(context, 'Could not update the task.');
    }
  }

  String _emptyText() => switch (_status) {
    TaskStatus.open => 'No open tasks',
    TaskStatus.done => 'Nothing done yet',
    TaskStatus.archived => 'Nothing archived',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        tooltip: 'New task',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SegmentedButton<TaskStatus>(
              segments: const [
                ButtonSegment<TaskStatus>(
                  value: TaskStatus.open,
                  label: Text('Open'),
                ),
                ButtonSegment<TaskStatus>(
                  value: TaskStatus.done,
                  label: Text('Done'),
                ),
                ButtonSegment<TaskStatus>(
                  value: TaskStatus.archived,
                  label: Text('Archived'),
                ),
              ],
              selected: <TaskStatus>{_status},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => _setStatus(selection.first),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TaskItem>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Could not load the tasks.'),
                        TextButton(
                          onPressed: _retry,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final items = snapshot.data;
                if (items == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (items.isEmpty) {
                  return Center(child: Text(_emptyText()));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _TaskTile(
                    task: items[index],
                    onTap: () => _open(items[index]),
                    onToggle: () => _toggle(items[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onTap,
    required this.onToggle,
  });

  final TaskItem task;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final remindAt = task.remindAt;
    final parts = <String>[
      if (task.kind == TaskKind.reminder) 'Reminder',
      if (remindAt != null) formatDue(remindAt),
      if (task.source != null)
        task.source!.appLabel ?? task.source!.packageName,
    ];
    final done = task.status == TaskStatus.done;
    return ListTile(
      onTap: onTap,
      leading: task.status == TaskStatus.archived
          ? const Icon(Icons.archive_outlined)
          : Checkbox(
              value: done,
              onChanged: (_) => onToggle(),
              semanticLabel: done ? 'Reopen task' : 'Mark task done',
            ),
      title: Text(
        task.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: done
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: parts.isEmpty ? null : Text(parts.join(' · ')),
    );
  }
}
