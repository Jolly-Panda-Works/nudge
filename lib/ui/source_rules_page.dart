import 'dart:async';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/ingest_policy.dart';
import '../domain/shared_source.dart';
import '../domain/source_app.dart';
import '../l10n/l10n.dart';

/// Lets the user pick the apps used by the allowlist or blocklist.
class SourceRulesPage extends StatefulWidget {
  const SourceRulesPage({
    required this.services,
    required this.mode,
    super.key,
  });

  final AppServices services;
  final FilterMode mode;

  @override
  State<SourceRulesPage> createState() => _SourceRulesPageState();
}

class _SourceRulesPageState extends State<SourceRulesPage> {
  static final RegExp _packagePattern = RegExp(
    r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$',
  );

  List<SourceApp>? _apps;
  Set<String> _selected = <String>{};
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final seen = (await widget.services.notifications.listSourceApps())
          .where((app) => app.packageName != sharedPackageName)
          .toList();
      final rules = await widget.services.settings.listRules();
      final byPackage = <String, SourceApp>{
        for (final app in seen) app.packageName: app,
        for (final rule in rules)
          if (!seen.any((app) => app.packageName == rule.packageName))
            rule.packageName: rule,
      };
      final apps = byPackage.values.toList()
        ..sort(
          (a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ),
        );
      if (!mounted) return;
      setState(() {
        _apps = apps;
        _selected = {for (final rule in rules) rule.packageName};
        _failed = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  Future<void> _toggle(SourceApp app, {required bool selected}) async {
    final settings = widget.services.settings;
    if (selected) {
      await settings.addRule(app.packageName, appLabel: app.label);
    } else {
      await settings.removeRule(app.packageName);
    }
    await _load();
  }

  Future<void> _addByPackage() async {
    final packageName = await showDialog<String>(
      context: context,
      builder: (_) => const _AddPackageDialog(),
    );
    if (packageName == null) return;
    await widget.services.settings.addRule(packageName);
    await _load();
  }

  String get _explanation => widget.mode == FilterMode.allowlist
      ? tr('Only the selected apps are captured.')
      : tr('Notifications from the selected apps are ignored.');

  @override
  Widget build(BuildContext context) {
    final apps = _apps;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Choose apps'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addByPackage,
        icon: const Icon(Icons.add),
        label: Text(tr('Add by package name')),
      ),
      body: _failed
          ? Center(
              child: FilledButton(
                onPressed: _load,
                child: Text(tr('Retry')),
              ),
            )
          : apps == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_explanation),
                ),
                if (apps.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      tr('No apps yet. Apps appear here after they post a '
                      'notification, or add one by package name.'),
                    ),
                  ),
                for (final app in apps)
                  SwitchListTile(
                    title: Text(app.displayName),
                    subtitle: app.label == null ? null : Text(app.packageName),
                    value: _selected.contains(app.packageName),
                    onChanged: (value) => _toggle(app, selected: value),
                  ),
              ],
            ),
    );
  }
}

class _AddPackageDialog extends StatefulWidget {
  const _AddPackageDialog();

  @override
  State<_AddPackageDialog> createState() => _AddPackageDialogState();
}

class _AddPackageDialogState extends State<_AddPackageDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (!_SourceRulesPageState._packagePattern.hasMatch(value)) {
      setState(() => _error = tr('Enter a package name such as com.example.app'));
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('Add by package name')),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: tr('Package name'),
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('Cancel')),
        ),
        FilledButton(onPressed: _submit, child: Text(tr('Add'))),
      ],
    );
  }
}
