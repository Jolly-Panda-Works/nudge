import 'dart:async';

import 'package:flutter/material.dart';

import '../app_info.dart';
import '../app_services.dart';
import '../domain/ingest_policy.dart';
import '../domain/notification_export.dart';
import '../platform/data_exporter.dart';
import 'calendars_page.dart';
import 'content_width.dart';
import 'dialogs.dart';
import 'reminder_settings_section.dart';
import 'source_rules_page.dart';
import 'time_format.dart';
import '../l10n/l10n.dart';

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
    FilterMode.off => tr('All apps'),
    FilterMode.allowlist => tr('Only selected apps'),
    FilterMode.blocklist => tr('All apps except selected'),
  };

  static String _retentionLabel(int? days) =>
      days == null ? tr('Forever') : tr('{days} days', {'days': days});

  void _openCalendars() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CalendarsPage(services: widget.services),
      ),
    );
  }

  static String _themeLabel(String setting) => switch (setting) {
    'light' => tr('Light'),
    'dark' => tr('Dark'),
    _ => tr('System default'),
  };

  Future<void> _chooseTheme() async {
    final current = widget.services.theme.setting;
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(tr('Choose theme')),
        children: [
          for (final option in const <String>['system', 'light', 'dark'])
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(option),
              child: Text(
                _themeLabel(option),
                style: option == current
                    ? const TextStyle(fontWeight: FontWeight.bold)
                    : null,
              ),
            ),
        ],
      ),
    );
    if (chosen == null || chosen == current) return;
    try {
      await widget.services.theme.choose(chosen);
      if (mounted) setState(() {});
    } on Exception {
      if (mounted) {
        showMessage(context, tr('Could not apply the new setting.'));
      }
    }
  }

  static String _languageLabel(String setting) => switch (setting) {
    'en' => 'English',
    'fa' => 'فارسی',
    _ => tr('System default'),
  };

  Future<void> _chooseLanguage() async {
    final current = widget.services.language.setting;
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(tr('Choose language')),
        children: [
          for (final option in const <String>['system', 'en', 'fa'])
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(option),
              child: Text(
                _languageLabel(option),
                style: option == current
                    ? const TextStyle(fontWeight: FontWeight.bold)
                    : null,
              ),
            ),
        ],
      ),
    );
    if (chosen == null || chosen == current) return;
    try {
      // Every screen is rebuilt in the new language, so nothing follows.
      await widget.services.language.choose(chosen);
    } on Exception {
      if (mounted) {
        showMessage(context, tr('Could not apply the new setting.'));
      }
    }
  }

  Future<void> _chooseMode(FilterMode current) async {
    final chosen = await showDialog<FilterMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(tr('Capture mode')),
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
        title: Text(tr('Keep notifications for')),
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
      if (mounted) {
        showMessage(context, tr('Could not apply the new setting.'));
      }
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
      showMessage(context, tr('Could not open the settings screen on this device.'));
    }
  }

  Future<void> _export() async {
    final confirmed = await confirmAction(
      context,
      title: tr('Export data'),
      message: tr('The export file contains the full text of every stored '
          'notification, plus your tasks, and is not encrypted. Keep it '
          'somewhere safe.'),
      action: tr('Export'),
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
                ? tr('Export saved')
                : tr('Exported to {location}', {'location': result.location}),
          ExportOutcome.cancelled => tr('Export cancelled'),
          ExportOutcome.unsupported =>
            tr('Export is not available on this platform'),
        },
      );
    } on Exception {
      if (mounted) showMessage(context, tr('Export failed.'));
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await confirmAction(
      context,
      title: tr('Delete all notifications?'),
      message: tr('This removes every stored notification and anything still '
          'waiting to be stored. It cannot be undone. Your settings are kept.'),
      action: tr('Delete'),
    );
    if (!confirmed || !mounted) return;
    try {
      final deleted = await widget.services.notifications.deleteAll();
      await widget.services.platform.clearQueue();
      if (!mounted) return;
      showMessage(
        context,
        deleted == 1
            ? tr('Deleted 1 notification')
            : tr('Deleted {count} notifications', {'count': deleted}),
      );
      await _load();
    } on Exception {
      if (mounted) {
        showMessage(context, tr('Could not delete the notifications.'));
      }
    }
  }

  Future<void> _deleteAllTasks() async {
    final confirmed = await confirmAction(
      context,
      title: tr('Delete all tasks?'),
      message: tr('This removes every task and reminder, including done and '
          'archived ones. It cannot be undone. Notifications are kept.'),
      action: tr('Delete'),
    );
    if (!confirmed || !mounted) return;
    try {
      final deleted = await widget.services.tasks.deleteAll();
      if (!mounted) return;
      showMessage(
        context,
        deleted == 1
            ? tr('Deleted 1 task')
            : tr('Deleted {count} tasks', {'count': deleted}),
      );
    } on Exception {
      if (mounted) showMessage(context, tr('Could not delete the tasks.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final policy = _policy;
    final controller = widget.services.statusController;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Settings'))),
      body: ContentWidth(child: _failed
          ? Center(
              child: FilledButton(
                onPressed: _load,
                child: Text(tr('Retry')),
              ),
            )
          : policy == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  title: Text(tr('Language')),
                  subtitle: Text(
                    _languageLabel(widget.services.language.setting),
                  ),
                  trailing: const Icon(Icons.language),
                  onTap: _chooseLanguage,
                ),
                ListTile(
                  title: Text(tr('Theme')),
                  subtitle: Text(
                    _themeLabel(widget.services.theme.setting),
                  ),
                  trailing: const Icon(Icons.brightness_6),
                  onTap: _chooseTheme,
                ),
                _SectionHeader(tr('Notification access')),
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    final status = controller.status;
                    if (!controller.isSupported) {
                      return ListTile(
                        title: Text(tr('Not available on this platform')),
                        subtitle: Text(
                          tr('Notification capture is available on Android.'),
                        ),
                      );
                    }
                    final access = status == null
                        ? tr('checking')
                        : status.accessGranted
                        ? tr('granted')
                        : tr('not granted');
                    final listener = status == null
                        ? tr('checking')
                        : status.listenerConnected
                        ? tr('connected')
                        : tr('not connected');
                    return Column(
                      children: [
                        ListTile(
                          title: Text(tr('Access: {state}', {'state': access})),
                          subtitle: Text(tr('Listener: {state}', {'state': listener})),
                        ),
                        ListTile(
                          title: Text(tr('Open Notification Access settings')),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: _openAccessSettings,
                        ),
                        ListTile(
                          title: Text(tr('Reconnect listener')),
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
                if (widget.services.reminderPlatform.isSupported) ...[
                  _SectionHeader(tr('Reminders')),
                  ReminderSettingsSection(services: widget.services),
                ],
                ListTile(
                  title: Text(tr('Calendars')),
                  subtitle: Text(tr('Show calendars from this device')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openCalendars,
                ),
                _SectionHeader(tr('What to capture')),
                ListTile(
                  title: Text(tr('Capture mode')),
                  subtitle: Text(_modeLabel(policy.mode)),
                  onTap: () => _chooseMode(policy.mode),
                ),
                ListTile(
                  title: Text(tr('Choose apps')),
                  subtitle: Text(
                    policy.mode == FilterMode.off
                        ? tr('Not used in "All apps" mode')
                        : tr('{count} selected', {'count': policy.packages.length}),
                  ),
                  enabled: policy.mode != FilterMode.off,
                  onTap: policy.mode == FilterMode.off
                      ? null
                      : () => _openRules(policy.mode),
                ),
                SwitchListTile(
                  title: Text(tr('Ongoing notifications')),
                  subtitle: Text(
                    tr('Media players, navigation and other persistent '
                    'notifications'),
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
                  title: Text(tr('Group summaries')),
                  subtitle: Text(
                    tr('The combined entry apps post for a group of '
                    'notifications'),
                  ),
                  value: policy.captureGroupSummaries,
                  onChanged: (value) async {
                    await widget.services.settings.setCaptureGroupSummaries(
                      value: value,
                    );
                    await _load();
                  },
                ),
                _SectionHeader(tr('Your data')),
                ListTile(
                  title: Text(tr('Stored notifications: {count}', {'count': _total})),
                  subtitle: Text(tr('{count} active', {'count': _active})),
                ),
                ListTile(
                  title: Text(tr('Keep notifications for')),
                  subtitle: Text(_retentionLabel(_retentionDays)),
                  onTap: _chooseRetention,
                ),
                ListTile(
                  title: Text(tr('Export data')),
                  subtitle: Text(
                    tr('Save all stored notifications and tasks as a JSON file'),
                  ),
                  trailing: const Icon(Icons.file_download_outlined),
                  onTap: _export,
                ),
                ListTile(
                  title: Text(tr('Delete all notifications')),
                  subtitle: Text(
                    tr('Removes stored notifications and anything still queued'),
                  ),
                  trailing: const Icon(Icons.delete_outline),
                  onTap: _deleteAll,
                ),
                ListTile(
                  title: Text(tr('Delete all tasks')),
                  subtitle: Text(
                    tr('Removes every task and reminder, including done ones'),
                  ),
                  trailing: const Icon(Icons.delete_outline),
                  onTap: _deleteAllTasks,
                ),
                _SectionHeader(tr('About')),
                const ListTile(title: Text('$appName v$appVersion')),
              ],
            )),
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
