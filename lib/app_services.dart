import 'dart:async';

import 'application/capture_ingestor.dart';
import 'application/capture_status_controller.dart';
import 'application/calendar_integration.dart';
import 'application/language_controller.dart';
import 'application/reminder_scheduler.dart';
import 'application/retention_service.dart';
import 'application/theme_controller.dart';
import 'application/source_navigator.dart';
import 'application/text_importer.dart';
import 'data/database/app_database.dart';
import 'data/database/open_connection.dart';
import 'data/drift_capture_settings_repository.dart';
import 'data/drift_notification_repository.dart';
import 'data/drift_task_repository.dart';
import 'domain/capture_settings_repository.dart';
import 'domain/notification_repository.dart';
import 'domain/task_repository.dart';
import 'platform/capture_platform.dart';
import 'platform/capture_platform_factory.dart';
import 'platform/calendar_platform.dart';
import 'platform/calendar_platform_factory.dart';
import 'platform/data_exporter.dart';
import 'platform/noop_calendar_platform.dart';
import 'platform/noop_reminder_platform.dart';
import 'platform/reminder_platform.dart';
import 'platform/reminder_platform_factory.dart';

/// Wires the app together. UI code receives this instead of creating objects.
final class AppServices {
  AppServices({
    required this.platform,
    required this.notifications,
    required this.settings,
    required this.tasks,
    required this.ingestor,
    required this.exporter,
    TextImporter? importer,
    RetentionService? retention,
    SourceNavigator? sourceNavigator,
    ReminderPlatform? reminderPlatform,
    LanguageController? language,
    ThemeController? theme,
    CalendarPlatform? calendarPlatform,
    CalendarIntegration? calendarIntegration,
    ReminderScheduler? reminderScheduler,
    CaptureStatusController? statusController,
    this.database,
  }) : importer = importer ?? TextImporter(notifications: notifications),
       retention =
           retention ??
           RetentionService(notifications: notifications, settings: settings),
       sourceNavigator = sourceNavigator ?? SourceNavigator(platform),
       reminderPlatform = reminderPlatform ?? const NoopReminderPlatform(),
       language = language ?? LanguageController(settings, deviceLanguage: () => 'en'),
       theme = theme ?? ThemeController(settings),
       calendarPlatform = calendarPlatform ?? const NoopCalendarPlatform(),
       statusController = statusController ?? CaptureStatusController(platform) {
    this.reminderScheduler =
        reminderScheduler ??
        ReminderScheduler(platform: this.reminderPlatform, tasks: tasks);
    this.calendars =
        calendarIntegration ??
        CalendarIntegration(platform: this.calendarPlatform, settings: settings);
  }

  factory AppServices.create() {
    final database = openAppDatabase();
    final platform = createCapturePlatform();
    final reminderPlatform = createReminderPlatform();
    final notifications = DriftNotificationRepository(database);
    final settings = DriftCaptureSettingsRepository(database);
    return AppServices(
      database: database,
      platform: platform,
      notifications: notifications,
      settings: settings,
      tasks: DriftTaskRepository(database),
      ingestor: CaptureIngestor(
        platform: platform,
        notifications: notifications,
        settings: settings,
      ),
      exporter: createDataExporter(),
      reminderPlatform: reminderPlatform,
      language: LanguageController(settings),
      calendarPlatform: createCalendarPlatform(),
    );
  }

  final AppDatabase? database;
  final CapturePlatform platform;
  final NotificationRepository notifications;
  final CaptureSettingsRepository settings;
  final TaskRepository tasks;
  final CaptureIngestor ingestor;
  final DataExporter exporter;
  final TextImporter importer;
  final RetentionService retention;
  final SourceNavigator sourceNavigator;
  final ReminderPlatform reminderPlatform;
  final LanguageController language;
  final ThemeController theme;
  final CalendarPlatform calendarPlatform;
  late final CalendarIntegration calendars;
  late final ReminderScheduler reminderScheduler;
  final CaptureStatusController statusController;

  /// Starts status tracking, applies the retention setting and drains the
  /// native queue.
  Future<void> start() async {
    statusController.start();
    unawaited(
      retention.apply().then<void>((_) {}, onError: (Object _) {
        // Retention is retried on the next start or when the setting changes.
      }),
    );
    unawaited(
      reminderScheduler.start().then<void>((_) {}, onError: (Object _) {
        // Alarms are set again on the next task change or start.
      }),
    );
    await ingestor.start();
  }
}
