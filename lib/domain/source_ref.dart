/// Persistent reference to where a notification came from.
///
/// A PendingIntent is NOT durable or serializable, so it is never stored here.
/// [hasContentAction] only records that one existed at capture time; whether it
/// is still usable is decided at open time (fallback order lives in M2).
final class SourceRef {
  const SourceRef({
    required this.packageName,
    required this.notificationKey,
    required this.hasContentAction,
    this.actionTitles = const <String>[],
  });

  final String packageName;
  final String notificationKey;
  final bool hasContentAction;
  final List<String> actionTitles;
}
