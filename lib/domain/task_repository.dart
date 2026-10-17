import 'captured_notification.dart';
import 'task.dart';
import 'task_draft.dart';

final class CreateTaskResult {
  const CreateTaskResult(this.task, {required this.created});

  final TaskItem task;

  /// False when the notification already had a task; [task] is that task.
  final bool created;
}

/// Storage of app-owned tasks and reminders.
///
/// State changes that do not make sense for the current status (for example
/// completing an archived task) change nothing and return the unchanged task.
/// Methods that take an unknown id return null.
abstract interface class TaskRepository {
  /// Creates a task that does not come from a notification.
  Future<TaskItem> create(TaskDraft draft);

  /// Creates a task for [notification] unless it already has one that is not
  /// archived (duplicate prevention). [draft] overrides the derived values.
  Future<CreateTaskResult> createFromNotification(
    CapturedNotification notification, {
    TaskDraft? draft,
  });

  Future<TaskItem?> findById(String id);

  /// The task linked to a notification key. Archived tasks are ignored.
  Future<TaskItem?> findBySourceKey(String notificationKey);

  /// Replaces the editable fields. Changing the due time clears a snooze.
  Future<TaskItem?> updateDetails(String id, TaskDraft draft);

  Future<TaskItem?> markDone(String id);

  Future<TaskItem?> reopen(String id);

  Future<TaskItem?> archive(String id);

  /// Moves an archived task back to done or open.
  Future<TaskItem?> restore(String id);

  /// Postpones the reminder of an open task until [until].
  Future<TaskItem?> snooze(String id, DateTime until);

  Future<bool> delete(String id);

  /// Open tasks come first (soonest reminder first, those without one last),
  /// then done tasks, then archived ones.
  Stream<List<TaskItem>> watchTasks({
    Set<TaskStatus> statuses = const <TaskStatus>{TaskStatus.open},
  });

  /// Every task, newest first (used for export).
  Future<List<TaskItem>> listAll();

  /// Open tasks that have a reminder time, soonest first.
  Future<List<TaskItem>> listWithPendingReminder();

  Future<int> count({TaskStatus? status});

  Future<int> deleteAll();
}
