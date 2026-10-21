/// What the user entered for a new or edited calendar event.
///
/// For a timed event [start] and [end] are instants and [end] must be after
/// [start]. For an all-day event [start] and [end] are local midnights of the
/// first and the **last** day (inclusive), and [end] must not be before
/// [start].
final class EventDraft {
  const EventDraft({
    required this.calendarId,
    required this.title,
    required this.start,
    required this.end,
    required this.allDay,
    this.notes,
  });

  final String calendarId;
  final String title;
  final String? notes;
  final DateTime start;
  final DateTime end;
  final bool allDay;

  /// The title without surrounding spaces.
  String get cleanTitle => title.trim();

  /// Null when the draft can be saved, otherwise what is wrong:
  /// `title` (empty) or `range` (the end is not after the start).
  String? get problem {
    if (cleanTitle.isEmpty) return 'title';
    if (allDay) {
      final first = DateTime(start.year, start.month, start.day);
      final last = DateTime(end.year, end.month, end.day);
      return last.isBefore(first) ? 'range' : null;
    }
    return end.isAfter(start) ? null : 'range';
  }

  bool get isValid => problem == null;

  /// The first instant of an all-day event as Android stores it (UTC
  /// midnight) or the start instant of a timed one.
  int get beginMillis => allDay
      ? DateTime.utc(start.year, start.month, start.day).millisecondsSinceEpoch
      : start.millisecondsSinceEpoch;

  /// The end instant (exclusive). For an all-day event, the UTC midnight
  /// after the last day.
  int get endMillis => allDay
      ? DateTime.utc(
          end.year,
          end.month,
          end.day + 1,
        ).millisecondsSinceEpoch
      : end.millisecondsSinceEpoch;
}
