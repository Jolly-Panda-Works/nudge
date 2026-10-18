import 'reminder_platform.dart';

/// Used on platforms without reminder alerts (for example Windows).
final class NoopReminderPlatform implements ReminderPlatform {
  const NoopReminderPlatform();

  @override
  bool get isSupported => false;

  @override
  Future<ReminderPermissions> permissions() async => const ReminderPermissions(
    notificationsAllowed: false,
    exactAlarmsAllowed: false,
  );

  @override
  Future<bool> requestNotificationPermission() async => false;

  @override
  Future<bool> openNotificationSettings() async => false;

  @override
  Future<bool> openExactAlarmSettings() async => false;

  @override
  Future<void> sync(List<ReminderEntry> entries) async {}

  @override
  Future<List<ReminderSnooze>> drainSnoozes() async => const <ReminderSnooze>[];
}
