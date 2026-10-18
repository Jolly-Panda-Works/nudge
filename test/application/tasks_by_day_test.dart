import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/application/tasks_by_day.dart';
import 'package:nudge/domain/task.dart';

TaskItem task(
  String title, {
  DateTime? dueAt,
  DateTime? snoozedUntil,
  TaskStatus status = TaskStatus.open,
}) {
  final now = DateTime.utc(2026, 10, 1);
  return TaskItem(
    id: title,
    title: title,
    kind: TaskKind.task,
    status: status,
    createdAt: now,
    updatedAt: now,
    dueAt: dueAt,
    snoozedUntil: snoozedUntil,
  );
}

void main() {
  test('groups by the local day of the reminder time', () {
    final days = groupTasksByDay(<TaskItem>[
      task('a', dueAt: DateTime(2026, 10, 18, 9)),
      task('b', dueAt: DateTime(2026, 10, 18, 7)),
      task('c', dueAt: DateTime(2026, 10, 19, 23, 59)),
    ]);

    expect(days.keys, <DateTime>[DateTime(2026, 10, 18), DateTime(2026, 10, 19)]);
    expect(days[DateTime(2026, 10, 18)]!.map((t) => t.title), <String>['b', 'a']);
    expect(days[DateTime(2026, 10, 19)]!.single.title, 'c');
  });

  test('a snooze moves the task to the snoozed day', () {
    final days = groupTasksByDay(<TaskItem>[
      task(
        'a',
        dueAt: DateTime(2026, 10, 18, 9),
        snoozedUntil: DateTime(2026, 10, 20, 9),
      ),
    ]);

    expect(days.containsKey(DateTime(2026, 10, 18)), isFalse);
    expect(days[DateTime(2026, 10, 20)]!.single.title, 'a');
  });

  test('tasks without a time and archived tasks are left out', () {
    final days = groupTasksByDay(<TaskItem>[
      task('no time'),
      task('archived', dueAt: DateTime(2026, 10, 18, 9), status: TaskStatus.archived),
      task('done', dueAt: DateTime(2026, 10, 18, 9), status: TaskStatus.done),
    ]);

    expect(days[DateTime(2026, 10, 18)]!.map((t) => t.title), <String>['done']);
  });

  test('equal times are ordered by title', () {
    final at = DateTime(2026, 10, 18, 9);
    final days = groupTasksByDay(<TaskItem>[
      task('b', dueAt: at),
      task('a', dueAt: at),
    ]);

    expect(days[DateTime(2026, 10, 18)]!.map((t) => t.title), <String>['a', 'b']);
  });

  test('localDay drops the time', () {
    expect(localDay(DateTime(2026, 10, 18, 23, 59)), DateTime(2026, 10, 18));
  });
}
