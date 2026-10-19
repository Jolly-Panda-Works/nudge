import 'package:flutter/foundation.dart';

import 'calendar_platform.dart';
import 'method_channel_calendar_platform.dart';
import 'noop_calendar_platform.dart';

CalendarPlatform createCalendarPlatform() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return MethodChannelCalendarPlatform();
  }
  return const NoopCalendarPlatform();
}
