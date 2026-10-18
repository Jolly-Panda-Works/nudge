import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/application/reminder_scheduler.dart';
import 'package:nudge/domain/task.dart';
import 'package:nudge/domain/task_draft.dart';
import 'package:nudge/platform/reminder_platform.dart';

import '../support/fake_reminder_platform.dart';
import '../support/in_memory_task_repository.dart';

void main() {
  final now = DateTime.utc(2026, 10, 18, 8);
  late FakeReminderPlatform platform;
  late InMemoryTaskRepository tasks;
  late ReminderScheduler scheduler;

  setUp(() {
    platform = FakeReminderPlatform();
    tasks = InMemoryTaskRepository();
    scheduler = ReminderScheduler(
      platform: platform,
      tasks: tasks,
      clock: () => now,
    );
  });

  tearDown(() => scheduler.dispose());

  test('schedules open tasks with a future reminder time', () async {
    final future = await tasks.create(
      TaskDraft(
        title: 'Call Sara',
        kind: TaskKind.reminder,
        dueAt: now.add(const Duration(hours: 2)),
      ),
    );
    await tasks.create(const TaskDraft(title: 'No time'));

    await scheduler.sync();

    expect(platform.lastSync, hasLength(1));
    expect(platform.lastSync.single.taskId, future.id);
    expect(platform.lastSync.single.title, 'Call Sara');
    expect(platform.lastSync.single.at, future.dueAt);
  });

  test('a time in the past is not scheduled', () async {
    await tasks.create(
      TaskDraft(title: 'Old', dueAt: now.subtract(const Duration(hours: 1))),
    );

    await scheduler.sync();

    expect(platform.lastSync, isEmpty);
  });

  test('done tasks drop out of the schedule', () async {
    final task = await tasks.create(
      TaskDraft(title: 'A', dueAt: now.add(const Duration(hours: 1))),
    );
    await scheduler.sync();
    expect(platform.lastSync, hasLength(1));

    await tasks.markDone(task.id);
    await scheduler.sync();

    expect(platform.lastSync, isEmpty);
  });

  test('a snooze done from the alert is applied before syncing', () async {
    final task = await tasks.create(
      TaskDraft(title: 'A', dueAt: now.subtract(const Duration(minutes: 5))),
    );
    final until = now.add(const Duration(minutes: 10));
    platform.pendingSnoozes.add(ReminderSnooze(taskId: task.id, until: until));

    await scheduler.sync();

    expect((await tasks.findById(task.id))?.snoozedUntil, until);
    expect(platform.lastSync.single.at, until);
    expect(platform.pendingSnoozes, isEmpty);
  });

  test('a snooze for a deleted task is ignored', () async {
    platform.pendingSnoozes.add(
      ReminderSnooze(taskId: 'gone', until: now.add(const Duration(hours: 1))),
    );

    await scheduler.sync();

    expect(platform.lastSync, isEmpty);
  });

  test('start follows later changes to the task list', () async {
    await scheduler.start();
    expect(platform.syncs, isNotEmpty);

    await tasks.create(
      TaskDraft(title: 'B', dueAt: now.add(const Duration(hours: 3))),
    );
    await Future<void>.delayed(Duration.zero);
    await scheduler.sync();

    expect(platform.lastSync, hasLength(1));
  });

  test('does nothing on a platform without alerts', () async {
    platform.supported = false;
    await tasks.create(
      TaskDraft(title: 'A', dueAt: now.add(const Duration(hours: 1))),
    );

    await scheduler.start();
    await scheduler.sync();

    expect(platform.syncs, isEmpty);
  });
}
