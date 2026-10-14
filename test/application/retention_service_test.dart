import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/application/retention_service.dart';
import 'package:nudge/data/database/app_database.dart';
import 'package:nudge/data/drift_capture_settings_repository.dart';
import 'package:nudge/data/drift_notification_repository.dart';
import 'package:nudge/domain/ingest_policy.dart';

import '../support/fixtures.dart';

void main() {
  late AppDatabase db;
  late DriftNotificationRepository repo;
  late DriftCaptureSettingsRepository settings;
  late RetentionService retention;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftNotificationRepository(db);
    settings = DriftCaptureSettingsRepository(db);
    retention = RetentionService(
      notifications: repo,
      settings: settings,
      clock: () => fixedNow.add(const Duration(days: 40)),
    );
    await repo.ingest(captured(), const CapturePolicy());
  });

  tearDown(() async {
    await db.close();
  });

  test('keeps everything when no retention is set', () async {
    expect(await retention.apply(), 0);
    expect(await repo.count(), 1);
  });

  test('keeps notifications that are newer than the limit', () async {
    await settings.setRetentionDays(90);
    expect(await retention.apply(), 0);
    expect(await repo.count(), 1);
  });

  test('deletes notifications older than the limit', () async {
    await settings.setRetentionDays(30);
    expect(await retention.apply(), 1);
    expect(await repo.count(), 0);
  });
}
