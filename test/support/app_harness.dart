import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/app_services.dart';
import 'package:nudge/application/capture_ingestor.dart';
import 'package:nudge/main.dart';

import 'fake_capture_platform.dart';
import 'fake_calendar_platform.dart';
import 'fake_data_exporter.dart';
import 'fake_reminder_platform.dart';
import 'in_memory_repositories.dart';
import 'in_memory_task_repository.dart';

/// Builds the app with fakes so widget tests need no device and no database.
final class AppHarness {
  AppHarness({
    bool accessGranted = true,
    bool connected = true,
    bool supported = true,
    bool remindersSupported = false,
    bool calendarsSupported = false,
  }) : platform = (FakeCapturePlatform()
         ..accessGranted = accessGranted
         ..connected = connected
         ..supported = supported),
       reminders = (FakeReminderPlatform()..supported = remindersSupported),
       deviceCalendars = (FakeCalendarPlatform()
         ..supported = calendarsSupported);

  final FakeCapturePlatform platform;
  final InMemoryNotificationRepository notifications =
      InMemoryNotificationRepository();
  final InMemorySettingsRepository settings = InMemorySettingsRepository();
  final InMemoryTaskRepository tasks = InMemoryTaskRepository();
  final FakeDataExporter exporter = FakeDataExporter();
  final FakeReminderPlatform reminders;
  final FakeCalendarPlatform deviceCalendars;

  late final AppServices services = AppServices(
    platform: platform,
    notifications: notifications,
    settings: settings,
    tasks: tasks,
    exporter: exporter,
    reminderPlatform: reminders,
    calendarPlatform: deviceCalendars,
    ingestor: CaptureIngestor(
      platform: platform,
      notifications: notifications,
      settings: settings,
    ),
  );

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(NudgeApp(services: services));
    await tester.pumpAndSettle();
  }
}
