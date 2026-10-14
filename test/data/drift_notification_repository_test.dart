import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/data/database/app_database.dart';
import 'package:nudge/data/drift_notification_repository.dart';
import 'package:nudge/domain/captured_notification.dart';
import 'package:nudge/domain/ingest_policy.dart';

import '../support/fixtures.dart';

void main() {
  late AppDatabase db;
  late DriftNotificationRepository repo;
  final later = DateTime.utc(2026, 10, 13, 9);
  const open = CapturePolicy();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftNotificationRepository(db, clock: () => later);
  });

  tearDown(() async {
    await db.close();
  });

  test('insert then find round-trips all fields', () async {
    final n = captured(title: null, actions: <String>['Reply', 'Mute']);
    expect(await repo.ingest(n, open), IngestDecision.insert);

    final stored = await repo.findByKey(n.key);
    expect(stored, isNotNull);
    expect(stored!.title, isNull);
    expect(stored.text, 'Hello');
    expect(stored.postedAt, n.postedAt);
    expect(stored.postedAt.isUtc, isTrue);
    expect(stored.contentHash, n.contentHash);
    expect(stored.source.hasContentAction, isTrue);
    expect(stored.source.actionTitles, <String>['Reply', 'Mute']);
    expect(stored.firstSeenAt, fixedNow);
    expect(stored.status, NotificationStatus.active);
  });

  test('same key and same content is ignored', () async {
    await repo.ingest(captured(), open);
    expect(
      await repo.ingest(captured(time: 1760000009000), open),
      IngestDecision.ignoreDuplicate,
    );
    expect((await repo.watchInbox().first).length, 1);
  });

  test('changed text updates the row and bumps updateCount', () async {
    await repo.ingest(captured(), open);
    expect(
      await repo.ingest(captured(text: 'Edited'), open),
      IngestDecision.update,
    );
    final stored = await repo.findByKey(captured().key);
    expect(stored!.text, 'Edited');
    expect(stored.updateCount, 1);
    expect(stored.lastUpdatedAt, later);
    expect(stored.firstSeenAt, fixedNow);
  });

  test(
    'markRemoved keeps content and hides it from the active inbox',
    () async {
      final n = captured();
      await repo.ingest(n, open);
      await repo.markRemoved(n.key);

      final stored = await repo.findByKey(n.key);
      expect(stored!.status, NotificationStatus.removed);
      expect(stored.text, 'Hello');
      expect(await repo.watchInbox(includeRemoved: false).first, isEmpty);
      expect((await repo.watchInbox().first).length, 1);
    },
  );

  test(
    'markRemovedExcept removes only entries missing from active set',
    () async {
      final a = captured(key: 'A', text: 'one');
      final b = captured(key: 'B', text: 'two', time: 1760000100000);
      await repo.ingest(a, open);
      await repo.ingest(b, open);

      expect(await repo.markRemovedExcept(<String>{'A'}), 1);
      expect((await repo.findByKey('A'))!.status, NotificationStatus.active);
      expect((await repo.findByKey('B'))!.status, NotificationStatus.removed);
    },
  );

  test('filtered notifications are not stored', () async {
    const policy = CapturePolicy(
      mode: FilterMode.blocklist,
      packages: <String>{'com.chat'},
    );
    expect(
      await repo.ingest(captured(), policy),
      IngestDecision.ignoreFiltered,
    );
    expect(await repo.findByKey(captured().key), isNull);
  });

  test('identical content re-posted under a new key is ignored', () async {
    await repo.ingest(captured(key: 'B', time: 1760000000000), open);
    expect(
      await repo.ingest(captured(key: 'A', time: 1760000001000), open),
      IngestDecision.ignoreDuplicate,
    );
    expect((await repo.watchInbox().first).length, 1);
  });

  test('purgeOlderThan deletes only entries older than the cutoff', () async {
    await repo.ingest(captured(), open);
    expect(
      await repo.purgeOlderThan(later.subtract(const Duration(days: 30))),
      0,
    );
    expect(await repo.purgeOlderThan(later.add(const Duration(days: 1))), 1);
    expect(await repo.watchInbox().first, isEmpty);
  });

  test('deleteAll removes everything', () async {
    await repo.ingest(captured(key: 'A', text: 'one'), open);
    await repo.ingest(
      captured(key: 'B', text: 'two', time: 1760000100000),
      open,
    );
    expect(await repo.deleteAll(), 2);
    expect(await repo.watchInbox().first, isEmpty);
  });

  test('count returns the total and the active-only number', () async {
    await repo.ingest(captured(key: 'A', text: 'one'), open);
    await repo.ingest(
      captured(key: 'B', text: 'two', time: 1760000100000),
      open,
    );
    await repo.markRemoved('A');

    expect(await repo.count(), 2);
    expect(await repo.count(activeOnly: true), 1);
  });

  test('listSourceApps returns distinct apps sorted by name', () async {
    await repo.ingest(
      captured(key: 'A', pkg: 'com.zeta', label: 'Zeta', text: 'one'),
      open,
    );
    await repo.ingest(
      captured(key: 'B', pkg: 'com.alpha', label: 'Alpha', text: 'two'),
      open,
    );
    await repo.ingest(
      captured(key: 'C', pkg: 'com.alpha', label: 'Alpha', text: 'three'),
      open,
    );

    final apps = await repo.listSourceApps();
    expect(apps.map((a) => a.packageName), <String>['com.alpha', 'com.zeta']);
    expect(apps.map((a) => a.displayName), <String>['Alpha', 'Zeta']);
  });

  test('listAll returns every notification, newest first', () async {
    await repo.ingest(captured(key: 'A', text: 'old'), open);
    await repo.ingest(
      captured(key: 'B', text: 'new', time: 1760000100000),
      open,
    );
    await repo.markRemoved('A');

    final all = await repo.listAll();
    expect(all.map((n) => n.key), <String>['B', 'A']);
    expect(all.last.status, NotificationStatus.removed);
  });

  test('deleteByKey deletes only the given notification', () async {
    await repo.ingest(captured(key: 'A', text: 'one'), open);
    await repo.ingest(
      captured(key: 'B', text: 'two', time: 1760000100000),
      open,
    );

    expect(await repo.deleteByKey('A'), isTrue);
    expect(await repo.deleteByKey('A'), isFalse);
    expect(await repo.findByKey('A'), isNull);
    expect(await repo.findByKey('B'), isNotNull);
  });
}
