import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/application/calendar_integration.dart';
import 'package:nudge/domain/external_calendar.dart';

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
    platform.calendars = [calendar('1'), calendar('2', name: 'Work')];

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
}
