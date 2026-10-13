import 'application/capture_ingestor.dart';
import 'application/capture_status_controller.dart';
import 'data/database/app_database.dart';
import 'data/database/open_connection.dart';
import 'data/drift_capture_settings_repository.dart';
import 'data/drift_notification_repository.dart';
import 'domain/capture_settings_repository.dart';
import 'domain/notification_repository.dart';
import 'platform/capture_platform.dart';
import 'platform/capture_platform_factory.dart';

/// Wires the app together. UI code receives this instead of creating objects.
final class AppServices {
  AppServices({
    required this.platform,
    required this.notifications,
    required this.settings,
    required this.ingestor,
    CaptureStatusController? statusController,
    this.database,
  }) : statusController = statusController ?? CaptureStatusController(platform);

  factory AppServices.create() {
    final database = openAppDatabase();
    final platform = createCapturePlatform();
    final notifications = DriftNotificationRepository(database);
    final settings = DriftCaptureSettingsRepository(database);
    return AppServices(
      database: database,
      platform: platform,
      notifications: notifications,
      settings: settings,
      ingestor: CaptureIngestor(
        platform: platform,
        notifications: notifications,
        settings: settings,
      ),
    );
  }

  final AppDatabase? database;
  final CapturePlatform platform;
  final NotificationRepository notifications;
  final CaptureSettingsRepository settings;
  final CaptureIngestor ingestor;
  final CaptureStatusController statusController;

  /// Starts status tracking and drains the native queue.
  Future<void> start() async {
    statusController.start();
    await ingestor.start();
  }
}
