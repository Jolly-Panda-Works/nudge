import '../domain/external_calendar.dart';
import '../domain/external_event.dart';
import 'calendar_platform.dart';

/// Used on platforms without a calendar provider (for example Windows).
final class NoopCalendarPlatform implements CalendarPlatform {
  const NoopCalendarPlatform();

  @override
  bool get isSupported => false;

  @override
  Future<CalendarPermissions> permissions() async => CalendarPermissions.none;

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<bool> openAppSettings() async => false;

  @override
  Future<List<ExternalCalendar>> listCalendars() async =>
      const <ExternalCalendar>[];

  @override
  Future<List<ExternalEvent>> listEvents({
    required DateTime from,
    required DateTime to,
    required Set<String> calendarIds,
  }) async => const <ExternalEvent>[];

  @override
  Future<bool> openEvent(ExternalEvent event) async => false;
}
