import '../domain/capture_settings_repository.dart';
import '../domain/event_draft.dart';
import '../domain/external_calendar.dart';
import '../domain/external_event.dart';
import '../domain/task.dart';
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

/// Why a change to the device calendars was not made.
enum CalendarWriteProblem {
  /// The integration is off.
  notEnabled,

  /// The calendar permission (or its write part) is missing.
  noWritePermission,

  /// There is no calendar that accepts new events (none chosen, or all are
  /// read only).
  noWritableCalendar,

  /// The calendar of the event does not accept changes.
  readOnly,

  /// A repeating event: edited in the calendar app.
  recurring,

  /// The task has no time to put in a calendar.
  noTime,

  /// The provider refused or failed.
  failed,
}

final class CalendarWriteException implements Exception {
  const CalendarWriteException(this.problem);

  final CalendarWriteProblem problem;

  @override
  String toString() => 'CalendarWriteException($problem)';
}

/// What adding a task to the calendar did.
enum AddToCalendarResult {
  /// A new event was created.
  added,

  /// The task already has its event; nothing new was created.
  alreadyAdded,
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
    final visible = await _visibleIds(calendars);
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

  /// The stored choice (only calendars that still exist), or, when nothing
  /// was chosen, the calendars the device's calendar app shows.
  Future<Set<String>> _visibleIds(List<ExternalCalendar> calendars) async {
    final stored = await _settings.getVisibleCalendarIds();
    if (stored != null) {
      return stored.intersection(<String>{for (final c in calendars) c.id});
    }
    return <String>{
      for (final c in calendars)
        if (c.visibleInProvider) c.id,
    };
  }

  /// The occurrences of events in the shown calendars that overlap
  /// [from, to). Empty while the integration is off, unsupported or not
  /// allowed. Throws [CalendarPlatformException] when the provider fails.
  Future<List<ExternalEvent>> events({
    required DateTime from,
    required DateTime to,
  }) async {
    if (!_platform.isSupported) return const <ExternalEvent>[];
    if (!await _settings.getCalendarIntegrationEnabled()) {
      return const <ExternalEvent>[];
    }
    if (!(await _platform.permissions()).read) return const <ExternalEvent>[];
    final calendars = await _platform.listCalendars();
    final visible = await _visibleIds(calendars);
    if (visible.isEmpty) return const <ExternalEvent>[];
    final byId = <String, ExternalCalendar>{for (final c in calendars) c.id: c};
    // A day of padding on both sides: all-day events are stored in UTC.
    final found = await _platform.listEvents(
      from: from.subtract(const Duration(days: 1)),
      to: to.add(const Duration(days: 1)),
      calendarIds: visible,
    );
    return <ExternalEvent>[
      for (final event in found)
        event.withCalendar(
          label: byId[event.calendarId]?.label ?? '',
          canWrite: byId[event.calendarId]?.canWrite ?? false,
        ),
    ];
  }

  /// Opens an event in the device's calendar app.
  Future<bool> openEvent(ExternalEvent event) => _platform.openEvent(event);

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

  // ---------------------------------------------------------------- writing

  /// The calendar if it exists, is shown to be writable and the permission to
  /// write is granted; otherwise throws the matching problem.
  Future<ExternalCalendar> _writableCalendar(String calendarId) async {
    if (!_platform.isSupported ||
        !await _settings.getCalendarIntegrationEnabled()) {
      throw const CalendarWriteException(CalendarWriteProblem.notEnabled);
    }
    final permissions = await _platform.permissions();
    if (!permissions.read || !permissions.write) {
      throw const CalendarWriteException(
        CalendarWriteProblem.noWritePermission,
      );
    }
    final List<ExternalCalendar> calendars;
    try {
      calendars = await _platform.listCalendars();
    } on CalendarPlatformException {
      throw const CalendarWriteException(CalendarWriteProblem.failed);
    }
    for (final c in calendars) {
      if (c.id == calendarId) {
        if (!c.canWrite) {
          throw const CalendarWriteException(CalendarWriteProblem.readOnly);
        }
        return c;
      }
    }
    throw const CalendarWriteException(CalendarWriteProblem.noWritableCalendar);
  }

  /// Runs a platform write and turns its failures into a problem.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on CalendarPlatformException catch (error) {
      throw CalendarWriteException(
        error.code == 'permission_denied'
            ? CalendarWriteProblem.noWritePermission
            : CalendarWriteProblem.failed,
      );
    }
  }

  /// Saves a new event and returns its id.
  Future<String> createEvent(EventDraft draft) async {
    if (!draft.isValid)
      throw ArgumentError.value(draft, 'draft', draft.problem);
    await _writableCalendar(draft.calendarId);
    return _guard(() => _platform.createEvent(draft));
  }

  /// Changes an event (not a repeating one). The calendar cannot be changed.
  Future<void> updateEvent(ExternalEvent event, EventDraft draft) async {
    if (!draft.isValid)
      throw ArgumentError.value(draft, 'draft', draft.problem);
    if (event.recurring) {
      throw const CalendarWriteException(CalendarWriteProblem.recurring);
    }
    await _writableCalendar(event.calendarId);
    final changed = await _guard(
      () => _platform.updateEvent(
        event.eventId,
        EventDraft(
          calendarId: event.calendarId,
          title: draft.title,
          notes: draft.notes,
          start: draft.start,
          end: draft.end,
          allDay: draft.allDay,
        ),
      ),
    );
    if (!changed)
      throw const CalendarWriteException(CalendarWriteProblem.failed);
  }

  /// Deletes an event (not a repeating one).
  Future<void> deleteEvent(ExternalEvent event) async {
    if (event.recurring) {
      throw const CalendarWriteException(CalendarWriteProblem.recurring);
    }
    await _writableCalendar(event.calendarId);
    final deleted = await _guard(() => _platform.deleteEvent(event.eventId));
    if (!deleted)
      throw const CalendarWriteException(CalendarWriteProblem.failed);
  }

  // ------------------------------------------------------------ task links

  /// True when the task already has an event that still exists. A link to an
  /// event that was deleted is forgotten.
  Future<bool> isTaskInCalendar(String taskId) async {
    final eventId = await _settings.getTaskEventLink(taskId);
    if (eventId == null) return false;
    if (!_platform.isSupported) return true;
    try {
      if (await _platform.eventExists(eventId)) return true;
    } on CalendarPlatformException {
      // Cannot tell (for example no permission): keep the link.
      return true;
    }
    await _settings.setTaskEventLink(taskId, null);
    return false;
  }

  /// Puts a task with a time into the default calendar, one hour long (an
  /// event of the same title, with the task's notes). A task that already has
  /// its event is not added twice.
  Future<AddToCalendarResult> addTaskToCalendar(TaskItem task) async {
    final at = task.remindAt;
    if (at == null) {
      throw const CalendarWriteException(CalendarWriteProblem.noTime);
    }
    if (await isTaskInCalendar(task.id))
      return AddToCalendarResult.alreadyAdded;
    final state = await load();
    final calendarId = state.defaultId;
    if (calendarId == null) {
      throw const CalendarWriteException(
        CalendarWriteProblem.noWritableCalendar,
      );
    }
    final id = await createEvent(
      EventDraft(
        calendarId: calendarId,
        title: task.title,
        notes: task.notes,
        start: at.toLocal(),
        end: at.toLocal().add(const Duration(hours: 1)),
        allDay: false,
      ),
    );
    await _settings.setTaskEventLink(task.id, id);
    return AddToCalendarResult.added;
  }

  /// Forgets the link of a task (when the task is deleted). The event stays.
  Future<void> forgetTaskLink(String taskId) =>
      _settings.setTaskEventLink(taskId, null);
}
