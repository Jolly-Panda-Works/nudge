import '../domain/event_draft.dart';
import '../domain/external_calendar.dart';
import '../domain/external_event.dart';

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

  /// The occurrences of events in the calendars [calendarIds] that overlap
  /// [from, to). Recurring events are expanded. Throws
  /// [CalendarPlatformException] when they cannot be read.
  Future<List<ExternalEvent>> listEvents({
    required DateTime from,
    required DateTime to,
    required Set<String> calendarIds,
  });

  /// Opens the event in the device's calendar app. False when it cannot be.
  Future<bool> openEvent(ExternalEvent event);

  /// Saves a new event and returns its id. Throws
  /// [CalendarPlatformException] (`permission_denied` or `write_failed`).
  Future<String> createEvent(EventDraft draft);

  /// Changes an event. False when it no longer exists.
  Future<bool> updateEvent(String eventId, EventDraft draft);

  /// Deletes an event. False when it no longer exists.
  Future<bool> deleteEvent(String eventId);

  /// True while the event is still in its calendar.
  Future<bool> eventExists(String eventId);
}
