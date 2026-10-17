import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/domain/task.dart';
import 'package:nudge/domain/task_draft.dart';

import '../support/fixtures.dart';

void main() {
  group('TaskDraft.fromNotification', () {
    test('uses the notification title and keeps the text as notes', () {
      final draft = TaskDraft.fromNotification(
        captured(title: 'Sara', text: 'Dinner at 8?'),
      );
      expect(draft.title, 'Sara');
      expect(draft.notes, 'Dinner at 8?');
      expect(draft.kind, TaskKind.task);
      expect(draft.dueAt, isNull);
    });

    test('without a title the first non-empty line becomes the title', () {
      final draft = TaskDraft.fromNotification(
        captured(title: null, text: '\n  Buy milk\nand eggs'),
      );
      expect(draft.title, 'Buy milk');
      expect(draft.notes, 'Buy milk\nand eggs');
    });

    test('a single-line text used as title is not repeated in the notes', () {
      final draft = TaskDraft.fromNotification(
        captured(title: null, text: 'Buy milk'),
      );
      expect(draft.title, 'Buy milk');
      expect(draft.notes, isNull);
    });

    test('long titles are shortened', () {
      final draft = TaskDraft.fromNotification(
        captured(title: 'x' * 300, text: null),
      );
      expect(draft.title.length, TaskDraft.derivedTitleLength);
      expect(draft.title.endsWith('…'), isTrue);
    });

    test('a notification without content gets a title from its app', () {
      final draft = TaskDraft.fromNotification(
        captured(title: null, text: null),
      );
      expect(draft.title, 'Notification from Chat');
      expect(draft.notes, isNull);
    });

    test('kind and due time can be chosen', () {
      final due = DateTime.utc(2026, 10, 20, 9);
      final draft = TaskDraft.fromNotification(
        captured(),
        kind: TaskKind.reminder,
        dueAt: due,
      );
      expect(draft.kind, TaskKind.reminder);
      expect(draft.dueAt, due);
    });
  });

  group('TaskDraft.normalized', () {
    test('trims values and turns empty optional fields into null', () {
      final clean = TaskDraft(
        title: '  Call Sara  ',
        notes: '   ',
        calendarId: ' ',
        dueAt: DateTime(2026, 10, 20, 9),
      ).normalized();
      expect(clean.title, 'Call Sara');
      expect(clean.notes, isNull);
      expect(clean.calendarId, isNull);
      expect(clean.dueAt!.isUtc, isTrue);
    });

    test('a blank title is rejected', () {
      expect(
        () => const TaskDraft(title: '   ').normalized(),
        throwsArgumentError,
      );
    });

    test('very long titles are cut to the maximum', () {
      final clean = TaskDraft(title: 'y' * 500).normalized();
      expect(clean.title.length, TaskDraft.maxTitleLength);
    });
  });

  group('TaskItem', () {
    final created = DateTime.utc(2026, 10, 12);

    TaskItem item({DateTime? due, DateTime? snoozed}) => TaskItem(
      id: 't1',
      title: 'x',
      kind: TaskKind.reminder,
      status: TaskStatus.open,
      dueAt: due,
      snoozedUntil: snoozed,
      createdAt: created,
      updatedAt: created,
    );

    test('remindAt prefers the snooze time over the due time', () {
      final due = DateTime.utc(2026, 10, 13, 9);
      final snoozed = DateTime.utc(2026, 10, 13, 10);
      expect(item(due: due).remindAt, due);
      expect(item(due: due, snoozed: snoozed).remindAt, snoozed);
      expect(item().remindAt, isNull);
    });
  });

  test('generated task ids have a stable shape and do not repeat', () {
    final ids = <String>{for (var i = 0; i < 500; i++) generateTaskId()};
    expect(ids, hasLength(500));
    expect(ids.every((id) => RegExp(r'^t_[0-9a-f]{16}$').hasMatch(id)), isTrue);
  });
}
