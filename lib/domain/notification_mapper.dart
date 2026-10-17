import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'captured_notification.dart';
import 'raw_notification_payload.dart';
import 'source_ref.dart';

/// Maps native payloads to domain objects. Pure and deterministic given a clock.
final class NotificationMapper {
  NotificationMapper({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  CapturedNotification map(RawNotificationPayload payload) {
    final title = _clean(payload.title);
    final text = _clean(payload.text);
    final redacted = payload.redactedHint || (title == null && text == null);
    final now = _clock().toUtc();

    return CapturedNotification(
      key: payload.key,
      packageName: payload.packageName,
      appLabel: _clean(payload.appLabel),
      title: title,
      text: text,
      postedAt: DateTime.fromMillisecondsSinceEpoch(
        payload.postTimeMillis,
        isUtc: true,
      ),
      groupKey: _clean(payload.groupKey),
      isGroupSummary: payload.isGroupSummary,
      isOngoing: payload.isOngoing,
      isRedacted: redacted,
      contentHash: _hash(payload.packageName, title, text),
      source: SourceRef(
        packageName: payload.packageName,
        notificationKey: payload.key,
        hasContentAction: payload.hasContentAction,
        actionTitles: List<String>.unmodifiable(payload.actionTitles),
      ),
      firstSeenAt: now,
      lastUpdatedAt: now,
    );
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static String _hash(String packageName, String? title, String? text) {
    final input = '$packageName\u0000${title ?? ''}\u0000${text ?? ''}';
    return sha256.convert(utf8.encode(input)).toString();
  }
}
