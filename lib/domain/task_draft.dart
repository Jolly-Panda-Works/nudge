import 'captured_notification.dart';
import 'task.dart';

/// The user-editable fields of a task.
final class TaskDraft {
  const TaskDraft({
    required this.title,
    this.notes,
    this.kind = TaskKind.task,
    this.dueAt,
    this.calendarId,
  });

  /// Starting values for a task made from a notification. The user can edit
  /// everything before saving.
  factory TaskDraft.fromNotification(
    CapturedNotification notification, {
    TaskKind kind = TaskKind.task,
    DateTime? dueAt,
  }) {
    final title = _deriveTitle(notification);
    final text = notification.text;
    return TaskDraft(
      title: title,
      notes: (text != null && text != title) ? text : null,
      kind: kind,
      dueAt: dueAt,
    );
  }

  static const int derivedTitleLength = 120;
  static const int maxTitleLength = 200;

  final String title;
  final String? notes;
  final TaskKind kind;
  final DateTime? dueAt;
  final String? calendarId;

  /// Trimmed, validated copy. Throws [ArgumentError] for a blank title.
  TaskDraft normalized() {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be blank');
    }
    final cleanNotes = notes?.trim();
    final cleanCalendar = calendarId?.trim();
    return TaskDraft(
      title: _truncate(cleanTitle, maxTitleLength),
      notes: (cleanNotes == null || cleanNotes.isEmpty) ? null : cleanNotes,
      kind: kind,
      dueAt: dueAt?.toUtc(),
      calendarId: (cleanCalendar == null || cleanCalendar.isEmpty)
          ? null
          : cleanCalendar,
    );
  }

  static String _deriveTitle(CapturedNotification notification) {
    final title = notification.title?.trim();
    if (title != null && title.isNotEmpty) {
      return _truncate(title, derivedTitleLength);
    }
    final line = _firstLine(notification.text);
    if (line != null) return _truncate(line, derivedTitleLength);
    final name = notification.appLabel ?? notification.packageName;
    return 'Notification from $name';
  }

  static String? _firstLine(String? text) {
    if (text == null) return null;
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  static String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength - 1).trimRight()}…';
  }
}
