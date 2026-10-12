import 'captured_notification.dart';
import 'ingest_policy.dart';

/// Storage of captured notifications. Implementations must never log
/// notification titles or bodies.
abstract interface class NotificationRepository {
  Future<CapturedNotification?> findByKey(String notificationKey);

  /// Newest stored entry of the same package and content hash whose post time
  /// is within [window] of [around].
  Future<CapturedNotification?> findRecentSameContent({
    required String packageName,
    required String contentHash,
    required DateTime around,
    Duration window,
  });

  /// Applies [decideIngest] and persists the outcome atomically.
  Future<IngestDecision> ingest(
    CapturedNotification incoming,
    CapturePolicy policy,
  );

  /// Marks one active notification as removed (content is kept).
  Future<void> markRemoved(String notificationKey);

  /// Marks every active notification whose key is not in [activeKeys] as
  /// removed. Used to reconcile after the listener (re)connects.
  Future<int> markRemovedExcept(Set<String> activeKeys);

  Stream<List<CapturedNotification>> watchInbox({bool includeRemoved = true});

  /// Deletes entries not updated since [cutoff]. Returns deleted count.
  Future<int> purgeOlderThan(DateTime cutoff);

  Future<int> deleteAll();
}
