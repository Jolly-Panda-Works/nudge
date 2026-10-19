import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/platform/calendar_platform.dart';
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
}
