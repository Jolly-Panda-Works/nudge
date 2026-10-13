import 'package:nudge/domain/captured_notification.dart';
import 'package:nudge/domain/notification_mapper.dart';
import 'package:nudge/domain/raw_notification_payload.dart';

final DateTime fixedNow = DateTime.utc(2026, 10, 12, 8);

NotificationMapper testMapper() => NotificationMapper(clock: () => fixedNow);

RawNotificationPayload payload({
  String key = '0|com.chat|1|null|10',
  String pkg = 'com.chat',
  String? title = 'Sara',
  String? text = 'Hello',
  int time = 1760000000000,
  bool ongoing = false,
  bool summary = false,
  bool redactedHint = false,
  List<String> actions = const <String>[],
  String? label = 'Chat',
}) {
  return RawNotificationPayload(
    key: key,
    packageName: pkg,
    appLabel: label,
    title: title,
    text: text,
    postTimeMillis: time,
    isOngoing: ongoing,
    isGroupSummary: summary,
    redactedHint: redactedHint,
    hasContentAction: true,
    actionTitles: actions,
  );
}

CapturedNotification captured({
  String key = '0|com.chat|1|null|10',
  String pkg = 'com.chat',
  String? title = 'Sara',
  String? text = 'Hello',
  int time = 1760000000000,
  bool ongoing = false,
  bool summary = false,
  bool redactedHint = false,
  List<String> actions = const <String>[],
  String? label = 'Chat',
}) {
  return testMapper().map(
    payload(
      key: key,
      pkg: pkg,
      title: title,
      text: text,
      time: time,
      ongoing: ongoing,
      summary: summary,
      redactedHint: redactedHint,
      actions: actions,
      label: label,
    ),
  );
}
