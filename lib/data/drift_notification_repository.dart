import 'package:drift/drift.dart';

import '../domain/captured_notification.dart';
import '../domain/ingest_policy.dart';
import '../domain/notification_repository.dart';
import '../domain/source_app.dart';
import 'database/app_database.dart';
import 'notification_row_mapper.dart';

final class DriftNotificationRepository implements NotificationRepository {
  DriftNotificationRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  int get _nowMs => _clock().toUtc().millisecondsSinceEpoch;

  @override
  Future<CapturedNotification?> findByKey(String notificationKey) async {
    final row =
        await (_db.select(_db.notifications)
              ..where((t) => t.notificationKey.equals(notificationKey)))
            .getSingleOrNull();
    return row == null ? null : notificationFromRow(row);
  }

  @override
  Future<CapturedNotification?> findRecentSameContent({
    required String packageName,
    required String contentHash,
    required DateTime around,
    Duration window = const Duration(seconds: 2),
  }) async {
    final from = around.subtract(window).millisecondsSinceEpoch;
    final to = around.add(window).millisecondsSinceEpoch;
    final query = _db.select(_db.notifications)
      ..where(
        (t) =>
            t.packageName.equals(packageName) &
            t.contentHash.equals(contentHash) &
            t.postedAtMs.isBetweenValues(from, to),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.postedAtMs)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : notificationFromRow(row);
  }

  @override
  Future<IngestDecision> ingest(
    CapturedNotification incoming,
    CapturePolicy policy,
  ) {
    return _db.transaction(() async {
      final existing = await findByKey(incoming.key);
      final recent = existing == null
          ? await findRecentSameContent(
              packageName: incoming.packageName,
              contentHash: incoming.contentHash,
              around: incoming.postedAt,
            )
          : null;
      final decision = decideIngest(
        incoming: incoming,
        policy: policy,
        existingByKey: existing,
        recentSameContent: recent,
      );
      switch (decision) {
        case IngestDecision.insert:
          await _db
              .into(_db.notifications)
              .insert(notificationToCompanion(incoming));
        case IngestDecision.update:
          final updated = existing!.applyUpdateFrom(incoming, _clock().toUtc());
          await (_db.update(_db.notifications)
                ..where((t) => t.notificationKey.equals(updated.key)))
              .write(notificationToCompanion(updated));
        case IngestDecision.ignoreDuplicate:
        case IngestDecision.ignoreFiltered:
          break;
      }
      return decision;
    });
  }

  @override
  Future<void> markRemoved(String notificationKey) async {
    await (_db.update(_db.notifications)..where(
          (t) =>
              t.notificationKey.equals(notificationKey) &
              t.status.equalsValue(NotificationStatus.active),
        ))
        .write(
          NotificationsCompanion(
            status: const Value(NotificationStatus.removed),
            lastUpdatedAtMs: Value(_nowMs),
          ),
        );
  }

  @override
  Future<int> markRemovedExcept(Set<String> activeKeys) {
    return (_db.update(_db.notifications)..where(
          (t) =>
              t.status.equalsValue(NotificationStatus.active) &
              t.notificationKey.isNotIn(activeKeys),
        ))
        .write(
          NotificationsCompanion(
            status: const Value(NotificationStatus.removed),
            lastUpdatedAtMs: Value(_nowMs),
          ),
        );
  }

  @override
  Stream<List<CapturedNotification>> watchInbox({bool includeRemoved = true}) {
    final query = _db.select(_db.notifications);
    if (!includeRemoved) {
      query.where((t) => t.status.equalsValue(NotificationStatus.active));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.postedAtMs)]);
    return query.watch().map(
      (rows) => rows.map(notificationFromRow).toList(growable: false),
    );
  }

  @override
  Future<int> purgeOlderThan(DateTime cutoff) {
    return (_db.delete(_db.notifications)..where(
          (t) => t.lastUpdatedAtMs.isSmallerThanValue(
            cutoff.toUtc().millisecondsSinceEpoch,
          ),
        ))
        .go();
  }

  @override
  Future<int> deleteAll() => _db.delete(_db.notifications).go();

  @override
  Future<int> count({bool activeOnly = false}) async {
    final total = _db.notifications.notificationKey.count();
    final query = _db.selectOnly(_db.notifications)..addColumns([total]);
    if (activeOnly) {
      query.where(
        _db.notifications.status.equalsValue(NotificationStatus.active),
      );
    }
    final row = await query.getSingle();
    return row.read(total) ?? 0;
  }

  @override
  Future<List<SourceApp>> listSourceApps() async {
    final packageColumn = _db.notifications.packageName;
    final labelColumn = _db.notifications.appLabel;
    final query = _db.selectOnly(_db.notifications, distinct: true)
      ..addColumns([packageColumn, labelColumn]);
    final rows = await query.get();
    final labels = <String, String?>{};
    for (final row in rows) {
      final packageName = row.read(packageColumn);
      if (packageName == null) continue;
      labels[packageName] = row.read(labelColumn) ?? labels[packageName];
    }
    final apps =
        [
          for (final entry in labels.entries)
            SourceApp(packageName: entry.key, label: entry.value),
        ]..sort(
          (a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ),
        );
    return apps;
  }

  @override
  Future<List<CapturedNotification>> listAll() async {
    final rows = await (_db.select(
      _db.notifications,
    )..orderBy([(t) => OrderingTerm.desc(t.postedAtMs)])).get();
    return rows.map(notificationFromRow).toList(growable: false);
  }

  @override
  Future<bool> deleteByKey(String notificationKey) async {
    final deleted = await (_db.delete(
      _db.notifications,
    )..where((t) => t.notificationKey.equals(notificationKey))).go();
    return deleted > 0;
  }
}
