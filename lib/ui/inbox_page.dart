import 'dart:async';

import 'package:flutter/material.dart';

import '../app_info.dart';
import '../app_services.dart';
import '../domain/captured_notification.dart';
import 'dialogs.dart';
import 'import_text_dialog.dart';
import 'notification_detail_page.dart';
import 'settings_page.dart';
import 'time_format.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({required this.services, super.key});

  final AppServices services;

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  bool _showRemoved = false;
  late Stream<List<CapturedNotification>> _stream = _openStream();

  Stream<List<CapturedNotification>> _openStream() =>
      widget.services.notifications.watchInbox(includeRemoved: _showRemoved);

  @override
  void initState() {
    super.initState();
    unawaited(widget.services.statusController.refresh());
  }

  void _setFilter({required bool showRemoved}) {
    setState(() {
      _showRemoved = showRemoved;
      _stream = _openStream();
    });
  }

  void _retry() => setState(() => _stream = _openStream());

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(services: widget.services),
      ),
    );
  }

  void _openDetail(CapturedNotification notification) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationDetailPage(
          notification: notification,
          services: widget.services,
        ),
      ),
    );
  }

  Future<void> _importText() async {
    final imported = await showDialog<ImportedText>(
      context: context,
      builder: (_) => const ImportTextDialog(),
    );
    if (imported == null) return;
    try {
      await widget.services.importer.importText(
        text: imported.text,
        title: imported.title,
      );
    } on Exception {
      if (mounted) showMessage(context, 'Could not import the text.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.services.statusController;
    return Scaffold(
      appBar: AppBar(
        title: const Text(appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _importText,
        tooltip: 'Import text',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => _AccessBanner(
              services: widget.services,
              supported: controller.isSupported,
              status: controller.status,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(value: false, label: Text('Active')),
                ButtonSegment<bool>(value: true, label: Text('All')),
              ],
              selected: <bool>{_showRemoved},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  _setFilter(showRemoved: selection.first),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CapturedNotification>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ErrorState(onRetry: _retry);
                }
                final items = snapshot.data;
                if (items == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (items.isEmpty) {
                  return ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) => _EmptyState(
                      supported: controller.isSupported,
                      accessGranted: controller.status?.accessGranted ?? false,
                    ),
                  );
                }
                final now = DateTime.now();
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _NotificationTile(
                    notification: items[index],
                    now: now,
                    onTap: () => _openDetail(items[index]),
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

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.now,
    required this.onTap,
  });

  final CapturedNotification notification;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appName = notification.appLabel ?? notification.packageName;
    final title =
        notification.title ??
        (notification.isRedacted ? 'Content hidden' : '(no title)');
    final removed = notification.status == NotificationStatus.removed;
    final snippet = notification.text;
    return ListTile(
      onTap: onTap,
      isThreeLine: snippet != null,
      leading: CircleAvatar(
        child: Text(appName.isEmpty ? '?' : appName[0].toUpperCase()),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$appName · ${formatTimestamp(notification.postedAt, now: now)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (snippet != null)
            Text(snippet, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
      trailing: removed ? const Chip(label: Text('Dismissed')) : null,
    );
  }
}

class _AccessBanner extends StatelessWidget {
  const _AccessBanner({
    required this.services,
    required this.supported,
    required this.status,
  });

  final AppServices services;
  final bool supported;
  final CaptureStatus? status;

  @override
  Widget build(BuildContext context) {
    final current = status;
    if (!supported || current == null) return const SizedBox.shrink();
    if (current.accessGranted && current.listenerConnected) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final needsAccess = !current.accessGranted;
    return Card(
      color: scheme.errorContainer,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              needsAccess
                  ? 'Notification access is off'
                  : 'Listener not connected',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              needsAccess
                  ? 'Nudge cannot capture notifications until you enable '
                        'Notification Access for it.'
                  : 'Notification access is on, but the listener is not '
                        'running. Try reconnecting.',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  if (needsAccess) {
                    await services.platform.openAccessSettings();
                  } else {
                    await services.platform.requestRebind();
                  }
                  await services.statusController.refresh();
                },
                child: Text(needsAccess ? 'Enable' : 'Reconnect'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.supported, required this.accessGranted});

  final bool supported;
  final bool accessGranted;

  @override
  Widget build(BuildContext context) {
    final String hint;
    if (!supported) {
      hint = 'Notification capture is available on Android.';
    } else if (!accessGranted) {
      hint = 'Enable Notification Access to start capturing.';
    } else {
      hint = 'New notifications from other apps will appear here.';
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none, size: 48),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(hint, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              'Could not load notifications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
