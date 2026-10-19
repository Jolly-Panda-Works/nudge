import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/application/events_by_day.dart';

import '../support/fake_calendar_platform.dart';

void main() {
  test('an event is placed on its day', () {
    final days = groupEventsByDay([
      event('a', start: DateTime(2026, 10, 18, 10)),
    ]);

    expect(days.keys, <DateTime>[DateTime(2026, 10, 18)]);
    expect(days[DateTime(2026, 10, 18)]!.single.eventId, 'a');
  });

  test('an event over midnight appears on both days', () {
    final days = groupEventsByDay([
      event(
        'night',
        start: DateTime(2026, 10, 18, 22),
        end: DateTime(2026, 10, 19, 2),
      ),
    ]);

    expect(days.keys.toSet(), <DateTime>{
      DateTime(2026, 10, 18),
      DateTime(2026, 10, 19),
    });
  });

  test('an event that ends at midnight does not touch the next day', () {
    final days = groupEventsByDay([
      event(
        'late',
        start: DateTime(2026, 10, 18, 22),
        end: DateTime(2026, 10, 19),
      ),
    ]);

    expect(days.keys, <DateTime>[DateTime(2026, 10, 18)]);
  });

  test('a one-day all-day event covers exactly its day', () {
    final days = groupEventsByDay([
      event(
        'holiday',
        start: DateTime(2026, 10, 20),
        end: DateTime(2026, 10, 21),
        allDay: true,
      ),
    ]);

    expect(days.keys, <DateTime>[DateTime(2026, 10, 20)]);
  });

  test('a multi-day all-day event covers every day', () {
    final days = groupEventsByDay([
      event(
        'trip',
        start: DateTime(2026, 10, 20),
        end: DateTime(2026, 10, 23),
        allDay: true,
      ),
    ]);

    expect(days.keys.toSet(), <DateTime>{
      DateTime(2026, 10, 20),
      DateTime(2026, 10, 21),
      DateTime(2026, 10, 22),
    });
  });

  test('a very long event is capped', () {
    final days = groupEventsByDay([
      event(
        'year',
        start: DateTime(2026, 1, 1),
        end: DateTime(2027, 1, 1),
        allDay: true,
      ),
    ], maxDays: 10);

    expect(days, hasLength(10));
  });

  test('an event without a length stays on its day', () {
    final at = DateTime(2026, 10, 18, 10);
    final days = groupEventsByDay([event('x', start: at, end: at)]);

    expect(days.keys, <DateTime>[DateTime(2026, 10, 18)]);
  });

  test('all-day events come first, then by start, then by title', () {
    final days = groupEventsByDay([
      event('b', title: 'B', start: DateTime(2026, 10, 18, 9)),
      event('c', title: 'C', start: DateTime(2026, 10, 18, 8)),
      event('a', title: 'A', start: DateTime(2026, 10, 18, 9)),
      event(
        'd',
        title: 'D',
        start: DateTime(2026, 10, 18),
        end: DateTime(2026, 10, 19),
        allDay: true,
      ),
    ]);

    expect(
      days[DateTime(2026, 10, 18)]!.map((e) => e.title),
      <String>['D', 'C', 'A', 'B'],
    );
  });
}
