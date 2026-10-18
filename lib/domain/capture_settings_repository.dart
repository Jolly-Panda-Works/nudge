import 'ingest_policy.dart';
import 'source_app.dart';

/// Persistent capture settings (source-app rules, filters, retention).
abstract interface class CaptureSettingsRepository {
  Future<CapturePolicy> loadPolicy({String? ownPackageName});

  Future<void> setMode(FilterMode mode);

  Future<void> addRule(String packageName, {String? appLabel});

  Future<void> removeRule(String packageName);

  /// The apps currently in the allowlist/blocklist.
  Future<List<SourceApp>> listRules();

  Future<void> setCaptureOngoing({required bool value});

  Future<void> setCaptureGroupSummaries({required bool value});

  /// Null means "keep until deleted manually".
  Future<int?> getRetentionDays();

  /// The calendar system shown in the calendar: `jalali` (default) or
  /// `gregorian`.
  Future<String> getCalendarSystemId();

  Future<void> setCalendarSystemId(String id);

  Future<void> setRetentionDays(int? days);
}
