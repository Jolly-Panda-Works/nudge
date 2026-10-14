import '../domain/capture_settings_repository.dart';
import '../domain/notification_repository.dart';

/// Deletes notifications that were not updated for the configured number of
/// days. Applied at startup and whenever the setting changes.
final class RetentionService {
  RetentionService({
    required NotificationRepository notifications,
    required CaptureSettingsRepository settings,
    DateTime Function()? clock,
  }) : _notifications = notifications,
       _settings = settings,
       _clock = clock ?? DateTime.now;

  final NotificationRepository _notifications;
  final CaptureSettingsRepository _settings;
  final DateTime Function() _clock;

  /// Returns how many notifications were deleted.
  Future<int> apply() async {
    final days = await _settings.getRetentionDays();
    if (days == null || days <= 0) return 0;
    final cutoff = _clock().toUtc().subtract(Duration(days: days));
    return _notifications.purgeOlderThan(cutoff);
  }
}
