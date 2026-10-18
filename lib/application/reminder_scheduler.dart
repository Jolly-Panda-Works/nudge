import 'dart:async';

import '../domain/task_repository.dart';
import '../platform/reminder_platform.dart';

/// Keeps the system alarms in step with the open tasks that have a reminder
/// time, and applies snoozes done from an alert while the app was closed.
///
/// Only future reminder times are scheduled. One that has fired stays on its
/// task (still open) but is not scheduled again.
final class ReminderScheduler {
  ReminderScheduler({
    required ReminderPlatform platform,
    required TaskRepository tasks,
    DateTime Function()? clock,
  }) : _platform = platform,
       _tasks = tasks,
       _clock = clock ?? DateTime.now;

  final ReminderPlatform _platform;
  final TaskRepository _tasks;
  final DateTime Function() _clock;

  StreamSubscription<Object?>? _subscription;
  Future<void> _queue = Future<void>.value();

  bool get isSupported => _platform.isSupported;

  /// Starts following the task list: every change re-syncs the alarms.
  Future<void> start() async {
    if (!_platform.isSupported || _subscription != null) return;
    _subscription = _tasks.watchTasks().listen(
      (_) => unawaited(_syncQuietly()),
      onError: (Object _) {
        // The next change or start tries again.
      },
    );
    await _syncQuietly();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _syncQuietly() => sync().then<void>(
    (_) {},
    onError: (Object _) {
      // Alarms are set again on the next change or start.
    },
  );

  /// Applies pending snoozes, then replaces the system alarms. Calls run one
  /// after another so two syncs never interleave.
  Future<void> sync() {
    final next = _queue.then((_) => _syncNow());
    _queue = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<void> _syncNow() async {
    if (!_platform.isSupported) return;
    await _applySnoozes();
    final now = _clock();
    final pending = await _tasks.listWithPendingReminder();
    final entries = <ReminderEntry>[
      for (final task in pending)
        if (task.remindAt != null && task.remindAt!.isAfter(now))
          ReminderEntry(
            taskId: task.id,
            title: task.title,
            at: task.remindAt!,
          ),
    ];
    await _platform.sync(entries);
  }

  Future<void> _applySnoozes() async {
    final snoozes = await _platform.drainSnoozes();
    for (final snooze in snoozes) {
      try {
        await _tasks.snooze(snooze.taskId, snooze.until);
      } on Exception {
        // A task that no longer exists is skipped.
      }
    }
  }
}
