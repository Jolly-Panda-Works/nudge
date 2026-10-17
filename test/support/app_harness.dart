import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/app_services.dart';
import 'package:nudge/application/capture_ingestor.dart';
import 'package:nudge/main.dart';

import 'fake_capture_platform.dart';
import 'fake_data_exporter.dart';
import 'in_memory_repositories.dart';
import 'in_memory_task_repository.dart';

/// Builds the app with fakes so widget tests need no device and no database.
final class AppHarness {
  AppHarness({
    bool accessGranted = true,
    bool connected = true,
    bool supported = true,
  }) : platform = (FakeCapturePlatform()
         ..accessGranted = accessGranted
         ..connected = connected
         ..supported = supported);

  final FakeCapturePlatform platform;
  final InMemoryNotificationRepository notifications =
      InMemoryNotificationRepository();
  final InMemorySettingsRepository settings = InMemorySettingsRepository();
  final InMemoryTaskRepository tasks = InMemoryTaskRepository();
  final FakeDataExporter exporter = FakeDataExporter();

  late final AppServices services = AppServices(
    platform: platform,
    notifications: notifications,
    settings: settings,
    tasks: tasks,
    exporter: exporter,
    ingestor: CaptureIngestor(
      platform: platform,
      notifications: notifications,
      settings: settings,
    ),
  );

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(NudgeApp(services: services));
    await tester.pumpAndSettle();
  }
}
