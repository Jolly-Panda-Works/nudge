import 'dart:async';

import 'package:nudge/domain/capture_settings_repository.dart';
import 'package:nudge/domain/captured_notification.dart';
import 'package:nudge/domain/ingest_policy.dart';
import 'package:nudge/domain/notification_repository.dart';
import 'package:nudge/domain/source_app.dart';

import 'fixtures.dart';

/// Simple in-memory repository for widget tests (no database, no timers).
class InMemoryNotificationRepository implements NotificationRepository {
  final List<CapturedNotification> _items = <CapturedNotification>[];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  void add(CapturedNotification notification) {
    _items.add(notification);
    _changes.add(null);
  }

  List<CapturedNotification> _snapshot(bool includeRemoved) {
    final items =
        _items
            .where(
              (n) => includeRemoved || n.status == NotificationStatus.active,
            )
            .toList()
          ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return items;
  }

  @override
  Future<CapturedNotification?> findByKey(String notificationKey) async {
    for (final item in _items) {
      if (item.key == notificationKey) return item;
    }
    return null;
  }

  @override
  Future<CapturedNotification?> findRecentSameContent({
    required String packageName,
    required String contentHash,
    required DateTime around,
    Duration window = const Duration(seconds: 2),
  }) async => null;

  @override
  Future<IngestDecision> ingest(
    CapturedNotification incoming,
    CapturePolicy policy,
  ) async {
    if (await findByKey(incoming.key) != null) {
      return IngestDecision.ignoreDuplicate;
    }
    add(incoming);
    return IngestDecision.insert;
  }

  @override
  Future<void> markRemoved(String notificationKey) async {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].key == notificationKey) {
        _items[i] = _items[i].markRemoved(fixedNow);
      }
    }
    _changes.add(null);
  }

  @override
  Future<int> markRemovedExcept(Set<String> activeKeys) async {
    var changed = 0;
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.status == NotificationStatus.active &&
          !activeKeys.contains(item.key)) {
        _items[i] = item.markRemoved(fixedNow);
        changed++;
      }
    }
    _changes.add(null);
    return changed;
  }

  @override
  Stream<List<CapturedNotification>> watchInbox({
    bool includeRemoved = true,
  }) async* {
    yield _snapshot(includeRemoved);
    await for (final _ in _changes.stream) {
      yield _snapshot(includeRemoved);
    }
  }

  @override
  Future<int> purgeOlderThan(DateTime cutoff) async => 0;

  @override
  Future<int> deleteAll() async {
    final count = _items.length;
    _items.clear();
    _changes.add(null);
    return count;
  }

  @override
  Future<int> count({bool activeOnly = false}) async =>
      _snapshot(!activeOnly).length;

  @override
  Future<List<CapturedNotification>> listAll() async => _snapshot(true);

  @override
  Future<bool> deleteByKey(String notificationKey) async {
    final before = _items.length;
    _items.removeWhere((n) => n.key == notificationKey);
    _changes.add(null);
    return _items.length < before;
  }

  @override
  Future<List<SourceApp>> listSourceApps() async {
    final labels = <String, String?>{};
    for (final item in _items) {
      labels[item.packageName] = item.appLabel ?? labels[item.packageName];
    }
    return [
      for (final entry in labels.entries)
        SourceApp(packageName: entry.key, label: entry.value),
    ];
  }
}

class InMemorySettingsRepository implements CaptureSettingsRepository {
  FilterMode mode = FilterMode.off;
  final Map<String, String?> rules = <String, String?>{};
  bool captureOngoing = false;
  bool captureGroupSummaries = false;
  int? retentionDays;

  @override
  Future<CapturePolicy> loadPolicy({String? ownPackageName}) async {
    return CapturePolicy(
      mode: mode,
      packages: Set<String>.of(rules.keys),
      ownPackageName: ownPackageName,
      captureOngoing: captureOngoing,
      captureGroupSummaries: captureGroupSummaries,
    );
  }

  @override
  Future<void> setMode(FilterMode newMode) async => mode = newMode;

  @override
  Future<void> addRule(String packageName, {String? appLabel}) async =>
      rules[packageName] = appLabel;

  @override
  Future<void> removeRule(String packageName) async =>
      rules.remove(packageName);

  @override
  Future<List<SourceApp>> listRules() async => [
    for (final entry in rules.entries)
      SourceApp(packageName: entry.key, label: entry.value),
  ];

  @override
  Future<void> setCaptureOngoing({required bool value}) async =>
      captureOngoing = value;

  @override
  Future<void> setCaptureGroupSummaries({required bool value}) async =>
      captureGroupSummaries = value;

  @override
  Future<int?> getRetentionDays() async => retentionDays;

  @override
  Future<void> setRetentionDays(int? days) async => retentionDays = days;
}
