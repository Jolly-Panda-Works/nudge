import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/domain/capture_settings_repository.dart';
import 'package:nudge/domain/captured_notification.dart';
import 'package:nudge/domain/ingest_policy.dart';
import 'package:nudge/domain/notification_repository.dart';

/// Repository stub for widget tests: only `count` is implemented.
class StubNotificationRepository extends Fake
    implements NotificationRepository {
  StubNotificationRepository({this.total = 0, this.active = 0});

  final int total;
  final int active;

  @override
  Future<int> count({bool activeOnly = false}) async =>
      activeOnly ? active : total;
}

class StubSettingsRepository extends Fake
    implements CaptureSettingsRepository {}

/// Wraps a real repository and can be told to fail `ingest`.
class FlakyNotificationRepository extends Fake
    implements NotificationRepository {
  FlakyNotificationRepository(this._inner);

  final NotificationRepository _inner;
  bool failIngest = false;

  @override
  Future<IngestDecision> ingest(
    CapturedNotification incoming,
    CapturePolicy policy,
  ) {
    if (failIngest) throw StateError('database unavailable');
    return _inner.ingest(incoming, policy);
  }

  @override
  Future<void> markRemoved(String notificationKey) =>
      _inner.markRemoved(notificationKey);

  @override
  Future<int> markRemovedExcept(Set<String> activeKeys) =>
      _inner.markRemovedExcept(activeKeys);

  @override
  Future<int> count({bool activeOnly = false}) =>
      _inner.count(activeOnly: activeOnly);
}
