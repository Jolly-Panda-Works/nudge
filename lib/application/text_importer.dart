import '../domain/ingest_policy.dart';
import '../domain/notification_mapper.dart';
import '../domain/notification_repository.dart';
import '../domain/raw_notification_payload.dart';
import '../domain/shared_source.dart';

/// Stores text the user shares or pastes. Imported entries are chosen by the
/// user, so they bypass the capture filters.
final class TextImporter {
  TextImporter({
    required NotificationRepository notifications,
    NotificationMapper? mapper,
    DateTime Function()? clock,
  }) : _notifications = notifications,
       _mapper = mapper ?? NotificationMapper(),
       _clock = clock ?? DateTime.now;

  final NotificationRepository _notifications;
  final NotificationMapper _mapper;
  final DateTime Function() _clock;
  int _counter = 0;

  /// Returns false when [text] is blank and nothing was stored.
  Future<bool> importText({
    required String text,
    String? title,
    DateTime? postedAt,
  }) async {
    final body = text.trim();
    if (body.isEmpty) return false;
    final posted = (postedAt ?? _clock()).toUtc();
    final payload = RawNotificationPayload(
      key: 'shared:${posted.millisecondsSinceEpoch}:${_counter++}',
      packageName: sharedPackageName,
      appLabel: sharedAppLabel,
      title: title,
      text: body,
      postTimeMillis: posted.millisecondsSinceEpoch,
    );
    await _notifications.ingest(_mapper.map(payload), const CapturePolicy());
    return true;
  }
}
