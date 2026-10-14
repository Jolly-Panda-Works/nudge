import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/domain/captured_notification.dart';
import 'package:nudge/domain/notification_export.dart';

import '../support/fixtures.dart';

void main() {
  test('exports metadata and every notification field', () {
    final json = exportNotificationsJson(
      <CapturedNotification>[
        captured(title: 'Sara', actions: <String>['Reply']),
        captured(key: 'B', title: null, text: null).markRemoved(fixedNow),
      ],
      appVersion: '0.5.0',
      exportedAt: DateTime.utc(2026, 10, 13, 9),
    );

    final data = jsonDecode(json) as Map<String, Object?>;
    expect(data['app'], 'Nudge');
    expect(data['formatVersion'], 1);
    expect(data['appVersion'], '0.5.0');
    expect(data['exportedAt'], '2026-10-13T09:00:00.000Z');

    final items = (data['notifications']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(items, hasLength(2));

    expect(items[0]['title'], 'Sara');
    expect(items[0]['text'], 'Hello');
    expect(items[0]['packageName'], 'com.chat');
    expect(items[0]['appLabel'], 'Chat');
    expect(items[0]['postedAt'], '2025-10-09T08:53:20.000Z');
    expect(items[0]['status'], 'active');
    expect(items[0]['actionTitles'], <String>['Reply']);
    expect(items[0]['hasContentAction'], isTrue);

    expect(items[1]['title'], isNull);
    expect(items[1]['isRedacted'], isTrue);
    expect(items[1]['status'], 'removed');
  });

  test('an empty list exports an empty array', () {
    final json = exportNotificationsJson(
      const [],
      appVersion: '0.5.0',
      exportedAt: DateTime.utc(2026, 10, 13),
    );
    final data = jsonDecode(json) as Map<String, Object?>;
    expect(data['notifications'], isEmpty);
  });
}
