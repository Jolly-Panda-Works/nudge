import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/data/database/app_database.dart';
import 'package:nudge/data/drift_notification_repository.dart';
import 'package:nudge/data/drift_task_repository.dart';
import 'package:nudge/domain/ingest_policy.dart';
import 'package:nudge/domain/task.dart';
import 'package:nudge/domain/task_draft.dart';

import '../support/fixtures.dart';

void main() {
  late AppDatabase db;
  late DriftTaskRepository tasks;
  late DriftNotificationRepository notifications;
  late DateTime now;
  late int counter;
  const open = CapturePolicy();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    now = fixedNow;
    counter = 0;
    tasks = DriftTaskRepository(
      db,
      clock: () => now,
      idGenerator: () => 't${++counter}',
    );
    notifications = DriftNotificationRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('creating', () {
    test('create stores trimmed values as an open task', () async {
      final task = await tasks.create(
        TaskDraft(
          title: '  Call Sara ',
          notes: ' about dinner ',
          kind: TaskKind.reminder,
          dueAt: DateTime.utc(2026, 10, 20, 9),
          calendarId: 'cal-1',
        ),
      );

      final stored = await tasks.findById(task.id);
      expect(stored, isNotNull);
      expect(stored!.title, 'Call Sara');
      expect(stored.notes, 'about dinner');
      expect(stored.kind, TaskKind.reminder);
      expect(stored.status, TaskStatus.open);
      expect(stored.dueAt, DateTime.utc(2026, 10, 20, 9));
      expect(stored.dueAt!.isUtc, isTrue);
      expect(stored.calendarId, 'cal-1');
      expect(stored.source, isNull);
      expect(stored.createdAt, fixedNow);
      expect(stored.completedAt, isNull);
    });

    test('a blank title is rejected and nothing is stored', () async {
      await expectLater(
        tasks.create(const TaskDraft(title: '  ')),
        throwsArgumentError,
      );
      expect(await tasks.count(), 0);
    });

    test('createFromNotification links the task to its source', () async {
      final n = captured(title: 'Sara', text: 'Hello');
      final result = await tasks.createFromNotification(n);

      expect(result.created, isTrue);
      final task = result.task;
      expect(task.title, 'Sara');
      expect(task.notes, 'Hello');
      expect(task.source!.notificationKey, n.key);
      expect(task.source!.packageName, 'com.chat');
      expect(task.source!.appLabel, 'Chat');
      expect(task.source!.hasContentAction, isTrue);

      final stored = await tasks.findBySourceKey(n.key);
      expect(stored!.id, task.id);
    });

    test('a draft overrides the derived values', () async {
      final result = await tasks.createFromNotification(
        captured(),
        draft: TaskDraft(
          title: 'Reply to Sara',
          kind: TaskKind.reminder,
          dueAt: DateTime.utc(2026, 10, 14, 18),
        ),
      );
      expect(result.task.title, 'Reply to Sara');
      expect(result.task.kind, TaskKind.reminder);
      expect(result.task.source, isNotNull);
    });
  });

  group('duplicate prevention', () {
    test('a second request returns the existing task', () async {
      final n = captured();
      final first = await tasks.createFromNotification(n);
      final second = await tasks.createFromNotification(n);

      expect(second.created, isFalse);
      expect(second.task.id, first.task.id);
      expect(await tasks.count(), 1);
    });

    test('a done task still blocks a duplicate', () async {
      final n = captured();
      final first = await tasks.createFromNotification(n);
      await tasks.markDone(first.task.id);

      final second = await tasks.createFromNotification(n);
      expect(second.created, isFalse);
      expect(second.task.status, TaskStatus.done);
    });

    test('an archived task allows a new one', () async {
      final n = captured();
      final first = await tasks.createFromNotification(n);
      await tasks.archive(first.task.id);

      final second = await tasks.createFromNotification(n);
      expect(second.created, isTrue);
      expect(second.task.id, isNot(first.task.id));
      expect((await tasks.findBySourceKey(n.key))!.id, second.task.id);
    });
  });

  group('status changes', () {
    test('markDone completes an open task and clears the snooze', () async {
      final task = await tasks.create(
        TaskDraft(title: 'x', dueAt: DateTime.utc(2026, 10, 20)),
      );
      await tasks.snooze(task.id, DateTime.utc(2026, 10, 21));
      now = fixedNow.add(const Duration(hours: 1));

      final done = await tasks.markDone(task.id);
      expect(done!.status, TaskStatus.done);
      expect(done.completedAt, now);
      expect(done.snoozedUntil, isNull);
      expect(done.updatedAt, now);
    });

    test('reopen puts a done task back', () async {
      final task = await tasks.create(const TaskDraft(title: 'x'));
      await tasks.markDone(task.id);

      final reopened = await tasks.reopen(task.id);
      expect(reopened!.status, TaskStatus.open);
      expect(reopened.completedAt, isNull);
    });

    test('changes that do not apply leave the task unchanged', () async {
      final task = await tasks.create(const TaskDraft(title: 'x'));

      expect((await tasks.reopen(task.id))!.status, TaskStatus.open);
      expect((await tasks.restore(task.id))!.status, TaskStatus.open);

      await tasks.archive(task.id);
      expect((await tasks.markDone(task.id))!.status, TaskStatus.archived);
      expect((await tasks.archive(task.id))!.status, TaskStatus.archived);
    });

    test('restore returns an archived task to open or done', () async {
      final openTask = await tasks.create(const TaskDraft(title: 'open'));
      final doneTask = await tasks.create(const TaskDraft(title: 'done'));
      await tasks.markDone(doneTask.id);
      await tasks.archive(openTask.id);
      await tasks.archive(doneTask.id);

      expect((await tasks.restore(openTask.id))!.status, TaskStatus.open);
      expect((await tasks.restore(doneTask.id))!.status, TaskStatus.done);
    });

    test('unknown ids return null', () async {
      expect(await tasks.markDone('nope'), isNull);
      expect(await tasks.archive('nope'), isNull);
      expect(await tasks.snooze('nope', fixedNow), isNull);
      expect(await tasks.findById('nope'), isNull);
      expect(await tasks.delete('nope'), isFalse);
    });
  });

  group('snooze and editing', () {
    test('snooze postpones the reminder of an open task', () async {
      final due = DateTime.utc(2026, 10, 20, 9);
      final snoozeUntil = DateTime.utc(2026, 10, 20, 10);
      final task = await tasks.create(
        TaskDraft(title: 'x', kind: TaskKind.reminder, dueAt: due),
      );

      final snoozed = await tasks.snooze(task.id, snoozeUntil);
      expect(snoozed!.snoozedUntil, snoozeUntil);
      expect(snoozed.dueAt, due);
      expect(snoozed.remindAt, snoozeUntil);
    });

    test('a done task cannot be snoozed', () async {
      final task = await tasks.create(const TaskDraft(title: 'x'));
      await tasks.markDone(task.id);

      final result = await tasks.snooze(task.id, DateTime.utc(2026, 10, 25));
      expect(result!.snoozedUntil, isNull);
    });

    test('updateDetails replaces the fields', () async {
      final task = await tasks.create(
        const TaskDraft(title: 'old', notes: 'old notes'),
      );
      now = fixedNow.add(const Duration(minutes: 5));

      final updated = await tasks.updateDetails(
        task.id,
        TaskDraft(
          title: ' new ',
          kind: TaskKind.reminder,
          dueAt: DateTime.utc(2026, 10, 21, 7),
          calendarId: 'cal-2',
        ),
      );
      expect(updated!.title, 'new');
      expect(updated.notes, isNull);
      expect(updated.kind, TaskKind.reminder);
      expect(updated.dueAt, DateTime.utc(2026, 10, 21, 7));
      expect(updated.calendarId, 'cal-2');
      expect(updated.updatedAt, now);
      expect(updated.createdAt, fixedNow);
    });

    test('a new due time clears the snooze, the same one keeps it', () async {
      final due = DateTime.utc(2026, 10, 20, 9);
      final task = await tasks.create(TaskDraft(title: 'x', dueAt: due));
      await tasks.snooze(task.id, DateTime.utc(2026, 10, 20, 12));

      final sameDue = await tasks.updateDetails(
        task.id,
        TaskDraft(title: 'x2', dueAt: due),
      );
      expect(sameDue!.snoozedUntil, DateTime.utc(2026, 10, 20, 12));

      final newDue = await tasks.updateDetails(
        task.id,
        TaskDraft(title: 'x2', dueAt: DateTime.utc(2026, 10, 22, 9)),
      );
      expect(newDue!.snoozedUntil, isNull);
    });
  });

  group('listing', () {
    test('open tasks are ordered by reminder time, then newest', () async {
      final base = DateTime.utc(2026, 10, 20, 9);
      final later = await tasks.create(
        TaskDraft(title: 'late', dueAt: base.add(const Duration(hours: 2))),
      );
      now = fixedNow.add(const Duration(minutes: 1));
      final noDue = await tasks.create(const TaskDraft(title: 'no due'));
      now = fixedNow.add(const Duration(minutes: 2));
      final soon = await tasks.create(
        TaskDraft(title: 'soon', dueAt: base.add(const Duration(hours: 1))),
      );
      now = fixedNow.add(const Duration(minutes: 3));
      final newerNoDue = await tasks.create(const TaskDraft(title: 'newer'));

      final list = await tasks.watchTasks().first;
      expect(list.map((t) => t.id), <String>[
        soon.id,
        later.id,
        newerNoDue.id,
        noDue.id,
      ]);
    });

    test('a snooze moves a task in the order', () async {
      final base = DateTime.utc(2026, 10, 20, 9);
      final a = await tasks.create(TaskDraft(title: 'a', dueAt: base));
      final b = await tasks.create(
        TaskDraft(title: 'b', dueAt: base.add(const Duration(hours: 1))),
      );
      await tasks.snooze(a.id, base.add(const Duration(hours: 5)));

      final list = await tasks.watchTasks().first;
      expect(list.map((t) => t.id), <String>[b.id, a.id]);
    });

    test('statuses can be selected and are grouped open, done, archived', () async {
      final openTask = await tasks.create(const TaskDraft(title: 'open'));
      final doneTask = await tasks.create(const TaskDraft(title: 'done'));
      final archivedTask = await tasks.create(const TaskDraft(title: 'old'));
      await tasks.markDone(doneTask.id);
      await tasks.archive(archivedTask.id);

      expect(
        (await tasks.watchTasks().first).map((t) => t.id),
        <String>[openTask.id],
      );
      expect(
        (await tasks
                .watchTasks(statuses: TaskStatus.values.toSet())
                .first)
            .map((t) => t.id),
        <String>[openTask.id, doneTask.id, archivedTask.id],
      );
    });

    test('listWithPendingReminder only returns open tasks with a time', () async {
      final base = DateTime.utc(2026, 10, 20, 9);
      final withDue = await tasks.create(TaskDraft(title: 'a', dueAt: base));
      await tasks.create(const TaskDraft(title: 'no due'));
      final doneTask = await tasks.create(TaskDraft(title: 'done', dueAt: base));
      await tasks.markDone(doneTask.id);

      final pending = await tasks.listWithPendingReminder();
      expect(pending.map((t) => t.id), <String>[withDue.id]);
    });

    test('count can be limited to one status', () async {
      final a = await tasks.create(const TaskDraft(title: 'a'));
      await tasks.create(const TaskDraft(title: 'b'));
      await tasks.markDone(a.id);

      expect(await tasks.count(), 2);
      expect(await tasks.count(status: TaskStatus.open), 1);
      expect(await tasks.count(status: TaskStatus.done), 1);
      expect(await tasks.count(status: TaskStatus.archived), 0);
    });

    test('listAll returns everything, newest first', () async {
      final first = await tasks.create(const TaskDraft(title: 'first'));
      now = fixedNow.add(const Duration(minutes: 1));
      final second = await tasks.create(const TaskDraft(title: 'second'));

      final all = await tasks.listAll();
      expect(all.map((t) => t.id), <String>[second.id, first.id]);
    });
  });

  group('deleting', () {
    test('delete removes one task', () async {
      final a = await tasks.create(const TaskDraft(title: 'a'));
      await tasks.create(const TaskDraft(title: 'b'));

      expect(await tasks.delete(a.id), isTrue);
      expect(await tasks.count(), 1);
    });

    test('deleteAll removes every task', () async {
      await tasks.create(const TaskDraft(title: 'a'));
      await tasks.create(const TaskDraft(title: 'b'));

      expect(await tasks.deleteAll(), 2);
      expect(await tasks.count(), 0);
    });
  });

  group('tasks and notifications', () {
    test('a task keeps its source after the notification is deleted', () async {
      final n = captured();
      await notifications.ingest(n, open);
      final task = (await tasks.createFromNotification(n)).task;

      await notifications.deleteByKey(n.key);

      final stored = await tasks.findById(task.id);
      expect(stored!.source!.notificationKey, n.key);
      expect(stored.source!.packageName, 'com.chat');
    });

    test('retention does not delete a notification an open task points to', () async {
      final n = captured();
      await notifications.ingest(n, open);
      await tasks.createFromNotification(n);
      final farFuture = fixedNow.add(const Duration(days: 365));

      expect(await notifications.purgeOlderThan(farFuture), 0);
      expect(await notifications.findByKey(n.key), isNotNull);
    });

    test('retention deletes it once the task is archived', () async {
      final n = captured();
      await notifications.ingest(n, open);
      final task = (await tasks.createFromNotification(n)).task;
      await tasks.archive(task.id);
      final farFuture = fixedNow.add(const Duration(days: 365));

      expect(await notifications.purgeOlderThan(farFuture), 1);
      expect(await notifications.findByKey(n.key), isNull);
    });

    test('retention still deletes notifications without tasks', () async {
      final linked = captured(key: 'A', text: 'one');
      final other = captured(key: 'B', text: 'two', time: 1760000100000);
      await notifications.ingest(linked, open);
      await notifications.ingest(other, open);
      await tasks.createFromNotification(linked);

      final farFuture = fixedNow.add(const Duration(days: 365));
      expect(await notifications.purgeOlderThan(farFuture), 1);
      expect(await notifications.findByKey('A'), isNotNull);
      expect(await notifications.findByKey('B'), isNull);
    });
  });
}
