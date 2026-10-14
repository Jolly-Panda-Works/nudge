import 'dart:convert';

import '../domain/raw_notification_payload.dart';

/// One entry of the native capture queue.
sealed class CaptureEvent {
  const CaptureEvent(this.seq);

  /// Parses one queue line.
  ///
  /// Throws [FormatException] when the line is not JSON or has no sequence
  /// number. A line with a sequence number but an invalid structure becomes a
  /// [MalformedEvent] so that it can still be acknowledged and dropped.
  factory CaptureEvent.fromJson(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Event is not a JSON object');
    }
    final seq = decoded['seq'];
    if (seq is! int) {
      throw const FormatException('Event has no sequence number');
    }
    try {
      switch (decoded['type']) {
        case 'posted':
          final payload = decoded['payload'];
          if (payload is! Map<String, Object?>) return MalformedEvent(seq);
          return PostedEvent(seq, RawNotificationPayload.fromMap(payload));
        case 'removed':
          final key = decoded['key'];
          if (key is! String || key.isEmpty) return MalformedEvent(seq);
          return RemovedEvent(seq, key);
        case 'snapshot':
          final keys = decoded['keys'];
          if (keys is! List<Object?>) return MalformedEvent(seq);
          return SnapshotEvent(seq, keys.whereType<String>().toSet());
        case 'shared':
          final text = decoded['text'];
          final postTime = decoded['postTimeMillis'];
          final title = decoded['title'];
          if (text is! String || text.trim().isEmpty || postTime is! int) {
            return MalformedEvent(seq);
          }
          return SharedEvent(
            seq,
            text: text,
            postedAt: DateTime.fromMillisecondsSinceEpoch(
              postTime,
              isUtc: true,
            ),
            title: title is String ? title : null,
          );
        default:
          return MalformedEvent(seq);
      }
    } on FormatException {
      return MalformedEvent(seq);
    }
  }

  final int seq;
}

final class PostedEvent extends CaptureEvent {
  const PostedEvent(super.seq, this.payload);

  final RawNotificationPayload payload;
}

final class RemovedEvent extends CaptureEvent {
  const RemovedEvent(super.seq, this.key);

  final String key;
}

/// Keys of all notifications that were active when the listener connected.
final class SnapshotEvent extends CaptureEvent {
  const SnapshotEvent(super.seq, this.activeKeys);

  final Set<String> activeKeys;
}

/// Text the user shared with the app from another app.
final class SharedEvent extends CaptureEvent {
  const SharedEvent(
    super.seq, {
    required this.text,
    required this.postedAt,
    this.title,
  });

  final String text;
  final DateTime postedAt;
  final String? title;
}

final class MalformedEvent extends CaptureEvent {
  const MalformedEvent(super.seq);
}
