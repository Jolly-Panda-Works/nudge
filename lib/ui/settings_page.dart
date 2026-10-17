import 'dart:async';

import 'package:flutter/material.dart';

import '../app_info.dart';
import '../app_services.dart';
import '../domain/ingest_policy.dart';
import '../domain/notification_export.dart';
import '../platform/data_exporter.dart';
import 'dialogs.dart';
import 'source_rules_page.dart';
import 'time_format.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({required this.services, super.key});

  final AppServices services;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  CapturePolicy? _policy;
  int? _retentionDays;
  int _total = 0;
  int _active = 0;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(widget.services.statusController.refresh());
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final services = widget.services;
      final policy = await services.settings.loadPolicy();
      final retention = await services.settings.getRetentionDays();
      final total = await services.notifications.count();
      final active = await services.notifications.count(activeOnly: true);
      if (!mounted) return;
      setState(() {
        _policy = policy;
        _retentionDays = retention;
        _total = total;
        _active = active;
        _failed = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  static String _modeLabel(FilterMode mode) => switch (mode) {
    FilterMode.off => 'All apps',
    FilterMode.allowlist => 'Only selected apps',
    FilterMode.blocklist => 'All apps except selected',
  };

  static String _retentionLabel(int? days) =>
      days == null ? 'Forever' : '$days days';

  Future<void> _chooseMode(FilterMode current) async {
    final chosen = await showDialog<FilterMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Capture mode'),
        children: [
          for (final mode in FilterMode.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(mode),
              child: Text(
                _modeLabel(mode),
                style: mode == current
                    ? const TextStyle(fontWeight: FontWeight.bold)
                    : null,
              ),
            ),
        ],
      ),
    );
    if (chosen == null || chosen == current) return;
    await widget.services.settings.setMode(chosen);
    await _load();
  }

  Future<void> _chooseRetention() async {
    // 0 stands for "forever".
    const options = <int>[0, 7, 30, 90];
    final chosen = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Keep notifications for'),
        children: [
          for (final days in options)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(days),
              child: Text(_retentionLabel(days == 0 ? null : days)),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    final days = chosen == 0 ? null : chosen;
    if (days == _retentionDays) return;
    await widget.services.settings.setRetentionDays(days);
    try {
      await widget.services.retention.apply();
    } on Exception {
      if (mounted) showMessage(context, 'Could not apply the new setting.');
    }
    await _load();
  }

  Future<void> _openRules(FilterMode mode) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SourceRulesPage(services: widget.services, mode: mode),
      ),
    );
    await _load();
  }

  Future<void> _openAccessSettings() async {
    final opened = await widget.services.platform.openAccessSettings();
    if (!opened && mounted) {
      showMessage(context, 'Could not open the settings screen on this device.');
    }
  }

  Future<void> _export() async {
    final confirmed = await confirmAction(
      context,
      title: 'Export data',
      message: 'The export file contains the full text of every stored '
          'notification, plus your tasks, and is not encrypted. Keep it '
          'somewhere safe.',
      action: 'Export',
    );
    if (!confirmed || !mounted) return;
    try {
      final all = await widget.services.notifications.listAll();
      final tasks = await widget.services.tasks.listAll();
      final now = DateTime.now();
      final json = exportNotificationsJson(
        all,
        appVersion: appVersion,
        exportedAt: now,
        tasks: tasks,
      );
      final result = await widget.services.exporter.save(
        fileName: 'nudge-export-${formatFileStamp(now)}.json',
        content: json,
      );
      if (!mounted) return;
      showMessage(
        context,
        switch (result.outcome) {
          ExportOutcome.saved =>
            result.location == null
                ? 'Export saved'
                : 'Exported to ${result.location}',
          ExportOutcome.cancelled => 'Export cancelled',
          ExportOutcome.unsupported =>
            'Export is not available on this platform',
        },
      );
    } on Exception {
      if (mounted) showMessage(context, 'Export failed.');
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete all notifications?',
      message: 'This removes every stored notification and anything still '
          'waiting to be stored. It cannot be undone. Your settings are kept.',
      action: 'Delete',
    );
    if (!confirmed || !mounted) return;
    try {
      final deleted = await widget.services.notifications.deleteAll();
      await widget.services.platform.clearQueue();
      if (!mounted) return;
      showMessage(
        context,
        'Deleted $deleted ${deleted == 1 ? 'notification' : 'notifications'}',
      );
      await _load();
    } on Exception {
      if (mounted) showMessage(context, 'Could not delete the notifications.');
    }
  }

  Future<void> _deleteAllTasks() async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete all tasks?',
      message: 'This removes every task and reminder, including done and '
          'archived ones. It cannot be undone. Notifications are kept.',
      action: 'Delete',
    );
    if (!confirmed || !mounted) return;
    try {
      final deleted = await widget.services.tasks.deleteAll();
      if (!mounted) return;
      showMessage(
        context,
        'Deleted $deleted ${deleted == 1 ? 'task' : 'tasks'}',
      );
    } on Exception {
      if (mounted) showMessage(context, 'Could not delete the tasks.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final policy = _policy;
    final controller = widget.services.statusController;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _failed
          ? Center(
              child: FilledButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            )
          : policy == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const _SectionHeader('Notification access'),
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    final status = controller.status;
                    if (!controller.isSupported) {
                      return const ListTile(
                        title: Text('Not available on this platform'),
                        subtitle: Text(
                          'Notification capture is available on Android.',
                        ),
                      );
                    }
                    final access = status == null
                        ? 'checking'
                        : status.accessGranted
                        ? 'granted'
                        : 'not granted';
                    final listener = status == null
                        ? 'checking'
                        : status.listenerConnected
                        ? 'connected'
                        : 'not connected';
                    return Column(
                      children: [
                        ListTile(
                          title: Text('Access: $access'),
                          subtitle: Text('Listener: $listener'),
                        ),
                        ListTile(
                          title: const Text('Open Notification Access settings'),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: _openAccessSettings,
                        ),
                        ListTile(
                          title: const Text('Reconnect listener'),
                          trailing: const Icon(Icons.refresh),
                          onTap: () async {
                            await widget.services.platform.requestRebind();
                            await controller.refresh();
                          },
                        ),
                      ],
                    );
                  },
                ),
                const _SectionHeader('What to capture'),
                ListTile(
                  title: const Text('Capture mode'),
                  subtitle: Text(_modeLabel(policy.mode)),
                  onTap: () => _chooseMode(policy.mode),
                ),
                ListTile(
                  title: const Text('Choose apps'),
                  subtitle: Text(
                    policy.mode == FilterMode.off
                        ? 'Not used in "All apps" mode'
                        : '${policy.packages.length} selected',
                  ),
                  enabled: policy.mode != FilterMode.off,
                  onTap: policy.mode == FilterMode.off
                      ? null
                      : () => _openRules(policy.mode),
                ),
                SwitchListTile(
                  title: const Text('Ongoing notifications'),
                  subtitle: const Text(
                    'Media players, navigation and other persistent '
                    'notifications',
                  ),
                  value: policy.captureOngoing,
                  onChanged: (value) async {
                    await widget.services.settings.setCaptureOngoing(
                      value: value,
                    );
                    await _load();
                  },
                ),
                SwitchListTile(
                  title: const Text('Group summaries'),
                  subtitle: const Text(
                    'The combined entry apps post for a group of '
                    'notifications',
                  ),
                  value: policy.captureGroupSummaries,
                  onChanged: (value) async {
                    await widget.services.settings.setCaptureGroupSummaries(
                      value: value,
                    );
                    await _load();
                  },
                ),
                const _SectionHeader('Your data'),
                ListTile(
                  title: Text('Stored notifications: $_total'),
                  subtitle: Text('$_active active'),
                ),
                ListTile(
                  title: const Text('Keep notifications for'),
                  subtitle: Text(_retentionLabel(_retentionDays)),
                  onTap: _chooseRetention,
                ),
                ListTile(
                  title: const Text('Export data'),
                  subtitle: const Text(
                    'Save all stored notifications and tasks as a JSON file',
                  ),
                  trailing: const Icon(Icons.file_download_outlined),
                  onTap: _export,
                ),
                ListTile(
                  title: const Text('Delete all notifications'),
                  subtitle: const Text(
                    'Removes stored notifications and anything still queued',
                  ),
                  trailing: const Icon(Icons.delete_outline),
                  onTap: _deleteAll,
                ),
                ListTile(
                  title: const Text('Delete all tasks'),
                  subtitle: const Text(
                    'Removes every task and reminder, including done ones',
                  ),
                  trailing: const Icon(Icons.delete_outline),
                  onTap: _deleteAllTasks,
                ),
                const _SectionHeader('About'),
                const ListTile(title: Text('$appName v$appVersion')),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
