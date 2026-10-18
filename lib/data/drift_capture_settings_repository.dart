import 'package:drift/drift.dart';

import '../domain/capture_settings_repository.dart';
import '../domain/ingest_policy.dart';
import '../domain/source_app.dart';
import 'database/app_database.dart';

final class DriftCaptureSettingsRepository
    implements CaptureSettingsRepository {
  DriftCaptureSettingsRepository(this._db);

  final AppDatabase _db;

  static const _kMode = 'filter_mode';
  static const _kOngoing = 'capture_ongoing';
  static const _kGroupSummaries = 'capture_group_summaries';
  static const _kRetentionDays = 'retention_days';
  static const _kCalendarSystem = 'calendar_system';
  static const _kLanguage = 'language';
  static const _kThemeMode = 'theme_mode';

  Future<String?> _read(String name) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.settingName.equals(name))).getSingleOrNull();
    return row?.settingValue;
  }

  Future<void> _write(String name, String value) {
    return _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion(
            settingName: Value(name),
            settingValue: Value(value),
          ),
        );
  }

  Future<void> _remove(String name) async {
    await (_db.delete(
      _db.appSettings,
    )..where((t) => t.settingName.equals(name))).go();
  }

  @override
  Future<CapturePolicy> loadPolicy({String? ownPackageName}) async {
    final mode = FilterMode.values.asNameMap()[await _read(_kMode)];
    final rules = await _db.select(_db.sourceRules).get();
    return CapturePolicy(
      mode: mode ?? FilterMode.off,
      packages: {for (final rule in rules) rule.packageName},
      ownPackageName: ownPackageName,
      captureOngoing: await _read(_kOngoing) == 'true',
      captureGroupSummaries: await _read(_kGroupSummaries) == 'true',
    );
  }

  @override
  Future<void> setMode(FilterMode mode) => _write(_kMode, mode.name);

  @override
  Future<void> addRule(String packageName, {String? appLabel}) {
    return _db
        .into(_db.sourceRules)
        .insertOnConflictUpdate(
          SourceRulesCompanion(
            packageName: Value(packageName),
            appLabel: Value(appLabel),
          ),
        );
  }

  @override
  Future<void> removeRule(String packageName) async {
    await (_db.delete(
      _db.sourceRules,
    )..where((t) => t.packageName.equals(packageName))).go();
  }

  @override
  Future<void> setCaptureOngoing({required bool value}) =>
      _write(_kOngoing, value.toString());

  @override
  Future<void> setCaptureGroupSummaries({required bool value}) =>
      _write(_kGroupSummaries, value.toString());

  @override
  Future<String> getThemeMode() async {
    final raw = await _read(_kThemeMode);
    return raw == 'light' || raw == 'dark' ? raw! : 'system';
  }

  @override
  Future<void> setThemeMode(String mode) => _write(
    _kThemeMode,
    mode == 'light' || mode == 'dark' ? mode : 'system',
  );

  @override
  Future<String> getLanguage() async {
    final raw = await _read(_kLanguage);
    return raw == 'en' || raw == 'fa' ? raw! : 'system';
  }

  @override
  Future<void> setLanguage(String language) => _write(
    _kLanguage,
    language == 'en' || language == 'fa' ? language : 'system',
  );

  @override
  Future<String> getCalendarSystemId() async {
    final raw = await _read(_kCalendarSystem);
    return raw == 'gregorian' ? 'gregorian' : 'jalali';
  }

  @override
  Future<void> setCalendarSystemId(String id) =>
      _write(_kCalendarSystem, id == 'gregorian' ? 'gregorian' : 'jalali');

  @override
  Future<int?> getRetentionDays() async {
    final raw = await _read(_kRetentionDays);
    return raw == null ? null : int.tryParse(raw);
  }

  @override
  Future<void> setRetentionDays(int? days) {
    return days == null
        ? _remove(_kRetentionDays)
        : _write(_kRetentionDays, days.toString());
  }

  @override
  Future<List<SourceApp>> listRules() async {
    final rows = await _db.select(_db.sourceRules).get();
    return [
      for (final row in rows)
        SourceApp(packageName: row.packageName, label: row.appLabel),
    ];
  }
}
