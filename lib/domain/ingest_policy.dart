import 'captured_notification.dart';

enum FilterMode { off, allowlist, blocklist }

enum IngestDecision { insert, update, ignoreDuplicate, ignoreFiltered }

/// User-configurable capture rules.
final class CapturePolicy {
  const CapturePolicy({
    this.mode = FilterMode.off,
    this.packages = const <String>{},
    this.ownPackageName,
    this.captureOngoing = false,
    this.captureGroupSummaries = false,
  });

  final FilterMode mode;
  final Set<String> packages;
  final String? ownPackageName;
  final bool captureOngoing;
  final bool captureGroupSummaries;

  bool allows(CapturedNotification n) {
    if (n.packageName == ownPackageName) return false;
    if (n.isOngoing && !captureOngoing) return false;
    if (n.isGroupSummary && !captureGroupSummaries) return false;
    switch (mode) {
      case FilterMode.off:
        return true;
      case FilterMode.allowlist:
        return packages.contains(n.packageName);
      case FilterMode.blocklist:
        return !packages.contains(n.packageName);
    }
  }
}

/// Decides what to do with an incoming notification.
///
/// [existingByKey]: stored entry with the same notification key, if any.
/// [recentSameContent]: stored entry from the same package with the same
/// content hash (looked up by the repository), used to catch apps that re-post
/// identical content under a new key.
IngestDecision decideIngest({
  required CapturedNotification incoming,
  required CapturePolicy policy,
  CapturedNotification? existingByKey,
  CapturedNotification? recentSameContent,
  Duration repostWindow = const Duration(seconds: 2),
}) {
  if (!policy.allows(incoming)) return IngestDecision.ignoreFiltered;

  final existing = existingByKey;
  if (existing != null) {
    // Never overwrite readable content with a redacted version.
    if (incoming.isRedacted && !existing.isRedacted) {
      return IngestDecision.ignoreDuplicate;
    }
    if (existing.status == NotificationStatus.removed) {
      return IngestDecision.update;
    }
    if (existing.contentHash == incoming.contentHash &&
        existing.isRedacted == incoming.isRedacted) {
      return IngestDecision.ignoreDuplicate;
    }
    return IngestDecision.update;
  }

  final recent = recentSameContent;
  if (recent != null &&
      recent.packageName == incoming.packageName &&
      recent.contentHash == incoming.contentHash &&
      incoming.postedAt.difference(recent.postedAt).abs() <= repostWindow) {
    return IngestDecision.ignoreDuplicate;
  }

  return IngestDecision.insert;
}
