import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/domain/captured_notification.dart';
import 'package:nudge/domain/ingest_policy.dart';
import 'package:nudge/domain/notification_repository.dart';
import 'package:nudge/domain/task_repository.dart';

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

/// Task repository stub for widget tests of screens that do not use tasks yet.
class StubTaskRepository extends Fake implements TaskRepository {}
