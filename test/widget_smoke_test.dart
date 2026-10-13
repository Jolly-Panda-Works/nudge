import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/app_info.dart';
import 'package:nudge/app_services.dart';
import 'package:nudge/application/capture_ingestor.dart';
import 'package:nudge/main.dart';

import 'support/fake_capture_platform.dart';
import 'support/stubs.dart';

void main() {
  testWidgets('shell shows name and version without services', (tester) async {
    await tester.pumpWidget(const NudgeApp());
    expect(find.text('$appName v$appVersion'), findsOneWidget);
  });

  testWidgets('shell shows the startup error type', (tester) async {
    await tester.pumpWidget(const NudgeApp(startupError: 'StateError'));
    expect(find.text('Startup failed: StateError'), findsOneWidget);
  });

  testWidgets('status page reflects platform state and counts', (tester) async {
    final platform = FakeCapturePlatform()
      ..accessGranted = true
      ..connected = false;
    final notifications = StubNotificationRepository(total: 3, active: 2);
    final services = AppServices(
      platform: platform,
      notifications: notifications,
      ingestor: CaptureIngestor(
        platform: platform,
        notifications: notifications,
        settings: StubSettingsRepository(),
      ),
    );

    await tester.pumpWidget(NudgeApp(services: services));
    await tester.pumpAndSettle();

    expect(find.text('Notification access: granted'), findsOneWidget);
    expect(find.text('Listener: not connected'), findsOneWidget);
    expect(find.text('Stored notifications: 3 (2 active)'), findsOneWidget);
    expect(find.text('Open Notification Access settings'), findsOneWidget);
  });
}
