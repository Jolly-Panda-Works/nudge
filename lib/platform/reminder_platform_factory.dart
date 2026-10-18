import 'package:flutter/foundation.dart';

import 'method_channel_reminder_platform.dart';
import 'noop_reminder_platform.dart';
import 'reminder_platform.dart';

ReminderPlatform createReminderPlatform() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return MethodChannelReminderPlatform();
  }
  return const NoopReminderPlatform();
}
