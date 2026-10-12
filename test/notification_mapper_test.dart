import 'package:flutter_test/flutter_test.dart';
import 'package:unified_inbox/domain/raw_notification_payload.dart';

import 'support/fixtures.dart';

void main() {
  group('NotificationMapper', () {
    test('trims text and converts blank strings to null', () {
      final n = testMapper().map(payload(title: '  Sara  ', text: '   '));
      expect(n.title, 'Sara');
      expect(n.text, isNull);
      expect(n.isRedacted, isFalse);
    });

    test('marks notification redacted when title and text are empty', () {
      final n = testMapper().map(payload(title: null, text: ' '));
      expect(n.isRedacted, isTrue);
    });

    test('honours the native redacted hint', () {
      final n = testMapper().map(payload(redactedHint: true));
      expect(n.isRedacted, isTrue);
    });

    test('postedAt is UTC and matches the epoch value', () {
      final n = testMapper().map(payload(time: 1760000000000));
      expect(n.postedAt.isUtc, isTrue);
      expect(
        n.postedAt,
        DateTime.fromMillisecondsSinceEpoch(1760000000000, isUtc: true),
      );
      expect(n.firstSeenAt, fixedNow);
    });

    test('content hash ignores timestamp but depends on text', () {
      final a = testMapper().map(payload(time: 1));
      final b = testMapper().map(payload(time: 99999));
      final c = testMapper().map(payload(text: 'Different'));
      expect(a.contentHash, b.contentHash);
      expect(a.contentHash, isNot(c.contentHash));
    });

    test('source reference keeps key, package and action presence', () {
      final n = testMapper().map(payload());
      expect(n.source.notificationKey, '0|com.chat|1|null|10');
      expect(n.source.packageName, 'com.chat');
      expect(n.source.hasContentAction, isTrue);
    });
  });

  group('RawNotificationPayload.fromMap', () {
    test('parses a valid map', () {
      final p = RawNotificationPayload.fromMap(<Object?, Object?>{
        'key': 'k1',
        'packageName': 'com.chat',
        'postTimeMillis': 123,
        'title': 'T',
        'actionTitles': <Object?>['Reply', 'Mute'],
        'hasContentAction': true,
      });
      expect(p.key, 'k1');
      expect(p.actionTitles, <String>['Reply', 'Mute']);
      expect(p.hasContentAction, isTrue);
      expect(p.isOngoing, isFalse);
    });

    test('throws FormatException when key is missing', () {
      expect(
        () => RawNotificationPayload.fromMap(<Object?, Object?>{
          'packageName': 'com.chat',
          'postTimeMillis': 1,
        }),
        throwsFormatException,
      );
    });

    test('throws FormatException when post time is not an int', () {
      expect(
        () => RawNotificationPayload.fromMap(<Object?, Object?>{
          'key': 'k',
          'packageName': 'p',
          'postTimeMillis': 'x',
        }),
        throwsFormatException,
      );
    });
  });
}
