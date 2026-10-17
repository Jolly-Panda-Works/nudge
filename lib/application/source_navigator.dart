import '../platform/capture_platform.dart';

/// What happened when the user asked to open the original of a notification.
enum SourceOpenOutcome {
  /// The live notification action was fired.
  openedOriginal,

  /// The original is gone; the source app's launcher screen was opened.
  openedApp,

  /// Neither worked. The saved content is still shown by the caller.
  unavailable,
}

/// Opens where a notification came from, in a fixed order and without
/// inventing deep links:
///   1. the live notification action (only while the notification is posted),
///   2. the source app's launch intent,
///   3. an explicit "unavailable" result.
final class SourceNavigator {
  const SourceNavigator(this._platform);

  final CapturePlatform _platform;

  Future<SourceOpenOutcome> open({
    required String packageName,
    String? notificationKey,
  }) async {
    if (!_platform.isSupported) return SourceOpenOutcome.unavailable;

    if (notificationKey != null && notificationKey.isNotEmpty) {
      if (await _attempt(() => _platform.openLiveContent(notificationKey))) {
        return SourceOpenOutcome.openedOriginal;
      }
    }
    if (packageName.isNotEmpty &&
        await _attempt(() => _platform.openSourceApp(packageName))) {
      return SourceOpenOutcome.openedApp;
    }
    return SourceOpenOutcome.unavailable;
  }

  /// A platform error counts as "did not work" so the next step still runs.
  Future<bool> _attempt(Future<bool> Function() action) async {
    try {
      return await action();
    } on Object {
      return false;
    }
  }
}
