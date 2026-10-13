import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/platform/capture_event.dart';

String json(Map<String, Object?> map) => jsonEncode(map);

void main() {
  group('CaptureEvent.fromJson', () {
    test('parses a posted event', () {
      final event = CaptureEvent.fromJson(
        json(<String, Object?>{
          'seq': 7,
          'type': 'posted',
          'payload': <String, Object?>{
            'key': 'k1',
            'packageName': 'com.chat',
            'postTimeMillis': 1760000000000,
            'title': 'Sara',
            'text': 'Hello',
            'actionTitles': <String>['Reply'],
            'hasContentAction': true,
          },
        }),
      );
      expect(event, isA<PostedEvent>());
      final posted = event as PostedEvent;
      expect(posted.seq, 7);
      expect(posted.payload.key, 'k1');
      expect(posted.payload.actionTitles, <String>['Reply']);
    });

    test('parses removed and snapshot events', () {
      final removed = CaptureEvent.fromJson(
        json(<String, Object?>{'seq': 1, 'type': 'removed', 'key': 'k1'}),
      );
      expect((removed as RemovedEvent).key, 'k1');

      final snapshot = CaptureEvent.fromJson(
        json(<String, Object?>{
          'seq': 2,
          'type': 'snapshot',
          'keys': <String>['a', 'b'],
        }),
      );
      expect((snapshot as SnapshotEvent).activeKeys, <String>{'a', 'b'});
    });

    test('an invalid structure with a sequence number is malformed', () {
      final event = CaptureEvent.fromJson(
        json(<String, Object?>{
          'seq': 3,
          'type': 'posted',
          'payload': <String, Object?>{'packageName': 'com.chat'},
        }),
      );
      expect(event, isA<MalformedEvent>());
      expect(event.seq, 3);
    });

    test('an unknown type is malformed', () {
      final event = CaptureEvent.fromJson(
        json(<String, Object?>{'seq': 4, 'type': 'mystery'}),
      );
      expect(event, isA<MalformedEvent>());
    });

    test('throws FormatException for non-JSON input', () {
      expect(() => CaptureEvent.fromJson('not json'), throwsFormatException);
    });

    test('throws FormatException when the sequence number is missing', () {
      expect(
        () => CaptureEvent.fromJson(json(<String, Object?>{'type': 'removed'})),
        throwsFormatException,
      );
    });
  });
}
