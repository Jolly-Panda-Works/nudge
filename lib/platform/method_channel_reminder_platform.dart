import 'dart:convert';

import 'package:flutter/services.dart';

import 'reminder_platform.dart';

/// Android implementation backed by the Kotlin `ReminderChannels`.
final class MethodChannelReminderPlatform implements ReminderPlatform {
  MethodChannelReminderPlatform({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('app.nudge/reminders');

  final MethodChannel _channel;

  @override
  bool get isSupported => true;

  @override
  Future<ReminderPermissions> permissions() async {
    final map = await _channel.invokeMapMethod<String, Object?>('permissions');
    return ReminderPermissions(
      notificationsAllowed: map?['notifications'] == true,
      exactAlarmsAllowed: map?['exactAlarms'] == true,
    );
  }

  @override
  Future<bool> requestNotificationPermission() async =>
      await _channel.invokeMethod<bool>('requestNotificationPermission') ??
      false;

  @override
  Future<bool> openNotificationSettings() async =>
      await _channel.invokeMethod<bool>('openNotificationSettings') ?? false;

  @override
  Future<bool> openExactAlarmSettings() async =>
      await _channel.invokeMethod<bool>('openExactAlarmSettings') ?? false;

  @override
  Future<void> sync(List<ReminderEntry> entries) {
    return _channel.invokeMethod<void>('sync', <String, Object?>{
      'entries': <Map<String, Object?>>[
        for (final entry in entries)
          <String, Object?>{
            'taskId': entry.taskId,
            'title': entry.title,
            'atMillis': entry.at.millisecondsSinceEpoch,
          },
      ],
    });
  }

  @override
  Future<List<ReminderSnooze>> drainSnoozes() async {
    final lines =
        await _channel.invokeListMethod<String>('drainEvents') ??
        const <String>[];
    final snoozes = <ReminderSnooze>[];
    for (final line in lines) {
      try {
        final data = jsonDecode(line);
        if (data is! Map<String, Object?> || data['type'] != 'snoozed') {
          continue;
        }
        final taskId = data['taskId'];
        final until = data['untilMillis'];
        if (taskId is String && until is num) {
          snoozes.add(
            ReminderSnooze(
              taskId: taskId,
              until: DateTime.fromMillisecondsSinceEpoch(
                until.toInt(),
                isUtc: true,
              ),
            ),
          );
        }
      } on FormatException {
        // Unreadable line: skipped.
      }
    }
    return snoozes;
  }
}
