import 'ingest_policy.dart';

/// Persistent capture settings (source-app rules, filters, retention).
abstract interface class CaptureSettingsRepository {
  Future<CapturePolicy> loadPolicy({String? ownPackageName});

  Future<void> setMode(FilterMode mode);

  Future<void> addRule(String packageName, {String? appLabel});

  Future<void> removeRule(String packageName);

  Future<void> setCaptureOngoing({required bool value});

  Future<void> setCaptureGroupSummaries({required bool value});

  /// Null means "keep until deleted manually".
  Future<int?> getRetentionDays();

  Future<void> setRetentionDays(int? days);
}
