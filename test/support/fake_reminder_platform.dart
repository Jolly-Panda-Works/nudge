import 'package:nudge/platform/reminder_platform.dart';

/// In-memory stand-in for the native alarms.
class FakeReminderPlatform implements ReminderPlatform {
  bool supported = true;
  bool notificationsAllowed = true;
  bool exactAlarmsAllowed = true;
  final List<List<ReminderEntry>> syncs = <List<ReminderEntry>>[];
  final List<ReminderSnooze> pendingSnoozes = <ReminderSnooze>[];
  int permissionRequests = 0;
  int notificationSettingsOpens = 0;
  int exactSettingsOpens = 0;

  List<ReminderEntry> get lastSync =>
      syncs.isEmpty ? const <ReminderEntry>[] : syncs.last;

  @override
  bool get isSupported => supported;

  @override
  Future<ReminderPermissions> permissions() async => ReminderPermissions(
    notificationsAllowed: notificationsAllowed,
    exactAlarmsAllowed: exactAlarmsAllowed,
  );

  @override
  Future<bool> requestNotificationPermission() async {
    permissionRequests++;
    return notificationsAllowed;
  }

  @override
  Future<bool> openNotificationSettings() async {
    notificationSettingsOpens++;
    return true;
  }

  @override
  Future<bool> openExactAlarmSettings() async {
    exactSettingsOpens++;
    return true;
  }

  @override
  Future<void> sync(List<ReminderEntry> entries) async {
    syncs.add(List<ReminderEntry>.of(entries));
  }

  @override
  Future<List<ReminderSnooze>> drainSnoozes() async {
    final copy = List<ReminderSnooze>.of(pendingSnoozes);
    pendingSnoozes.clear();
    return copy;
  }
}
