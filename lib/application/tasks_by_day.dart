import '../domain/task.dart';

/// The local day (midnight) that [time] falls on.
DateTime localDay(DateTime time) {
  final local = time.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Groups tasks by the local day of their reminder time (a snooze moves a
/// task to the day it was snoozed to). Tasks without a time, and archived
/// tasks, are left out. Inside a day tasks are ordered by time, then title.
Map<DateTime, List<TaskItem>> groupTasksByDay(Iterable<TaskItem> tasks) {
  final days = <DateTime, List<TaskItem>>{};
  for (final task in tasks) {
    final at = task.remindAt;
    if (at == null || task.status == TaskStatus.archived) continue;
    days.putIfAbsent(localDay(at), () => <TaskItem>[]).add(task);
  }
  for (final list in days.values) {
    list.sort((a, b) {
      final byTime = a.remindAt!.compareTo(b.remindAt!);
      return byTime != 0 ? byTime : a.title.compareTo(b.title);
    });
  }
  return days;
}
