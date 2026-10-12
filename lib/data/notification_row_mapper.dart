import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../domain/captured_notification.dart';
import '../domain/source_ref.dart';
import 'database/app_database.dart';

DateTime _fromMs(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

List<String> _decodeTitles(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is List<Object?>) {
      return List<String>.unmodifiable(decoded.whereType<String>());
    }
  } on FormatException {
    // Fall through: corrupt value is treated as "no actions".
  }
  return const <String>[];
}

CapturedNotification notificationFromRow(NotificationRow row) {
  return CapturedNotification(
    key: row.notificationKey,
    packageName: row.packageName,
    appLabel: row.appLabel,
    title: row.title,
    text: row.body,
    postedAt: _fromMs(row.postedAtMs),
    groupKey: row.groupKey,
    isGroupSummary: row.isGroupSummary,
    isOngoing: row.isOngoing,
    isRedacted: row.isRedacted,
    contentHash: row.contentHash,
    source: SourceRef(
      packageName: row.packageName,
      notificationKey: row.notificationKey,
      hasContentAction: row.sourceHasContentAction,
      actionTitles: _decodeTitles(row.sourceActionTitles),
    ),
    status: row.status,
    firstSeenAt: _fromMs(row.firstSeenAtMs),
    lastUpdatedAt: _fromMs(row.lastUpdatedAtMs),
    updateCount: row.updateCount,
  );
}

NotificationsCompanion notificationToCompanion(CapturedNotification n) {
  return NotificationsCompanion(
    notificationKey: Value(n.key),
    packageName: Value(n.packageName),
    appLabel: Value(n.appLabel),
    title: Value(n.title),
    body: Value(n.text),
    postedAtMs: Value(n.postedAt.millisecondsSinceEpoch),
    groupKey: Value(n.groupKey),
    isGroupSummary: Value(n.isGroupSummary),
    isOngoing: Value(n.isOngoing),
    isRedacted: Value(n.isRedacted),
    contentHash: Value(n.contentHash),
    sourceHasContentAction: Value(n.source.hasContentAction),
    sourceActionTitles: Value(jsonEncode(n.source.actionTitles)),
    status: Value(n.status),
    firstSeenAtMs: Value(n.firstSeenAt.millisecondsSinceEpoch),
    lastUpdatedAtMs: Value(n.lastUpdatedAt.millisecondsSinceEpoch),
    updateCount: Value(n.updateCount),
  );
}
