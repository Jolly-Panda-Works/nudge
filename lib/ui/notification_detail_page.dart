import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/captured_notification.dart';
import '../domain/shared_source.dart';
import '../domain/task.dart';
import 'dialogs.dart';
import 'task_detail_page.dart';
import 'task_form_page.dart';
import 'time_format.dart';

class NotificationDetailPage extends StatefulWidget {
  const NotificationDetailPage({
    required this.notification,
    required this.services,
    super.key,
  });

  final CapturedNotification notification;
  final AppServices services;

  @override
  State<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  CapturedNotification get notification => widget.notification;
  AppServices get services => widget.services;

  late Future<TaskItem?> _linkedTask = _findTask();

  Future<TaskItem?> _findTask() async {
    try {
      return await services.tasks.findBySourceKey(notification.key);
    } on Exception {
      return null;
    }
  }

  Future<void> _createTask(TaskKind kind) async {
    await Navigator.of(context).push<TaskItem>(
      MaterialPageRoute<TaskItem>(
        builder: (_) => TaskFormPage(
          services: services,
          notification: notification,
          initialKind: kind,
        ),
      ),
    );
    if (mounted) setState(() => _linkedTask = _findTask());
  }

  Future<void> _viewTask(TaskItem task) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailPage(task: task, services: services),
      ),
    );
    if (mounted) setState(() => _linkedTask = _findTask());
  }

  Future<void> _openOriginal() async {
    final outcome = await services.sourceNavigator.open(
      packageName: notification.packageName,
      notificationKey: notification.key,
    );
    if (!mounted) return;
    showMessage(context, sourceOutcomeMessage(outcome));
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete notification?',
      message:
          'It will be removed from Nudge. The original notification in '
          'the source app is not affected.',
      action: 'Delete',
    );
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await services.notifications.deleteByKey(notification.key);
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Notification deleted')),
      );
    } on Exception {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not delete the notification.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final removed = n.status == NotificationStatus.removed;
    final imported = n.packageName == sharedPackageName;
    final titleStyle = Theme.of(context).textTheme.titleLarge;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete notification',
            onPressed: () => _delete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (n.title != null)
            SelectableText(n.title!, style: titleStyle)
          else
            Text(
              n.isRedacted ? 'Content hidden by Android' : '(no title)',
              style: titleStyle,
            ),
          const SizedBox(height: 12),
          if (n.text != null)
            SelectableText(n.text!)
          else if (n.isRedacted)
            const Text(
              'The system did not share this notification\'s content with '
              'Nudge.',
            ),
          const SizedBox(height: 24),
          _Row(
            label: 'Source',
            value: imported
                ? 'Shared or imported text'
                : n.appLabel ?? n.packageName,
          ),
          if (!imported) _Row(label: 'Package', value: n.packageName),
          _Row(
            label: imported ? 'Added' : 'Posted',
            value: formatFullTimestamp(n.postedAt),
          ),
          _Row(label: 'First seen', value: formatFullTimestamp(n.firstSeenAt)),
          _Row(
            label: 'Last updated',
            value: formatFullTimestamp(n.lastUpdatedAt),
          ),
          _Row(label: 'Updates', value: '${n.updateCount}'),
          if (!imported)
            _Row(label: 'Status', value: removed ? 'Dismissed' : 'Active'),
          if (!imported)
            _Row(
              label: 'Original action',
              value: n.source.hasContentAction
                  ? 'Existed when captured'
                  : 'None when captured',
            ),
          const SizedBox(height: 16),
          FutureBuilder<TaskItem?>(
            future: _linkedTask,
            builder: (context, snapshot) {
              final task = snapshot.data;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (task != null)
                    FilledButton.icon(
                      onPressed: () => _viewTask(task),
                      icon: const Icon(Icons.task_alt),
                      label: const Text('View task'),
                    )
                  else if (snapshot.connectionState ==
                      ConnectionState.done) ...[
                    FilledButton.icon(
                      onPressed: () => _createTask(TaskKind.task),
                      icon: const Icon(Icons.add_task),
                      label: const Text('Create task'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _createTask(TaskKind.reminder),
                      icon: const Icon(Icons.alarm_add),
                      label: const Text('Create reminder'),
                    ),
                  ],
                  if (!imported)
                    OutlinedButton.icon(
                      onPressed: _openOriginal,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open original'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

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
