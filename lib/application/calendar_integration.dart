import '../domain/capture_settings_repository.dart';
import '../domain/external_calendar.dart';
import '../platform/calendar_platform.dart';

/// What happened when the user asked to turn the integration on.
enum EnableOutcome {
  /// On, and the calendars can be read.
  enabled,

  /// The system permission dialog was shown. The answer arrives later: call
  /// [CalendarIntegration.completeEnable] when the app is back in front.
  permissionRequested,

  /// This platform has no calendar provider.
  unsupported,
}

/// A snapshot of the integration for the screens.
final class CalendarState {
  const CalendarState({
    required this.supported,
    required this.enabled,
    required this.permissions,
    required this.calendars,
    required this.visibleIds,
    required this.defaultId,
    this.readFailed = false,
  });

  static const CalendarState unsupportedState = CalendarState(
    supported: false,
    enabled: false,
    permissions: CalendarPermissions.none,
    calendars: <ExternalCalendar>[],
    visibleIds: <String>{},
    defaultId: null,
  );

  final bool supported;

  /// The user's switch.
  final bool enabled;
  final CalendarPermissions permissions;

  /// Empty unless the integration is on and reading is allowed.
  final List<ExternalCalendar> calendars;

  /// The ids of the calendars shown (already resolved: the stored choice, or
  /// the ones the device's calendar app shows when nothing was chosen).
  final Set<String> visibleIds;

  /// The calendar new events go to (already resolved), or null.
  final String? defaultId;

  /// True when the integration is on but the permission was taken away.
  bool get permissionLost => enabled && !permissions.read;

  /// True when reading was allowed but the provider failed.
  final bool readFailed;

  bool isVisible(ExternalCalendar calendar) => visibleIds.contains(calendar.id);

  /// The calendars new events can be saved to.
  List<ExternalCalendar> get writable => <ExternalCalendar>[
    for (final c in calendars)
      if (c.canWrite) c,
  ];
}

/// Discovers the device's calendars and keeps the user's choices: whether the
/// integration is on, which calendars are shown and which one new events go
/// to. The permission is only requested when the user turns it on, and the
/// calendars are only read while it is on.
final class CalendarIntegration {
  CalendarIntegration({
    required CalendarPlatform platform,
    required CaptureSettingsRepository settings,
  }) : _platform = platform,
       _settings = settings;

  final CalendarPlatform _platform;
  final CaptureSettingsRepository _settings;

  bool get isSupported => _platform.isSupported;

  /// Reads the stored choices and, when on and allowed, the calendars.
  Future<CalendarState> load() async {
    if (!_platform.isSupported) return CalendarState.unsupportedState;
    final enabled = await _settings.getCalendarIntegrationEnabled();
    final permissions = await _platform.permissions();
    var calendars = const <ExternalCalendar>[];
    var readFailed = false;
    if (enabled && permissions.read) {
      try {
        calendars = await _platform.listCalendars();
      } on CalendarPlatformException {
        readFailed = true;
      }
    }
    final stored = await _settings.getVisibleCalendarIds();
    final visible = stored != null
        ? stored.intersection(<String>{for (final c in calendars) c.id})
        : <String>{
            for (final c in calendars)
              if (c.visibleInProvider) c.id,
          };
    final storedDefault = await _settings.getDefaultCalendarId();
    return CalendarState(
      supported: true,
      enabled: enabled,
      permissions: permissions,
      calendars: calendars,
      visibleIds: visible,
      defaultId: _resolveDefault(calendars, storedDefault),
      readFailed: readFailed,
    );
  }

  /// The stored default if it still exists and can be written to; otherwise
  /// the first writable calendar that is the account's own; otherwise null.
  static String? _resolveDefault(
    List<ExternalCalendar> calendars,
    String? stored,
  ) {
    for (final c in calendars) {
      if (c.id == stored && c.canWrite) return c.id;
    }
    for (final c in calendars) {
      if (c.canWrite && c.isOwner) return c.id;
    }
    return null;
  }

  /// Turns the integration on. Asks for the permission only now.
  Future<EnableOutcome> enable() async {
    if (!_platform.isSupported) return EnableOutcome.unsupported;
    final permissions = await _platform.permissions();
    if (!permissions.read) {
      final granted = await _platform.requestPermissions();
      if (!granted) return EnableOutcome.permissionRequested;
    }
    await _settings.setCalendarIntegrationEnabled(enabled: true);
    return EnableOutcome.enabled;
  }

  /// Finishes turning it on after the permission dialog. True when reading is
  /// now allowed (and the integration is on); false when it was refused.
  Future<bool> completeEnable() async {
    if (!_platform.isSupported) return false;
    final permissions = await _platform.permissions();
    if (!permissions.read) return false;
    await _settings.setCalendarIntegrationEnabled(enabled: true);
    return true;
  }

  /// Turns it off. The choices are kept; nothing is read any more.
  Future<void> disable() =>
      _settings.setCalendarIntegrationEnabled(enabled: false);

  Future<bool> openAppSettings() => _platform.openAppSettings();

  /// Shows or hides one calendar. The first change stores the full choice.
  Future<void> setVisible(
    CalendarState current,
    ExternalCalendar calendar, {
    required bool visible,
  }) {
    final next = Set<String>.of(current.visibleIds);
    if (visible) {
      next.add(calendar.id);
    } else {
      next.remove(calendar.id);
    }
    return _settings.setVisibleCalendarIds(next);
  }

  /// Chooses where new events are saved. Only a writable calendar is accepted.
  Future<void> setDefault(
    CalendarState current,
    ExternalCalendar? calendar,
  ) async {
    if (calendar != null && !calendar.canWrite) {
      throw ArgumentError.value(
        calendar.id,
        'calendar',
        'This calendar is read only',
      );
    }
    await _settings.setDefaultCalendarId(calendar?.id);
  }
}
