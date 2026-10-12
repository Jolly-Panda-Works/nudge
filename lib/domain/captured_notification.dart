import 'source_ref.dart';

enum NotificationStatus { active, removed }

final class CapturedNotification {
  const CapturedNotification({
    required this.key,
    required this.packageName,
    required this.postedAt,
    required this.contentHash,
    required this.source,
    required this.firstSeenAt,
    required this.lastUpdatedAt,
    this.appLabel,
    this.title,
    this.text,
    this.groupKey,
    this.isGroupSummary = false,
    this.isOngoing = false,
    this.isRedacted = false,
    this.status = NotificationStatus.active,
    this.updateCount = 0,
  });

  final String key;
  final String packageName;
  final String? appLabel;
  final String? title;
  final String? text;
  final DateTime postedAt;
  final String? groupKey;
  final bool isGroupSummary;
  final bool isOngoing;
  final bool isRedacted;

  /// SHA-256 of package + title + text. Excludes timestamps on purpose so a
  /// re-post of identical content is detected as a duplicate.
  final String contentHash;
  final SourceRef source;
  final NotificationStatus status;
  final DateTime firstSeenAt;
  final DateTime lastUpdatedAt;
  final int updateCount;

  /// New version of this notification after the source app updated it.
  /// Keeps identity and [firstSeenAt]; reactivates a removed entry.
  CapturedNotification applyUpdateFrom(
    CapturedNotification incoming,
    DateTime now,
  ) {
    return CapturedNotification(
      key: key,
      packageName: packageName,
      appLabel: incoming.appLabel ?? appLabel,
      title: incoming.title,
      text: incoming.text,
      postedAt: incoming.postedAt,
      groupKey: incoming.groupKey,
      isGroupSummary: incoming.isGroupSummary,
      isOngoing: incoming.isOngoing,
      isRedacted: incoming.isRedacted,
      contentHash: incoming.contentHash,
      source: incoming.source,
      status: NotificationStatus.active,
      firstSeenAt: firstSeenAt,
      lastUpdatedAt: now,
      updateCount: updateCount + 1,
    );
  }

  /// Marks the entry as removed from the status bar. Content is kept.
  CapturedNotification markRemoved(DateTime now) {
    return CapturedNotification(
      key: key,
      packageName: packageName,
      appLabel: appLabel,
      title: title,
      text: text,
      postedAt: postedAt,
      groupKey: groupKey,
      isGroupSummary: isGroupSummary,
      isOngoing: isOngoing,
      isRedacted: isRedacted,
      contentHash: contentHash,
      source: source,
      status: NotificationStatus.removed,
      firstSeenAt: firstSeenAt,
      lastUpdatedAt: now,
      updateCount: updateCount,
    );
  }
}
