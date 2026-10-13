import 'package:flutter/foundation.dart';

import 'capture_platform.dart';
import 'method_channel_capture_platform.dart';
import 'noop_capture_platform.dart';

CapturePlatform createCapturePlatform() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return MethodChannelCapturePlatform();
  }
  return const NoopCapturePlatform();
}
