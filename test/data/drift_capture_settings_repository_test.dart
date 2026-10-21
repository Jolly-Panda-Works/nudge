import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/data/database/app_database.dart';
import 'package:nudge/data/drift_capture_settings_repository.dart';
import 'package:nudge/domain/ingest_policy.dart';

void main() {
  late AppDatabase db;
  late DriftCaptureSettingsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftCaptureSettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('default policy is open with no rules', () async {
    final policy = await repo.loadPolicy(ownPackageName: 'app.nudge.nudge');
    expect(policy.mode, FilterMode.off);
    expect(policy.packages, isEmpty);
    expect(policy.captureOngoing, isFalse);
    expect(policy.captureGroupSummaries, isFalse);
    expect(policy.ownPackageName, 'app.nudge.nudge');
  });

  test('mode, rules and toggles persist', () async {
    await repo.setMode(FilterMode.allowlist);
    await repo.addRule('com.chat', appLabel: 'Chat');
    await repo.addRule('com.mail');
    await repo.setCaptureOngoing(value: true);
    await repo.setCaptureGroupSummaries(value: true);

    final policy = await repo.loadPolicy();
    expect(policy.mode, FilterMode.allowlist);
    expect(policy.packages, <String>{'com.chat', 'com.mail'});
    expect(policy.captureOngoing, isTrue);
    expect(policy.captureGroupSummaries, isTrue);
  });

  test('removeRule deletes a package', () async {
    await repo.addRule('com.chat');
    await repo.removeRule('com.chat');
    expect((await repo.loadPolicy()).packages, isEmpty);
  });

  test('retention days default to null and can be set and cleared', () async {
    expect(await repo.getRetentionDays(), isNull);
    await repo.setRetentionDays(30);
    expect(await repo.getRetentionDays(), 30);
    await repo.setRetentionDays(null);
    expect(await repo.getRetentionDays(), isNull);
  });

  test('the calendar system defaults to Jalali and can be changed', () async {
    expect(await repo.getCalendarSystemId(), 'jalali');
    await repo.setCalendarSystemId('gregorian');
    expect(await repo.getCalendarSystemId(), 'gregorian');
    await repo.setCalendarSystemId('anything else');
    expect(await repo.getCalendarSystemId(), 'jalali');
  });

  test('the calendar choices are stored', () async {
    expect(await repo.getCalendarIntegrationEnabled(), isFalse);
    expect(await repo.getVisibleCalendarIds(), isNull);
    expect(await repo.getDefaultCalendarId(), isNull);

    await repo.setCalendarIntegrationEnabled(enabled: true);
    await repo.setVisibleCalendarIds(<String>{'3', '1'});
    await repo.setDefaultCalendarId('3');

    expect(await repo.getCalendarIntegrationEnabled(), isTrue);
    expect(await repo.getVisibleCalendarIds(), <String>{'1', '3'});
    expect(await repo.getDefaultCalendarId(), '3');

    await repo.setVisibleCalendarIds(<String>{});
    expect(await repo.getVisibleCalendarIds(), isEmpty);
    await repo.setDefaultCalendarId(null);
    expect(await repo.getDefaultCalendarId(), isNull);
    await repo.setCalendarIntegrationEnabled(enabled: false);
    expect(await repo.getCalendarIntegrationEnabled(), isFalse);
  });

  test('a task keeps its calendar event link until it is forgotten', () async {
    expect(await repo.getTaskEventLink('t1'), isNull);

    await repo.setTaskEventLink('t1', '77');
    await repo.setTaskEventLink('t2', '88');

    expect(await repo.getTaskEventLink('t1'), '77');
    expect(await repo.getTaskEventLink('t2'), '88');

    await repo.setTaskEventLink('t1', null);
    expect(await repo.getTaskEventLink('t1'), isNull);
    expect(await repo.getTaskEventLink('t2'), '88');
  });

  test('listRules returns the saved apps with their labels', () async {
    await repo.addRule('com.chat', appLabel: 'Chat');
    await repo.addRule('com.mail');

    final rules = await repo.listRules();
    expect(rules.map((r) => r.packageName).toSet(), <String>{
      'com.chat',
      'com.mail',
    });
    expect(rules.firstWhere((r) => r.packageName == 'com.chat').label, 'Chat');
    expect(
      rules.firstWhere((r) => r.packageName == 'com.mail').displayName,
      'com.mail',
    );
  });
}
