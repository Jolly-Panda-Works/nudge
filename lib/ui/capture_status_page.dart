import 'dart:async';

import 'package:flutter/material.dart';

import '../app_info.dart';
import '../app_services.dart';

/// Temporary status screen used to verify capture on a device. It shows only
/// states and counts, never notification text. The real inbox arrives in M1
/// section 4.
class CaptureStatusPage extends StatefulWidget {
  const CaptureStatusPage({required this.services, super.key});

  final AppServices services;

  @override
  State<CaptureStatusPage> createState() => _CaptureStatusPageState();
}

class _Status {
  const _Status({
    required this.accessGranted,
    required this.listenerConnected,
    required this.total,
    required this.active,
  });

  final bool accessGranted;
  final bool listenerConnected;
  final int total;
  final int active;
}

class _CaptureStatusPageState extends State<CaptureStatusPage>
    with WidgetsBindingObserver {
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];
  _Status? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscriptions
      ..add(widget.services.platform.signals.listen((_) => _refresh()))
      ..add(widget.services.ingestor.onDrained.listen((_) => _refresh()));
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final services = widget.services;
    final granted = await services.platform.isAccessGranted();
    final connected = await services.platform.isServiceConnected();
    final total = await services.notifications.count();
    final active = await services.notifications.count(activeOnly: true);
    if (!mounted) return;
    setState(() {
      _status = _Status(
        accessGranted: granted,
        listenerConnected: connected,
        total: total,
        active: active,
      );
    });
  }

  Future<void> _openSettings() async {
    final opened = await widget.services.platform.openAccessSettings();
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the settings screen on this device.'),
        ),
      );
    }
  }

  Future<void> _reconnect() async {
    await widget.services.platform.requestRebind();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return Scaffold(
      appBar: AppBar(title: const Text('$appName v$appVersion')),
      body: status == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Notification access: '
                  '${status.accessGranted ? 'granted' : 'not granted'}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Listener: '
                  '${status.listenerConnected ? 'connected' : 'not connected'}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Stored notifications: ${status.total} '
                  '(${status.active} active)',
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _openSettings,
                  child: const Text('Open Notification Access settings'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _reconnect,
                  child: const Text('Reconnect listener'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Temporary status screen. The inbox arrives in the next '
                  'section. Notification text is never shown here.',
                ),
              ],
            ),
    );
  }
}
