import 'dart:convert';

import 'captured_notification.dart';

/// Serializes stored notifications for the user's own export file.
/// The result contains full notification text and is not encrypted.
String exportNotificationsJson(
  List<CapturedNotification> notifications, {
  required String appVersion,
  required DateTime exportedAt,
}) {
  final data = <String, Object?>{
    'app': 'Nudge',
    'formatVersion': 1,
    'appVersion': appVersion,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'notifications': [for (final n in notifications) _toMap(n)],
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
