import 'dart:math';

/// A plain task, or a reminder that is meant to alert at a given time.
enum TaskKind { task, reminder }

enum TaskStatus { open, done, archived }

/// Where a task came from. A snapshot is kept so the task still knows its
/// source after the notification was deleted or purged. A PendingIntent is
/// never stored: only the fact that an action existed.
final class TaskSource {
  const TaskSource({
    required this.notificationKey,
    required this.packageName,
    required this.hasContentAction,
    this.appLabel,
  });

  final String notificationKey;
  final String packageName;
  final String? appLabel;
  final bool hasContentAction;
}

/// An app-owned task. It never depends on an external calendar event; the
/// optional [calendarId] only names the calendar the user wants it shown in.
final class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.kind,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.dueAt,
    this.snoozedUntil,
    this.source,
    this.calendarId,
    this.completedAt,
  });

  final String id;
  final String title;
  final String? notes;
  final TaskKind kind;
  final TaskStatus status;
  final DateTime? dueAt;
  final DateTime? snoozedUntil;
  final TaskSource? source;
  final String? calendarId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  /// When the task should alert next: the snooze time if it was snoozed,
  /// otherwise the due time.
  DateTime? get remindAt => snoozedUntil ?? dueAt;
}

final Random _random = Random.secure();

/// Random id such as `t_9f3a07c21b44de50`.
String generateTaskId() {
  String part() => _random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
  return 't_${part()}${part()}';
}
