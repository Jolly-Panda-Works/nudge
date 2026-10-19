import 'dart:async';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../application/calendar_integration.dart';
import '../domain/external_calendar.dart';
import '../l10n/l10n.dart';
import 'content_width.dart';
import 'dialogs.dart';

/// Turning the device calendars on, and choosing which ones Nudge shows and
/// where new events are saved. The permission is requested only when the
/// switch is turned on.
class CalendarsPage extends StatefulWidget {
  const CalendarsPage({required this.services, super.key});

  final AppServices services;

  @override
  State<CalendarsPage> createState() => _CalendarsPageState();
}

class _CalendarsPageState extends State<CalendarsPage>
    with WidgetsBindingObserver {
  CalendarState? _state;
  bool _failed = false;

  /// True between turning the switch on and the answer to the system dialog.
  bool _awaitingPermission = false;

  /// True after the user refused the permission.
  bool _refused = false;

  CalendarIntegration get _integration => widget.services.calendars;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_onResumed());
  }

  Future<void> _onResumed() async {
    if (_awaitingPermission) {
      _awaitingPermission = false;
      try {
        final enabled = await _integration.completeEnable();
        if (mounted) setState(() => _refused = !enabled);
      } on Exception {
        if (mounted) setState(() => _failed = true);
      }
    }
    await _load();
  }

  Future<void> _load() async {
    try {
      final state = await _integration.load();
      if (!mounted) return;
      setState(() {
        _state = state;
        _failed = false;
      });
    } on Exception {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _toggle({required bool on}) async {
    try {
      if (!on) {
        await _integration.disable();
        setState(() => _refused = false);
        await _load();
        return;
      }
      final outcome = await _integration.enable();
      if (!mounted) return;
      switch (outcome) {
        case EnableOutcome.enabled:
          setState(() => _refused = false);
          await _load();
        case EnableOutcome.permissionRequested:
          _awaitingPermission = true;
        case EnableOutcome.unsupported:
          break;
      }
    } on Exception {
      if (mounted) showMessage(context, tr('Could not apply the new setting.'));
    }
  }

  Future<void> _openSettings() async {
    final opened = await _integration.openAppSettings();
    if (!opened && mounted) {
      showMessage(context, tr('Could not open the settings screen.'));
    }
  }

  Future<void> _setVisible(
    CalendarState state,
    ExternalCalendar calendar, {
    required bool visible,
  }) async {
    try {
      await _integration.setVisible(state, calendar, visible: visible);
      await _load();
    } on Exception {
      if (mounted) showMessage(context, tr('Could not apply the new setting.'));
    }
  }

  Future<void> _chooseDefault(CalendarState state) async {
    final writable = state.writable;
    if (writable.isEmpty) return;
    // The dialog result is wrapped so that "None" is different from closing it.
    final choice = await showDialog<({ExternalCalendar? calendar})>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(tr('Save new events to')),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop((calendar: null)),
            child: Text(tr('None')),
          ),
          for (final calendar in writable)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop((calendar: calendar)),
              child: Text(
                '${calendar.label} · ${calendar.accountName}',
                style: calendar.id == state.defaultId
                    ? const TextStyle(fontWeight: FontWeight.bold)
                    : null,
              ),
            ),
        ],
      ),
    );
    if (choice == null) return;
    try {
      await _integration.setDefault(state, choice.calendar);
      await _load();
    } on Exception {
      if (mounted) showMessage(context, tr('Could not apply the new setting.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Calendars'))),
      body: ContentWidth(
        child: _failed
            ? Center(
                child: FilledButton(
                  onPressed: _load,
                  child: Text(tr('Retry')),
                ),
              )
            : state == null
            ? const Center(child: CircularProgressIndicator())
            : !state.supported
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    tr('Calendars on this device are available on Android.'),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : _content(context, state),
      ),
    );
  }

  Widget _content(BuildContext context, CalendarState state) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final children = <Widget>[
      SwitchListTile(
        title: Text(tr('Show device calendars')),
        subtitle: Text(
          tr(
            'Reads the calendars of the accounts on this phone, such as '
            'Google or Samsung. Nudge asks for permission only when you '
            'turn this on.',
          ),
        ),
        value: state.enabled,
        onChanged: (on) => _toggle(on: on),
      ),
    ];
    if (_refused && !state.enabled) {
      children.add(
        ListTile(
          leading: Icon(Icons.info_outline, color: scheme.error),
          title: Text(tr('Calendar access was not allowed')),
          trailing: TextButton(
            onPressed: _openSettings,
            child: Text(tr('Open settings')),
          ),
        ),
      );
    }
    if (state.permissionLost) {
      children.add(
        ListTile(
          leading: Icon(Icons.warning_amber, color: scheme.error),
          title: Text(tr('Calendar permission was turned off')),
          trailing: TextButton(
            onPressed: _openSettings,
            child: Text(tr('Open settings')),
          ),
        ),
      );
    }
    if (state.enabled && state.permissions.read) {
      if (state.readFailed) {
        children.add(
          ListTile(
            title: Text(tr('The calendars could not be read.')),
            trailing: TextButton(
              onPressed: _load,
              child: Text(tr('Retry')),
            ),
          ),
        );
      } else if (state.calendars.isEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(tr('No calendars found on this device.')),
          ),
        );
      } else {
        String? account;
        for (final calendar in state.calendars) {
          final key = '${calendar.accountType}|${calendar.accountName}';
          if (key != account) {
            account = key;
            children.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  '${calendar.accountKind} · ${calendar.accountName}',
                  style: textTheme.titleSmall?.copyWith(color: scheme.primary),
                ),
              ),
            );
          }
          children.add(
            SwitchListTile(
              secondary: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(calendar.color ?? 0xFF9E9E9E),
                ),
              ),
              title: Text(calendar.label),
              subtitle: calendar.canWrite ? null : Text(tr('Read only')),
              value: state.isVisible(calendar),
              onChanged: (visible) =>
                  _setVisible(state, calendar, visible: visible),
            ),
          );
        }
        final writable = state.writable;
        final defaultCalendar = writable
            .where((c) => c.id == state.defaultId)
            .firstOrNull;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
            child: Text(
              tr('New events'),
              style: textTheme.titleSmall?.copyWith(color: scheme.primary),
            ),
          ),
        );
        children.add(
          ListTile(
            title: Text(tr('Save new events to')),
            subtitle: Text(
              writable.isEmpty
                  ? tr('No writable calendar')
                  : (defaultCalendar?.label ?? tr('Not set')),
            ),
            enabled: writable.isNotEmpty,
            onTap: () => _chooseDefault(state),
          ),
        );
      }
    }
    return ListView(children: children);
  }
}
