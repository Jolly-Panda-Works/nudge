import 'package:drift/drift.dart' show Value;

import '../domain/task.dart';
import 'database/app_database.dart';

DateTime _fromMs(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

DateTime? _fromMsOrNull(int? ms) => ms == null ? null : _fromMs(ms);

int? _toMsOrNull(DateTime? time) => time?.toUtc().millisecondsSinceEpoch;

TaskItem taskFromRow(TaskRow row) {
  final sourceKey = row.sourceKey;
  return TaskItem(
    id: row.id,
    title: row.title,
    notes: row.notes,
    kind: row.kind,
    status: row.status,
    dueAt: _fromMsOrNull(row.dueAtMs),
    snoozedUntil: _fromMsOrNull(row.snoozedUntilMs),
    source: sourceKey == null
        ? null
        : TaskSource(
            notificationKey: sourceKey,
            packageName: row.sourcePackage ?? '',
            appLabel: row.sourceLabel,
            hasContentAction: row.sourceHasContentAction,
          ),
    calendarId: row.calendarId,
    createdAt: _fromMs(row.createdAtMs),
    updatedAt: _fromMs(row.updatedAtMs),
    completedAt: _fromMsOrNull(row.completedAtMs),
  );
}

TasksCompanion taskToCompanion(TaskItem task) {
  final source = task.source;
  return TasksCompanion(
    id: Value(task.id),
    title: Value(task.title),
    notes: Value(task.notes),
    kind: Value(task.kind),
    status: Value(task.status),
    dueAtMs: Value(_toMsOrNull(task.dueAt)),
    snoozedUntilMs: Value(_toMsOrNull(task.snoozedUntil)),
    sourceKey: Value(source?.notificationKey),
    sourcePackage: Value(source?.packageName),
    sourceLabel: Value(source?.appLabel),
    sourceHasContentAction: Value(source?.hasContentAction ?? false),
    calendarId: Value(task.calendarId),
    createdAtMs: Value(_toMsOrNull(task.createdAt)!),
    updatedAtMs: Value(_toMsOrNull(task.updatedAt)!),
    completedAtMs: Value(_toMsOrNull(task.completedAt)),
  );
}
