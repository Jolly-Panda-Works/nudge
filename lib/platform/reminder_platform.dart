/// One reminder the system has to alert for.
final class ReminderEntry {
  const ReminderEntry({
    required this.taskId,
    required this.title,
    required this.at,
  });

  final String taskId;
  final String title;
  final DateTime at;
}

/// What the user has allowed. Without [notificationsAllowed] an alert cannot
/// be shown; without [exactAlarmsAllowed] it may arrive a few minutes late.
final class ReminderPermissions {
  const ReminderPermissions({
    required this.notificationsAllowed,
    required this.exactAlarmsAllowed,
  });

  final bool notificationsAllowed;
  final bool exactAlarmsAllowed;
}

/// A snooze the user chose on the alert itself while the app was closed.
final class ReminderSnooze {
  const ReminderSnooze({required this.taskId, required this.until});

  final String taskId;
  final DateTime until;
}

/// Bridge to the native alarms and alerts. Implementations: the Android method
/// channel, and a no-op for platforms without reminder alerts.
abstract interface class ReminderPlatform {
  bool get isSupported;

  Future<ReminderPermissions> permissions();

  /// True when alerts are already allowed. Otherwise the system dialog is
  /// shown (Android 13 and later) and false is returned.
  Future<bool> requestNotificationPermission();

  Future<bool> openNotificationSettings();

  Future<bool> openExactAlarmSettings();

  /// Makes the system alarms match [entries] exactly.
  Future<void> sync(List<ReminderEntry> entries);

  /// Snoozes done from an alert since the last call. They are removed.
  Future<List<ReminderSnooze>> drainSnoozes();
}
