import '../domain/external_event.dart';

/// Groups event occurrences by the local days they cover. An event that runs
/// over several days appears on each of them (up to [maxDays]); one that ends
/// exactly at midnight does not appear on the day it ends on. Inside a day,
/// all-day events come first, then timed events by start, then by title.
Map<DateTime, List<ExternalEvent>> groupEventsByDay(
  Iterable<ExternalEvent> events, {
  int maxDays = 31,
}) {
  final days = <DateTime, List<ExternalEvent>>{};
  for (final event in events) {
    final first = DateTime(
      event.start.year,
      event.start.month,
      event.start.day,
    );
    final lastInstant = event.end.isAfter(event.start)
        ? event.end.subtract(const Duration(milliseconds: 1))
        : event.start;
    final last = DateTime(lastInstant.year, lastInstant.month, lastInstant.day);
    var day = first;
    var count = 0;
    while (!day.isAfter(last) && count < maxDays) {
      days.putIfAbsent(day, () => <ExternalEvent>[]).add(event);
      day = DateTime(day.year, day.month, day.day + 1);
      count++;
    }
  }
  for (final list in days.values) {
    list.sort((a, b) {
      if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
      final byStart = a.start.compareTo(b.start);
      return byStart != 0 ? byStart : a.title.compareTo(b.title);
    });
  }
  return days;
}
