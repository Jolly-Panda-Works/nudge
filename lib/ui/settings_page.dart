import 'dart:async';

import 'package:flutter/material.dart';

import '../app_info.dart';
import '../app_services.dart';
import '../domain/ingest_policy.dart';
import 'source_rules_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({required this.services, super.key});

  final AppServices services;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  CapturePolicy? _policy;
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
      final policy = await widget.services.settings.loadPolicy();
      final total = await widget.services.notifications.count();
      final active = await widget.services.notifications.count(
        activeOnly: true,
      );
      if (!mounted) return;
      setState(() {
        _policy = policy;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the settings screen on this device.'),
        ),
      );
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
                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            'Access: ${status == null
                                ? 'checking'
                                : status.accessGranted
                                ? 'granted'
                                : 'not granted'}',
                          ),
                          subtitle: Text(
                            'Listener: ${status == null
                                ? 'checking'
                                : status.listenerConnected
                                ? 'connected'
                                : 'not connected'}',
                          ),
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
                const _SectionHeader('Stored data'),
                ListTile(
                  title: Text('Stored notifications: $_total'),
                  subtitle: Text('$_active active'),
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
