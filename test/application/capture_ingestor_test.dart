import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/application/capture_ingestor.dart';
import 'package:nudge/data/database/app_database.dart';
import 'package:nudge/data/drift_capture_settings_repository.dart';
import 'package:nudge/data/drift_notification_repository.dart';
import 'package:nudge/domain/captured_notification.dart';
import 'package:nudge/domain/ingest_policy.dart';
import 'package:nudge/domain/notification_repository.dart';
import 'package:nudge/platform/capture_signal.dart';

import '../support/fake_capture_platform.dart';
import '../support/fixtures.dart';
import '../support/stubs.dart';

Future<void> waitFor(Future<bool> Function() condition) async {
  for (var i = 0; i < 100; i++) {
    if (await condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Condition was not met in time');
}

void main() {
  late AppDatabase db;
  late DriftNotificationRepository repo;
  late DriftCaptureSettingsRepository settings;
  late FakeCapturePlatform platform;
  late CaptureIngestor ingestor;

  CaptureIngestor buildIngestor(NotificationRepository notifications) {
    return CaptureIngestor(
      platform: platform,
      notifications: notifications,
      settings: settings,
    );
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftNotificationRepository(db);
    settings = DriftCaptureSettingsRepository(db);
    platform = FakeCapturePlatform();
    ingestor = buildIngestor(repo);
  });

  tearDown(() async {
    await ingestor.dispose();
    await db.close();
  });

  test('stores posted notifications and acknowledges them', () async {
    platform
      ..addPosted(payload(key: 'A', text: 'one'))
      ..addPosted(payload(key: 'B', text: 'two', time: 1760000100000));

    expect(await ingestor.drain(), 2);
    expect(await repo.count(), 2);
    expect(platform.queue, isEmpty);
    expect(platform.lastAck, 2);
  });

  test('the same notification posted twice is stored once', () async {
    platform
      ..addPosted(payload())
      ..addPosted(payload(time: 1760000009000));

    await ingestor.drain();
    expect(await repo.count(), 1);
  });

  test('a removal marks the stored notification as removed', () async {
    platform.addPosted(payload(key: 'A'));
    await ingestor.drain();

    platform.addRemoved('A');
    await ingestor.drain();

    final stored = await repo.findByKey('A');
    expect(stored!.status, NotificationStatus.removed);
    expect(stored.text, 'Hello');
  });

  test('a snapshot removes entries that are no longer active', () async {
    platform
      ..addPosted(payload(key: 'A', text: 'one'))
      ..addPosted(payload(key: 'B', text: 'two', time: 1760000100000));
    await ingestor.drain();

    platform.addSnapshot(<String>{'A'});
    await ingestor.drain();

    expect((await repo.findByKey('A'))!.status, NotificationStatus.active);
    expect((await repo.findByKey('B'))!.status, NotificationStatus.removed);
  });

  test('blocklisted packages are acknowledged but not stored', () async {
    await settings.setMode(FilterMode.blocklist);
    await settings.addRule('com.chat');
    platform.addPosted(payload());

    await ingestor.drain();
    expect(await repo.count(), 0);
    expect(platform.queue, isEmpty);
  });

  test('notifications from the app itself are ignored', () async {
    platform
      ..package = 'com.chat'
      ..addPosted(payload());

    await ingestor.drain();
    expect(await repo.count(), 0);
  });

  test(
    'malformed events are skipped and later events still processed',
    () async {
      platform
        ..addMalformed()
        ..addPosted(payload());

      await ingestor.drain();
      expect(await repo.count(), 1);
      expect(platform.queue, isEmpty);
    },
  );

  test('events stay queued when storing fails and are retried', () async {
    final flaky = FlakyNotificationRepository(repo);
    final failing = buildIngestor(flaky);
    addTearDown(failing.dispose);
    flaky.failIngest = true;
    platform.addPosted(payload());

    await expectLater(failing.drain(), throwsA(isA<StateError>()));
    expect(platform.queue.length, 1);
    expect(platform.lastAck, 0);

    flaky.failIngest = false;
    await failing.drain();
    expect(await repo.count(), 1);
    expect(platform.queue, isEmpty);
  });

  test('a wake signal drains the queue', () async {
    await ingestor.start();
    platform.addPosted(payload());
    platform.signal(const WakeSignal());

    await waitFor(() async => await repo.count() == 1);
    expect(platform.queue, isEmpty);
  });

  test('onDrained reports how many events were processed', () async {
    platform.addPosted(payload());
    final reported = ingestor.onDrained.first;

    await ingestor.drain();
    expect(await reported, 1);
  });
}
