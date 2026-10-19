/// One occurrence of an event of a device calendar. A recurring event gives
/// one [ExternalEvent] per occurrence in the range that was asked for.
final class ExternalEvent {
  const ExternalEvent({
    required this.eventId,
    required this.calendarId,
    required this.title,
    required this.start,
    required this.end,
    required this.allDay,
    this.color,
    this.calendarLabel = '',
  });

  /// The provider's id of the event (the same for every occurrence).
  final String eventId;
  final String calendarId;

  /// May be empty; screens show a placeholder.
  final String title;

  /// For a timed event, the start instant. For an all-day event, the local
  /// midnight of its first day.
  final DateTime start;

  /// The end instant (exclusive). For an all-day event, the local midnight
  /// after its last day.
  final DateTime end;
  final bool allDay;

  /// Colour as ARGB, or null when the provider gave none.
  final int? color;

  /// The name of the calendar it belongs to (filled in by the app).
  final String calendarLabel;

  /// Identifies this occurrence (event and start).
  String get key => '$eventId@${start.millisecondsSinceEpoch}';

  ExternalEvent withCalendarLabel(String label) => ExternalEvent(
    eventId: eventId,
    calendarId: calendarId,
    title: title,
    start: start,
    end: end,
    allDay: allDay,
    color: color,
    calendarLabel: label,
  );
}
