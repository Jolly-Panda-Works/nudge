import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/application/calendar_integration.dart';
import 'package:nudge/domain/event_draft.dart';
import 'package:nudge/domain/external_calendar.dart';
import 'package:nudge/domain/task.dart';

import '../support/fake_calendar_platform.dart';
import '../support/in_memory_repositories.dart';

void main() {
  late FakeCalendarPlatform platform;
  late InMemorySettingsRepository settings;
  late CalendarIntegration integration;

  const allowed = CalendarPermissions(read: true, write: true);

  setUp(() {
    platform = FakeCalendarPlatform();
    settings = InMemorySettingsRepository();
    integration = CalendarIntegration(platform: platform, settings: settings);
  });

  test('an unsupported platform reports that and reads nothing', () async {
    platform.supported = false;

    final state = await integration.load();

    expect(state.supported, isFalse);
    expect(await integration.enable(), EnableOutcome.unsupported);
    expect(platform.listCalls, 0);
    expect(platform.permissionRequests, 0);
  });

  test('while off nothing is read and no permission is requested', () async {
    platform.calendars = [calendar('1')];

    final state = await integration.load();

    expect(state.enabled, isFalse);
    expect(state.calendars, isEmpty);
    expect(platform.listCalls, 0);
    expect(platform.permissionRequests, 0);
  });

  test('turning it on asks for the permission, then finishes later', () async {
    platform.allowOnRequest = true;

    final outcome = await integration.enable();

    expect(outcome, EnableOutcome.permissionRequested);
    expect(platform.permissionRequests, 1);
    expect(settings.calendarIntegration, isFalse);

    expect(await integration.completeEnable(), isTrue);
    expect(settings.calendarIntegration, isTrue);
  });

  test('a refused permission leaves the integration off', () async {
    await integration.enable();

    expect(await integration.completeEnable(), isFalse);
    expect(settings.calendarIntegration, isFalse);
  });

  test('with the permission already granted it turns on at once', () async {
    platform.granted = allowed;

    expect(await integration.enable(), EnableOutcome.enabled);
    expect(platform.permissionRequests, 0);
    expect(settings.calendarIntegration, isTrue);
  });

  test('on and allowed: the calendars are read', () async {
    platform.granted = allowed;
    settings.calendarIntegration = true;
    platform.calendars = [
      calendar('1', name: 'Personal'),
      calendar('2', name: 'Holidays', canWrite: false, isOwner: false),
    ];

    final state = await integration.load();

    expect(state.calendars.map((c) => c.id), <String>['1', '2']);
    expect(state.permissionLost, isFalse);
    expect(state.writable.map((c) => c.id), <String>['1']);
  });

  test('without a choice the calendars the device shows are visible', () async {
    platform.granted = allowed;
    settings.calendarIntegration = true;
    platform.calendars = [
      calendar('1', visible: true),
      calendar('2', visible: false),
    ];

    final state = await integration.load();

    expect(state.visibleIds, <String>{'1'});
  });

  test('a stored choice wins and forgets calendars that are gone', () async {
    platform.granted = allowed;
    settings.calendarIntegration = true;
    settings.visibleCalendarIds = <String>{'2', '99'};
    platform.calendars = [
      calendar('1', visible: true),
      calendar('2', visible: false),
    ];

    final state = await integration.load();

    expect(state.visibleIds, <String>{'2'});
  });

  test('the default is the stored writable calendar', () async {
    platform.granted = allowed;
    settings.calendarIntegration = true;
    settings.defaultCalendarId = '2';
    platform.calendars = [
      calendar('1'),
      calendar('2', name: 'Work'),
    ];

    expect((await integration.load()).defaultId, '2');
  });

  test('without a usable stored default, the first own writable one', () async {
    platform.granted = allowed;
    settings.calendarIntegration = true;
    settings.defaultCalendarId = 'gone';
    platform.calendars = [
      calendar('1', canWrite: false, isOwner: false),
      calendar('2', isOwner: false),
      calendar('3'),
    ];

    expect((await integration.load()).defaultId, '3');
  });

  test('a read-only calendar is never the default', () async {
    platform.granted = allowed;
    settings.calendarIntegration = true;
    settings.defaultCalendarId = '1';
    platform.calendars = [calendar('1', canWrite: false)];

    expect((await integration.load()).defaultId, isNull);
  });

  test('setDefault refuses a read-only calendar', () async {
    final state = await integration.load();

    expect(
      () => integration.setDefault(state, calendar('1', canWrite: false)),
      throwsArgumentError,
    );
  });

  test('setVisible stores the whole choice', () async {
    platform.granted = allowed;
    settings.calendarIntegration = true;
    platform.calendars = [
      calendar('1', visible: true),
      calendar('2', visible: true),
    ];
    final state = await integration.load();

    await integration.setVisible(state, state.calendars[0], visible: false);

    expect(settings.visibleCalendarIds, <String>{'2'});
    expect((await integration.load()).visibleIds, <String>{'2'});
  });

  test('a revoked permission is reported and nothing is read', () async {
    settings.calendarIntegration = true;
    platform.calendars = [calendar('1')];

    final state = await integration.load();

    expect(state.permissionLost, isTrue);
    expect(state.calendars, isEmpty);
    expect(platform.listCalls, 0);
  });

  test('a provider failure is reported, not thrown', () async {
    platform.granted = allowed;
    settings.calendarIntegration = true;
    platform.listFails = true;

    final state = await integration.load();

    expect(state.readFailed, isTrue);
    expect(state.calendars, isEmpty);
  });

  test('turning it off keeps the choices', () async {
    platform.granted = allowed;
    settings.calendarIntegration = true;
    settings.visibleCalendarIds = <String>{'1'};

    await integration.disable();

    expect(settings.calendarIntegration, isFalse);
    expect(settings.visibleCalendarIds, <String>{'1'});
  });

  test('account kinds are named', () {
    expect(calendar('1', type: 'com.google').accountKind, 'Google');
    expect(
      calendar('1', type: 'com.samsung.android.calendar').accountKind,
      'Samsung',
    );
    expect(calendar('1', type: 'LOCAL').accountKind, 'Device');
    expect(calendar('1', type: 'com.example').accountKind, 'com.example');
    expect(calendar('1', name: '').label, 'me@example.com');
  });

  group('events', () {
    final from = DateTime(2026, 10, 18);
    final to = DateTime(2026, 10, 25);

    void allow() {
      platform.granted = allowed;
      settings.calendarIntegration = true;
    }

    test('nothing is read while the integration is off', () async {
      platform.calendars = [calendar('1')];
      platform.events = [event('e', start: DateTime(2026, 10, 18, 9))];

      expect(await integration.events(from: from, to: to), isEmpty);
      expect(platform.eventQueries, isEmpty);
    });

    test('nothing is read without the permission', () async {
      settings.calendarIntegration = true;
      platform.calendars = [calendar('1')];

      expect(await integration.events(from: from, to: to), isEmpty);
      expect(platform.eventQueries, isEmpty);
    });

    test('only the shown calendars are queried, with their names', () async {
      allow();
      platform.calendars = [
        calendar('1', name: 'Personal', visible: true),
        calendar('2', name: 'Birthdays', visible: false),
      ];
      platform.events = [
        event('e1', calendarId: '1', start: DateTime(2026, 10, 18, 9)),
        event('e2', calendarId: '2', start: DateTime(2026, 10, 18, 10)),
      ];

      final found = await integration.events(from: from, to: to);

      expect(platform.eventQueries.single, <String>{'1'});
      expect(found.map((e) => e.eventId), <String>['e1']);
      expect(found.single.calendarLabel, 'Personal');
    });

    test('the stored choice decides which calendars are queried', () async {
      allow();
      settings.visibleCalendarIds = <String>{'2'};
      platform.calendars = [calendar('1'), calendar('2', name: 'Work')];
      platform.events = [
        event('e1', calendarId: '1', start: DateTime(2026, 10, 18, 9)),
        event('e2', calendarId: '2', start: DateTime(2026, 10, 18, 10)),
      ];

      final found = await integration.events(from: from, to: to);

      expect(found.map((e) => e.eventId), <String>['e2']);
    });

    test('hiding every calendar reads no events', () async {
      allow();
      settings.visibleCalendarIds = <String>{};
      platform.calendars = [calendar('1')];

      expect(await integration.events(from: from, to: to), isEmpty);
      expect(platform.eventQueries, isEmpty);
    });

    test('an event just outside the range is still found (padding)', () async {
      allow();
      platform.calendars = [calendar('1')];
      // An all-day event stored as UTC may start a few hours before `from`.
      platform.events = [
        event(
          'edge',
          start: DateTime(2026, 10, 17, 20),
          end: DateTime(2026, 10, 18, 2),
        ),
      ];

      final found = await integration.events(from: from, to: to);

      expect(found.map((e) => e.eventId), <String>['edge']);
    });

    test('a provider failure is thrown for the screen to show', () async {
      allow();
      platform.calendars = [calendar('1')];
      platform.eventsFail = true;

      expect(
        integration.events(from: from, to: to),
        throwsA(isA<Exception>()),
      );
    });

    test('opening an event goes to the platform', () async {
      final e = event('e1', start: DateTime(2026, 10, 18, 9));

      expect(await integration.openEvent(e), isTrue);
      expect(platform.opened, <Object>[e]);
    });
  });

  group('writing', () {
    EventDraft draft({String calendarId = '1', String title = 'Lunch'}) =>
        EventDraft(
          calendarId: calendarId,
          title: title,
          start: DateTime(2026, 10, 18, 12),
          end: DateTime(2026, 10, 18, 13),
          allDay: false,
        );

    void allow() {
      platform.granted = allowed;
      settings.calendarIntegration = true;
      platform.calendars = [
        calendar('1', name: 'Personal'),
        calendar('2', name: 'Holidays', canWrite: false, isOwner: false),
      ];
    }

    Future<CalendarWriteProblem?> problemOf(Future<Object?> Function() act) async {
      try {
        await act();
        return null;
      } on CalendarWriteException catch (e) {
        return e.problem;
      }
    }

    test('a new event is saved in a writable calendar', () async {
      allow();

      final id = await integration.createEvent(draft());

      expect(id, startsWith('n'));
      expect(platform.created.single.title, 'Lunch');
      expect(platform.created.single.calendarId, '1');
    });

    test('nothing is written while the integration is off', () async {
      platform.granted = allowed;
      platform.calendars = [calendar('1')];

      expect(
        await problemOf(() => integration.createEvent(draft())),
        CalendarWriteProblem.notEnabled,
      );
      expect(platform.created, isEmpty);
    });

    test('without the write permission nothing is written', () async {
      allow();
      platform.granted = const CalendarPermissions(read: true, write: false);

      expect(
        await problemOf(() => integration.createEvent(draft())),
        CalendarWriteProblem.noWritePermission,
      );
    });

    test('a read-only or unknown calendar refuses the event', () async {
      allow();

      expect(
        await problemOf(() => integration.createEvent(draft(calendarId: '2'))),
        CalendarWriteProblem.readOnly,
      );
      expect(
        await problemOf(() => integration.createEvent(draft(calendarId: '9'))),
        CalendarWriteProblem.noWritableCalendar,
      );
      expect(platform.created, isEmpty);
    });

    test('an invalid draft is rejected before anything is written', () async {
      allow();

      expect(
        () => integration.createEvent(draft(title: ' ')),
        throwsArgumentError,
      );
      expect(platform.created, isEmpty);
    });

    test('a provider failure becomes a problem', () async {
      allow();
      platform.writeFails = true;

      expect(
        await problemOf(() => integration.createEvent(draft())),
        CalendarWriteProblem.failed,
      );
    });

    test('an event is changed, keeping its calendar', () async {
      allow();
      platform.events = [event('e1', calendarId: '1', start: DateTime(2026, 10, 18, 9))];
      final found = (await integration.events(
        from: DateTime(2026, 10, 18),
        to: DateTime(2026, 10, 19),
      )).single;

      await integration.updateEvent(found, draft(calendarId: '2', title: 'Moved'));

      expect(platform.updated.single.$1, 'e1');
      expect(platform.updated.single.$2.title, 'Moved');
      expect(platform.updated.single.$2.calendarId, '1');
    });

    test('a repeating event is not changed or deleted', () async {
      allow();
      platform.events = [
        event('r', calendarId: '1', start: DateTime(2026, 10, 18, 9), recurring: true),
      ];
      final found = (await integration.events(
        from: DateTime(2026, 10, 18),
        to: DateTime(2026, 10, 19),
      )).single;

      expect(found.recurring, isTrue);
      expect(found.editable, isFalse);
      expect(
        await problemOf(() => integration.updateEvent(found, draft())),
        CalendarWriteProblem.recurring,
      );
      expect(
        await problemOf(() => integration.deleteEvent(found)),
        CalendarWriteProblem.recurring,
      );
      expect(platform.updated, isEmpty);
      expect(platform.deleted, isEmpty);
    });

    test('an event of a read-only calendar is not editable', () async {
      allow();
      platform.events = [event('h', calendarId: '2', start: DateTime(2026, 10, 18, 9))];
      final found = (await integration.events(
        from: DateTime(2026, 10, 18),
        to: DateTime(2026, 10, 19),
      )).single;

      expect(found.editable, isFalse);
      expect(
        await problemOf(() => integration.deleteEvent(found)),
        CalendarWriteProblem.readOnly,
      );
    });

    test('an event is deleted', () async {
      allow();
      platform.events = [event('e1', calendarId: '1', start: DateTime(2026, 10, 18, 9))];
      final found = (await integration.events(
        from: DateTime(2026, 10, 18),
        to: DateTime(2026, 10, 19),
      )).single;

      await integration.deleteEvent(found);

      expect(platform.deleted, <String>['e1']);
    });
  });

  group('tasks in the calendar', () {
    TaskItem task({DateTime? dueAt, String id = 't1'}) {
      final now = DateTime.utc(2026, 10, 1);
      return TaskItem(
        id: id,
        title: 'Call Sara',
        notes: 'About the trip',
        kind: TaskKind.task,
        status: TaskStatus.open,
        createdAt: now,
        updatedAt: now,
        dueAt: dueAt,
      );
    }

    void allow() {
      platform.granted = allowed;
      settings.calendarIntegration = true;
      platform.calendars = [calendar('1', name: 'Personal')];
    }

    test('a task becomes a one-hour event and is linked', () async {
      allow();
      final due = DateTime(2026, 10, 20, 9);

      final result = await integration.addTaskToCalendar(task(dueAt: due));

      expect(result, AddToCalendarResult.added);
      final created = platform.created.single;
      expect(created.title, 'Call Sara');
      expect(created.notes, 'About the trip');
      expect(created.start, due);
      expect(created.end, due.add(const Duration(hours: 1)));
      expect(settings.taskEventLinks['t1'], isNotNull);
      expect(await integration.isTaskInCalendar('t1'), isTrue);
    });

    test('a second request does not create a second event', () async {
      allow();
      final t = task(dueAt: DateTime(2026, 10, 20, 9));

      await integration.addTaskToCalendar(t);
      final again = await integration.addTaskToCalendar(t);

      expect(again, AddToCalendarResult.alreadyAdded);
      expect(platform.created, hasLength(1));
    });

    test('a task without a time cannot be added', () async {
      allow();

      expect(
        () => integration.addTaskToCalendar(task()),
        throwsA(
          isA<CalendarWriteException>().having(
            (e) => e.problem,
            'problem',
            CalendarWriteProblem.noTime,
          ),
        ),
      );
    });

    test('without a writable default calendar nothing is created', () async {
      platform.granted = allowed;
      settings.calendarIntegration = true;
      platform.calendars = [
        calendar('2', canWrite: false, isOwner: false),
      ];

      expect(
        () => integration.addTaskToCalendar(
          task(dueAt: DateTime(2026, 10, 20, 9)),
        ),
        throwsA(isA<CalendarWriteException>()),
      );
      expect(platform.created, isEmpty);
    });

    test('a link to a deleted event is forgotten, so it can be added again', () async {
      allow();
      final t = task(dueAt: DateTime(2026, 10, 20, 9));
      await integration.addTaskToCalendar(t);
      final eventId = settings.taskEventLinks['t1']!;
      platform.events.removeWhere((e) => e.eventId == eventId);
      platform.existing.remove(eventId);

      expect(await integration.isTaskInCalendar('t1'), isFalse);
      expect(settings.taskEventLinks, isEmpty);
      expect(await integration.addTaskToCalendar(t), AddToCalendarResult.added);
      expect(platform.created, hasLength(2));
    });

    test('forgetTaskLink removes the link and keeps the event', () async {
      allow();
      await integration.addTaskToCalendar(task(dueAt: DateTime(2026, 10, 20, 9)));

      await integration.forgetTaskLink('t1');

      expect(settings.taskEventLinks, isEmpty);
      expect(platform.events, hasLength(1));
    });
  });
}
