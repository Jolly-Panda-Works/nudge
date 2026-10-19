import 'package:nudge/domain/external_calendar.dart';
import 'package:nudge/domain/external_event.dart';
import 'package:nudge/platform/calendar_platform.dart';

ExternalCalendar calendar(
  String id, {
  String name = 'Personal',
  String account = 'me@example.com',
  String type = 'com.google',
  bool canWrite = true,
  bool isOwner = true,
  bool visible = true,
  int? color = 0xFF2196F3,
}) {
  return ExternalCalendar(
    id: id,
    displayName: name,
    accountName: account,
    accountType: type,
    canWrite: canWrite,
    isOwner: isOwner,
    visibleInProvider: visible,
    color: color,
  );
}

ExternalEvent event(
  String id, {
  String calendarId = '1',
  String title = 'Meeting',
  required DateTime start,
  DateTime? end,
  bool allDay = false,
  int? color,
}) {
  return ExternalEvent(
    eventId: id,
    calendarId: calendarId,
    title: title,
    start: start,
    end: end ?? start.add(const Duration(hours: 1)),
    allDay: allDay,
    color: color,
  );
}

/// In-memory stand-in for the device's calendar provider.
class FakeCalendarPlatform implements CalendarPlatform {
  bool supported = true;
  CalendarPermissions granted = CalendarPermissions.none;

  /// When true, the user "allows" the permission as soon as it is requested.
  bool allowOnRequest = false;
  List<ExternalCalendar> calendars = <ExternalCalendar>[];
  bool listFails = false;
  int permissionRequests = 0;
  int settingsOpens = 0;
  int listCalls = 0;
  List<ExternalEvent> events = <ExternalEvent>[];
  bool eventsFail = false;
  final List<Set<String>> eventQueries = <Set<String>>[];
  final List<ExternalEvent> opened = <ExternalEvent>[];

  @override
  bool get isSupported => supported;

  @override
  Future<CalendarPermissions> permissions() async => granted;

  @override
  Future<bool> requestPermissions() async {
    permissionRequests++;
    if (granted.read) return true;
    if (allowOnRequest) {
      granted = const CalendarPermissions(read: true, write: true);
    }
    // Like the real platform: the dialog was shown, the answer comes later.
    return false;
  }

  @override
  Future<bool> openAppSettings() async {
    settingsOpens++;
    return true;
  }

  @override
  Future<List<ExternalCalendar>> listCalendars() async {
    listCalls++;
    if (listFails) throw const CalendarPlatformException('query_failed');
    return List<ExternalCalendar>.of(calendars);
  }

  @override
  Future<List<ExternalEvent>> listEvents({
    required DateTime from,
    required DateTime to,
    required Set<String> calendarIds,
  }) async {
    eventQueries.add(Set<String>.of(calendarIds));
    if (eventsFail) throw const CalendarPlatformException('query_failed');
    return <ExternalEvent>[
      for (final e in events)
        if (calendarIds.contains(e.calendarId) &&
            e.start.isBefore(to) &&
            e.end.isAfter(from))
          e,
    ];
  }

  @override
  Future<bool> openEvent(ExternalEvent event) async {
    opened.add(event);
    return true;
  }
}
