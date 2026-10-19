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

  /// The app language: `system` (follow the device, default), `en` or `fa`.
  Future<String> getLanguage();

  /// The theme: `system` (follow the device, default), `light` or `dark`.
  Future<String> getThemeMode();

  /// Whether the user turned on showing the device's calendars.
  Future<bool> getCalendarIntegrationEnabled();

  Future<void> setCalendarIntegrationEnabled({required bool enabled});

  /// The calendars the user chose to show, or null when no choice was made
  /// yet (then the ones the device's calendar app shows are used).
  Future<Set<String>?> getVisibleCalendarIds();

  Future<void> setVisibleCalendarIds(Set<String> ids);

  /// The calendar new events are saved to, or null when none was chosen.
  Future<String?> getDefaultCalendarId();

  Future<void> setDefaultCalendarId(String? id);

  Future<void> setThemeMode(String mode);

  Future<void> setLanguage(String language);

  Future<void> setCalendarSystemId(String id);

  Future<void> setRetentionDays(int? days);
}
