import 'dart:async';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../platform/reminder_platform.dart';
import 'dialogs.dart';
import '../l10n/l10n.dart';

/// Shows whether reminder alerts can reach the user and how to fix it.
/// Refreshes when the app returns from the system settings screens.
/// Draws nothing on platforms without reminder alerts.
class ReminderSettingsSection extends StatefulWidget {
  const ReminderSettingsSection({required this.services, super.key});

  final AppServices services;

  @override
  State<ReminderSettingsSection> createState() =>
      _ReminderSettingsSectionState();
}

class _ReminderSettingsSectionState extends State<ReminderSettingsSection>
    with WidgetsBindingObserver {
  ReminderPermissions? _permissions;

  ReminderPlatform get _platform => widget.services.reminderPlatform;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh());
      unawaited(
        widget.services.reminderScheduler.sync().then<void>(
          (_) {},
          onError: (Object _) {},
        ),
      );
    }
  }

  Future<void> _refresh() async {
    if (!_platform.isSupported) return;
    try {
      final permissions = await _platform.permissions();
      if (mounted) setState(() => _permissions = permissions);
    } on Exception {
      // The tiles stay in the "checking" state.
    }
  }

  Future<void> _fixNotifications() async {
    final allowed = await _platform.requestNotificationPermission();
    if (!mounted) return;
    if (allowed) {
      await _refresh();
      return;
    }
    // Either the system dialog is showing, or it was refused before and will
    // not show again; the second case needs the system settings screen.
    final opened = await _platform.openNotificationSettings();
    if (!opened && mounted) {
      showMessage(context, tr('Could not open the settings screen.'));
    }
  }

  Future<void> _fixExactAlarms() async {
    final opened = await _platform.openExactAlarmSettings();
    if (!opened && mounted) {
      showMessage(context, tr('Could not open the settings screen.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_platform.isSupported) return const SizedBox.shrink();
    final permissions = _permissions;
    return Column(
      children: [
        ListTile(
          title: Text(tr('Reminder alerts')),
          subtitle: Text(
            permissions == null
                ? tr('Checking')
                : permissions.notificationsAllowed
                ? tr('Allowed')
                : tr('Blocked: reminders will not be shown'),
          ),
          trailing: permissions?.notificationsAllowed ?? true
              ? null
              : const Icon(Icons.open_in_new),
          onTap: permissions?.notificationsAllowed ?? true
              ? null
              : _fixNotifications,
        ),
        ListTile(
          title: Text(tr('Exact timing')),
          subtitle: Text(
            permissions == null
                ? tr('Checking')
                : permissions.exactAlarmsAllowed
                ? tr('Allowed')
                : tr('Not allowed: alerts may arrive a few minutes late'),
          ),
          trailing: permissions?.exactAlarmsAllowed ?? true
              ? null
              : const Icon(Icons.open_in_new),
          onTap: permissions?.exactAlarmsAllowed ?? true
              ? null
              : _fixExactAlarms,
        ),
      ],
    );
  }
}
