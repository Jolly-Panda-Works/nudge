import 'dart:convert';

import 'captured_notification.dart';
import 'task.dart';

/// Serializes stored notifications for the user's own export file.
/// Tasks are included. The result contains full notification text and is not
/// encrypted.
String exportNotificationsJson(
  List<CapturedNotification> notifications, {
  required String appVersion,
  required DateTime exportedAt,
  List<TaskItem> tasks = const <TaskItem>[],
}) {
  final data = <String, Object?>{
    'app': 'Nudge',
    'formatVersion': 1,
    'appVersion': appVersion,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'notifications': [for (final n in notifications) _toMap(n)],
    'tasks': [for (final t in tasks) _taskToMap(t)],
  };
  return const JsonEncoder.withIndent('  ').convert(data);
}

Map<String, Object?> _toMap(CapturedNotification n) => <String, Object?>{
  'key': n.key,
  'packageName': n.packageName,
  'appLabel': n.appLabel,
  'title': n.title,
  'text': n.text,
  'postedAt': n.postedAt.toUtc().toIso8601String(),
  'groupKey': n.groupKey,
  'isGroupSummary': n.isGroupSummary,
  'isOngoing': n.isOngoing,
  'isRedacted': n.isRedacted,
  'status': n.status.name,
  'firstSeenAt': n.firstSeenAt.toUtc().toIso8601String(),
  'lastUpdatedAt': n.lastUpdatedAt.toUtc().toIso8601String(),
  'updateCount': n.updateCount,
  'hasContentAction': n.source.hasContentAction,
  'actionTitles': n.source.actionTitles,
};

Map<String, Object?> _taskToMap(TaskItem t) => <String, Object?>{
  'id': t.id,
  'title': t.title,
  'notes': t.notes,
  'kind': t.kind.name,
  'status': t.status.name,
  'dueAt': t.dueAt?.toUtc().toIso8601String(),
  'snoozedUntil': t.snoozedUntil?.toUtc().toIso8601String(),
  'calendarId': t.calendarId,
  'createdAt': t.createdAt.toUtc().toIso8601String(),
  'updatedAt': t.updatedAt.toUtc().toIso8601String(),
  'completedAt': t.completedAt?.toUtc().toIso8601String(),
  'source': t.source == null
      ? null
      : <String, Object?>{
          'notificationKey': t.source!.notificationKey,
          'packageName': t.source!.packageName,
          'appLabel': t.source!.appLabel,
          'hasContentAction': t.source!.hasContentAction,
        },
};
