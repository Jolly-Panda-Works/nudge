import 'dart:async';

import 'package:nudge/domain/captured_notification.dart';
import 'package:nudge/domain/task.dart';
import 'package:nudge/domain/task_draft.dart';
import 'package:nudge/domain/task_repository.dart';

/// Simple in-memory task repository for widget tests (no database, no timers).
class InMemoryTaskRepository implements TaskRepository {
  final Map<String, TaskItem> _items = <String, TaskItem>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _next = 0;

  void _notify() => _changes.add(null);

  TaskItem _store(TaskItem task) {
    _items[task.id] = task;
    _notify();
    return task;
  }

  TaskItem _rebuild(
    TaskItem t, {
    String? title,
    String? notes,
    TaskKind? kind,
    TaskStatus? status,
    DateTime? dueAt,
    DateTime? snoozedUntil,
    DateTime? completedAt,
    bool clearSnooze = false,
    bool clearCompleted = false,
    bool replaceFields = false,
  }) {
    return TaskItem(
      id: t.id,
      title: title ?? t.title,
      notes: replaceFields ? notes : (notes ?? t.notes),
      kind: kind ?? t.kind,
      status: status ?? t.status,
      dueAt: replaceFields ? dueAt : (dueAt ?? t.dueAt),
      snoozedUntil: clearSnooze ? null : (snoozedUntil ?? t.snoozedUntil),
      source: t.source,
      calendarId: t.calendarId,
      createdAt: t.createdAt,
      updatedAt: DateTime.now().toUtc(),
      completedAt: clearCompleted ? null : (completedAt ?? t.completedAt),
    );
  }

  TaskItem _insert(TaskDraft draft, {TaskSource? source}) {
    final clean = draft.normalized();
    final now = DateTime.now().toUtc();
    return _store(
      TaskItem(
        id: 't_${_next++}',
        title: clean.title,
        notes: clean.notes,
        kind: clean.kind,
        status: TaskStatus.open,
        dueAt: clean.dueAt,
        source: source,
        calendarId: clean.calendarId,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<TaskItem> create(TaskDraft draft) async => _insert(draft);

  @override
  Future<CreateTaskResult> createFromNotification(
    CapturedNotification notification, {
    TaskDraft? draft,
  }) async {
    final existing = await findBySourceKey(notification.key);
    if (existing != null) return CreateTaskResult(existing, created: false);
    final task = _insert(
      draft ?? TaskDraft.fromNotification(notification),
      source: TaskSource(
        notificationKey: notification.key,
        packageName: notification.packageName,
        appLabel: notification.appLabel,
        hasContentAction: notification.source.hasContentAction,
      ),
    );
    return CreateTaskResult(task, created: true);
  }

  @override
  Future<TaskItem?> findById(String id) async => _items[id];

  @override
  Future<TaskItem?> findBySourceKey(String notificationKey) async {
    for (final t in _items.values) {
      if (t.status != TaskStatus.archived &&
          t.source?.notificationKey == notificationKey) {
        return t;
      }
    }
    return null;
  }

  @override
  Future<TaskItem?> updateDetails(String id, TaskDraft draft) async {
    final t = _items[id];
    if (t == null) return null;
    final clean = draft.normalized();
    final dueChanged = clean.dueAt != t.dueAt;
    return _store(
      _rebuild(
        t,
        title: clean.title,
        notes: clean.notes,
        kind: clean.kind,
        dueAt: clean.dueAt,
        replaceFields: true,
        clearSnooze: dueChanged,
      ),
    );
  }

  @override
  Future<TaskItem?> markDone(String id) async {
    final t = _items[id];
    if (t == null || t.status != TaskStatus.open) return t;
    return _store(
      _rebuild(
        t,
        status: TaskStatus.done,
        completedAt: DateTime.now().toUtc(),
        clearSnooze: true,
      ),
    );
  }

  @override
  Future<TaskItem?> reopen(String id) async {
    final t = _items[id];
    if (t == null || t.status != TaskStatus.done) return t;
    return _store(
      _rebuild(t, status: TaskStatus.open, clearCompleted: true),
    );
  }

  @override
  Future<TaskItem?> archive(String id) async {
    final t = _items[id];
    if (t == null || t.status == TaskStatus.archived) return t;
    return _store(_rebuild(t, status: TaskStatus.archived));
  }

  @override
  Future<TaskItem?> restore(String id) async {
    final t = _items[id];
    if (t == null || t.status != TaskStatus.archived) return t;
    return _store(
      _rebuild(
        t,
        status: t.completedAt != null ? TaskStatus.done : TaskStatus.open,
      ),
    );
  }

  @override
  Future<TaskItem?> snooze(String id, DateTime until) async {
    final t = _items[id];
    if (t == null || t.status != TaskStatus.open) return t;
    return _store(_rebuild(t, snoozedUntil: until.toUtc()));
  }

  @override
  Future<bool> delete(String id) async {
    final removed = _items.remove(id) != null;
    if (removed) _notify();
    return removed;
  }

  List<TaskItem> _sorted(Set<TaskStatus> statuses) {
    final list = _items.values
        .where((t) => statuses.contains(t.status))
        .toList();
    list.sort((a, b) {
      final byStatus = a.status.index.compareTo(b.status.index);
      if (byStatus != 0) return byStatus;
      final ar = a.remindAt;
      final br = b.remindAt;
      if (ar != null && br != null) {
        final c = ar.compareTo(br);
        if (c != 0) return c;
      } else if (ar != null) {
        return -1;
      } else if (br != null) {
        return 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  @override
  Stream<List<TaskItem>> watchTasks({
    Set<TaskStatus> statuses = const <TaskStatus>{TaskStatus.open},
  }) {
    // A plain controller (not an async* generator): cancelling the
    // subscription completes at once instead of waiting for the next change.
    late final StreamController<List<TaskItem>> controller;
    StreamSubscription<void>? changes;
    controller = StreamController<List<TaskItem>>(
      onListen: () {
        controller.add(_sorted(statuses));
        changes = _changes.stream.listen(
          (_) => controller.add(_sorted(statuses)),
        );
      },
      onCancel: () => changes?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<List<TaskItem>> listAll() async {
    final list = _items.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<TaskItem>> listWithPendingReminder() async => _sorted(
    <TaskStatus>{TaskStatus.open},
  ).where((t) => t.remindAt != null).toList();

  @override
  Future<int> count({TaskStatus? status}) async => status == null
      ? _items.length
      : _items.values.where((t) => t.status == status).length;

  @override
  Future<int> deleteAll() async {
    final n = _items.length;
    _items.clear();
    _notify();
    return n;
  }
}
