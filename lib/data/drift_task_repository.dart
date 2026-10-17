import 'package:drift/drift.dart';

import '../domain/captured_notification.dart';
import '../domain/task.dart';
import '../domain/task_draft.dart';
import '../domain/task_repository.dart';
import 'database/app_database.dart';
import 'task_row_mapper.dart';

final class DriftTaskRepository implements TaskRepository {
  DriftTaskRepository(
    this._db, {
    DateTime Function()? clock,
    String Function()? idGenerator,
  }) : _clock = clock ?? DateTime.now,
       _newId = idGenerator ?? generateTaskId;

  final AppDatabase _db;
  final DateTime Function() _clock;
  final String Function() _newId;

  /// Whole milliseconds, UTC: exactly what the database can store.
  DateTime get _now => DateTime.fromMillisecondsSinceEpoch(
    _clock().millisecondsSinceEpoch,
    isUtc: true,
  );

  Future<TaskItem> _insert(TaskDraft draft, {TaskSource? source}) async {
    final clean = draft.normalized();
    final now = _now;
    final task = TaskItem(
      id: _newId(),
      title: clean.title,
      notes: clean.notes,
      kind: clean.kind,
      status: TaskStatus.open,
      dueAt: clean.dueAt,
      source: source,
      calendarId: clean.calendarId,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.tasks).insert(taskToCompanion(task));
    return task;
  }

  /// Reads the task, lets [build] describe the change (or return null for a
  /// change that does not apply) and writes it, all in one transaction.
  Future<TaskItem?> _change(
    String id,
    TasksCompanion? Function(TaskItem current, DateTime now) build,
  ) {
    return _db.transaction(() async {
      final current = await findById(id);
      if (current == null) return null;
      final companion = build(current, _now);
      if (companion == null) return current;
      await (_db.update(
        _db.tasks,
      )..where((t) => t.id.equals(id))).write(companion);
      return findById(id);
    });
  }

  @override
  Future<TaskItem> create(TaskDraft draft) => _insert(draft);

  @override
  Future<CreateTaskResult> createFromNotification(
    CapturedNotification notification, {
    TaskDraft? draft,
  }) {
    return _db.transaction(() async {
      final existing = await findBySourceKey(notification.key);
      if (existing != null) return CreateTaskResult(existing, created: false);
      final task = await _insert(
        draft ?? TaskDraft.fromNotification(notification),
        source: TaskSource(
          notificationKey: notification.key,
          packageName: notification.packageName,
          appLabel: notification.appLabel,
          hasContentAction: notification.source.hasContentAction,
        ),
      );
      return CreateTaskResult(task, created: true);
    });
  }

  @override
  Future<TaskItem?> findById(String id) async {
    final row = await (_db.select(
      _db.tasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : taskFromRow(row);
  }

  @override
  Future<TaskItem?> findBySourceKey(String notificationKey) async {
    final query = _db.select(_db.tasks)
      ..where(
        (t) =>
            t.sourceKey.equals(notificationKey) &
            t.status.equalsValue(TaskStatus.archived).not(),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAtMs)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : taskFromRow(row);
  }

  @override
  Future<TaskItem?> updateDetails(String id, TaskDraft draft) {
    final clean = draft.normalized();
    return _change(id, (current, now) {
      final dueChanged = clean.dueAt != current.dueAt;
      return TasksCompanion(
        title: Value(clean.title),
        notes: Value(clean.notes),
        kind: Value(clean.kind),
        dueAtMs: Value(clean.dueAt?.millisecondsSinceEpoch),
        calendarId: Value(clean.calendarId),
        // A new due time replaces an old snooze.
        snoozedUntilMs: dueChanged
            ? const Value<int?>(null)
            : const Value<int?>.absent(),
        updatedAtMs: Value(now.millisecondsSinceEpoch),
      );
    });
  }

  @override
  Future<TaskItem?> markDone(String id) {
    return _change(id, (current, now) {
      if (current.status != TaskStatus.open) return null;
      return TasksCompanion(
        status: const Value(TaskStatus.done),
        completedAtMs: Value(now.millisecondsSinceEpoch),
        snoozedUntilMs: const Value<int?>(null),
        updatedAtMs: Value(now.millisecondsSinceEpoch),
      );
    });
  }

  @override
  Future<TaskItem?> reopen(String id) {
    return _change(id, (current, now) {
      if (current.status != TaskStatus.done) return null;
      return TasksCompanion(
        status: const Value(TaskStatus.open),
        completedAtMs: const Value<int?>(null),
        updatedAtMs: Value(now.millisecondsSinceEpoch),
      );
    });
  }

  @override
  Future<TaskItem?> archive(String id) {
    return _change(id, (current, now) {
      if (current.status == TaskStatus.archived) return null;
      return TasksCompanion(
        status: const Value(TaskStatus.archived),
        snoozedUntilMs: const Value<int?>(null),
        updatedAtMs: Value(now.millisecondsSinceEpoch),
      );
    });
  }

  @override
  Future<TaskItem?> restore(String id) {
    return _change(id, (current, now) {
      if (current.status != TaskStatus.archived) return null;
      return TasksCompanion(
        status: Value(
          current.completedAt == null ? TaskStatus.open : TaskStatus.done,
        ),
        updatedAtMs: Value(now.millisecondsSinceEpoch),
      );
    });
  }

  @override
  Future<TaskItem?> snooze(String id, DateTime until) {
    return _change(id, (current, now) {
      if (current.status != TaskStatus.open) return null;
      return TasksCompanion(
        snoozedUntilMs: Value(until.toUtc().millisecondsSinceEpoch),
        updatedAtMs: Value(now.millisecondsSinceEpoch),
      );
    });
  }

  @override
  Future<bool> delete(String id) async {
    final deleted = await (_db.delete(
      _db.tasks,
    )..where((t) => t.id.equals(id))).go();
    return deleted > 0;
  }

  static int _compare(TaskItem a, TaskItem b) {
    final byStatus = a.status.index.compareTo(b.status.index);
    if (byStatus != 0) return byStatus;
    switch (a.status) {
      case TaskStatus.open:
        final first = a.remindAt;
        final second = b.remindAt;
        if (first != null && second != null) {
          final byTime = first.compareTo(second);
          if (byTime != 0) return byTime;
        } else if (first != null) {
          return -1;
        } else if (second != null) {
          return 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      case TaskStatus.done:
        return (b.completedAt ?? b.updatedAt).compareTo(
          a.completedAt ?? a.updatedAt,
        );
      case TaskStatus.archived:
        return b.updatedAt.compareTo(a.updatedAt);
    }
  }

  @override
  Stream<List<TaskItem>> watchTasks({
    Set<TaskStatus> statuses = const <TaskStatus>{TaskStatus.open},
  }) {
    return _db.select(_db.tasks).watch().map((rows) {
      final items =
          rows
              .map(taskFromRow)
              .where((task) => statuses.contains(task.status))
              .toList()
            ..sort(_compare);
      return items;
    });
  }

  @override
  Future<List<TaskItem>> listAll() async {
    final rows = await (_db.select(
      _db.tasks,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAtMs)])).get();
    return rows.map(taskFromRow).toList(growable: false);
  }

  @override
  Future<List<TaskItem>> listWithPendingReminder() async {
    final rows = await _db.select(_db.tasks).get();
    return rows
        .map(taskFromRow)
        .where((t) => t.status == TaskStatus.open && t.remindAt != null)
        .toList()
      ..sort(_compare);
  }

  @override
  Future<int> count({TaskStatus? status}) async {
    final total = _db.tasks.id.count();
    final query = _db.selectOnly(_db.tasks)..addColumns([total]);
    if (status != null) {
      query.where(_db.tasks.status.equalsValue(status));
    }
    final row = await query.getSingle();
    return row.read(total) ?? 0;
  }

  @override
  Future<int> deleteAll() => _db.delete(_db.tasks).go();
}
