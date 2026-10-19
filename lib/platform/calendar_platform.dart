import '../domain/external_calendar.dart';

/// Thrown when the calendars cannot be read (permission revoked, or the
/// provider failed).
final class CalendarPlatformException implements Exception {
  const CalendarPlatformException(this.code);

  /// `permission_denied` or `query_failed`.
  final String code;

  @override
  String toString() => 'CalendarPlatformException($code)';
}

/// Bridge to the device's calendars. Implementations: the Android method
/// channel, and a no-op for platforms without a calendar provider.
abstract interface class CalendarPlatform {
  bool get isSupported;

  Future<CalendarPermissions> permissions();

  /// True when reading is already allowed. Otherwise the system dialog is
  /// shown and false is returned; check [permissions] when the app resumes.
  Future<bool> requestPermissions();

  Future<bool> openAppSettings();

  /// Every calendar the provider exposes. Throws
  /// [CalendarPlatformException] when it cannot be read.
  Future<List<ExternalCalendar>> listCalendars();
}
