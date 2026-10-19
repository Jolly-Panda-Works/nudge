import 'package:nudge/domain/external_calendar.dart';
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
}
