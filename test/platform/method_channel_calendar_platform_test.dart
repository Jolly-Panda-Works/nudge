import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/platform/calendar_platform.dart';
import '../support/fake_calendar_platform.dart' show event;
import 'package:nudge/platform/method_channel_calendar_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/calendars');
  late MethodChannelCalendarPlatform platform;

  void handle(Future<Object?> Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  setUp(() => platform = MethodChannelCalendarPlatform(channel: channel));
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('permissions are read from the map', () async {
    handle((call) async => <String, Object?>{'read': true, 'write': false});

    final permissions = await platform.permissions();

    expect(permissions.read, isTrue);
    expect(permissions.write, isFalse);
  });

  test('calendars are parsed and bad rows are skipped', () async {
    handle((call) async {
      expect(call.method, 'listCalendars');
      return <Map<String, Object?>>[
        <String, Object?>{
          'id': '7',
          'displayName': 'Work',
          'accountName': 'me@example.com',
          'accountType': 'com.google',
          'color': -14575885,
          'canWrite': true,
          'isOwner': true,
          'visible': true,
        },
        <String, Object?>{'id': '', 'displayName': 'No id'},
        <String, Object?>{'id': '8', 'color': null, 'canWrite': false},
      ];
    });

    final calendars = await platform.listCalendars();

    expect(calendars, hasLength(2));
    expect(calendars[0].id, '7');
    expect(calendars[0].label, 'Work');
    expect(calendars[0].color, -14575885);
    expect(calendars[0].canWrite, isTrue);
    expect(calendars[1].id, '8');
    expect(calendars[1].color, isNull);
    expect(calendars[1].canWrite, isFalse);
    expect(calendars[1].visibleInProvider, isFalse);
  });

  test('a denied read becomes a platform exception', () async {
    handle((call) async => throw PlatformException(code: 'permission_denied'));

    expect(
      platform.listCalendars(),
      throwsA(
        isA<CalendarPlatformException>().having(
          (e) => e.code,
          'code',
          'permission_denied',
        ),
      ),
    );
  });

  test('any other failure is a query failure', () async {
    handle((call) async => throw PlatformException(code: 'boom'));

    expect(
      platform.listCalendars(),
      throwsA(
        isA<CalendarPlatformException>().having(
          (e) => e.code,
          'code',
          'query_failed',
        ),
      ),
    );
  });

  test('events are parsed; all-day events become local days', () async {
    handle((call) async {
      expect(call.method, 'listEvents');
      expect(call.arguments['calendarIds'], <Object?>['1']);
      return <Map<String, Object?>>[
        <String, Object?>{
          'eventId': '5',
          'calendarId': '1',
          'title': 'Standup',
          'beginMillis': DateTime.utc(2026, 10, 18, 6, 30).millisecondsSinceEpoch,
          'endMillis': DateTime.utc(2026, 10, 18, 7).millisecondsSinceEpoch,
          'allDay': false,
          'color': -14575885,
        },
        <String, Object?>{
          'eventId': '6',
          'calendarId': '1',
          'title': 'Holiday',
          'beginMillis': DateTime.utc(2026, 10, 20).millisecondsSinceEpoch,
          'endMillis': DateTime.utc(2026, 10, 21).millisecondsSinceEpoch,
          'allDay': true,
        },
        <String, Object?>{'eventId': '7'},
      ];
    });

    final events = await platform.listEvents(
      from: DateTime(2026, 10, 17),
      to: DateTime(2026, 10, 25),
      calendarIds: <String>{'1'},
    );

    expect(events, hasLength(2));
    expect(events[0].title, 'Standup');
    expect(events[0].allDay, isFalse);
    expect(events[0].start, DateTime.utc(2026, 10, 18, 6, 30).toLocal());
    expect(events[0].color, -14575885);
    expect(events[1].allDay, isTrue);
    expect(events[1].start, DateTime(2026, 10, 20));
    expect(events[1].end, DateTime(2026, 10, 21));
    expect(events[1].color, isNull);
  });

  test('no calendars means no query', () async {
    var called = false;
    handle((call) async {
      called = true;
      return <Object?>[];
    });

    final events = await platform.listEvents(
      from: DateTime(2026, 10, 17),
      to: DateTime(2026, 10, 25),
      calendarIds: <String>{},
    );

    expect(events, isEmpty);
    expect(called, isFalse);
  });

  test('opening an all-day event sends UTC midnights', () async {
    Map<Object?, Object?>? sent;
    handle((call) async {
      sent = call.arguments as Map<Object?, Object?>;
      return true;
    });

    final opened = await platform.openEvent(
      event(
        '6',
        start: DateTime(2026, 10, 20),
        end: DateTime(2026, 10, 21),
        allDay: true,
      ),
    );

    expect(opened, isTrue);
    expect(sent!['eventId'], '6');
    expect(
      sent!['beginMillis'],
      DateTime.utc(2026, 10, 20).millisecondsSinceEpoch,
    );
    expect(sent!['allDay'], isTrue);
  });
}
