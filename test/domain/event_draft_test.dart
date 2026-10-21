import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/domain/event_draft.dart';

EventDraft draft({
  String title = 'Meeting',
  required DateTime start,
  required DateTime end,
  bool allDay = false,
}) => EventDraft(
  calendarId: '1',
  title: title,
  start: start,
  end: end,
  allDay: allDay,
);

void main() {
  test('a timed event needs a title and an end after the start', () {
    final ok = draft(
      start: DateTime(2026, 10, 18, 9),
      end: DateTime(2026, 10, 18, 10),
    );
    expect(ok.problem, isNull);
    expect(ok.isValid, isTrue);

    expect(
      draft(
        title: '   ',
        start: DateTime(2026, 10, 18, 9),
        end: DateTime(2026, 10, 18, 10),
      ).problem,
      'title',
    );
    expect(
      draft(
        start: DateTime(2026, 10, 18, 9),
        end: DateTime(2026, 10, 18, 9),
      ).problem,
      'range',
    );
    expect(
      draft(
        start: DateTime(2026, 10, 18, 10),
        end: DateTime(2026, 10, 18, 9),
      ).problem,
      'range',
    );
  });

  test('an all-day event may end on its first day, not before it', () {
    expect(
      draft(
        start: DateTime(2026, 10, 18),
        end: DateTime(2026, 10, 18),
        allDay: true,
      ).problem,
      isNull,
    );
    expect(
      draft(
        start: DateTime(2026, 10, 18),
        end: DateTime(2026, 10, 17),
        allDay: true,
      ).problem,
      'range',
    );
  });

  test('timed events are sent as instants', () {
    final d = draft(
      start: DateTime(2026, 10, 18, 9),
      end: DateTime(2026, 10, 18, 10),
    );
    expect(d.beginMillis, DateTime(2026, 10, 18, 9).millisecondsSinceEpoch);
    expect(d.endMillis, DateTime(2026, 10, 18, 10).millisecondsSinceEpoch);
  });

  test('all-day events are sent as UTC midnights, the end after the last day', () {
    final d = draft(
      start: DateTime(2026, 10, 20),
      end: DateTime(2026, 10, 22),
      allDay: true,
    );
    expect(d.beginMillis, DateTime.utc(2026, 10, 20).millisecondsSinceEpoch);
    expect(d.endMillis, DateTime.utc(2026, 10, 23).millisecondsSinceEpoch);
  });

  test('the end of an all-day event at a month end rolls over', () {
    final d = draft(
      start: DateTime(2026, 10, 31),
      end: DateTime(2026, 10, 31),
      allDay: true,
    );
    expect(d.endMillis, DateTime.utc(2026, 11, 1).millisecondsSinceEpoch);
  });

  test('the title is trimmed', () {
    expect(
      draft(
        title: '  Lunch  ',
        start: DateTime(2026, 10, 18, 12),
        end: DateTime(2026, 10, 18, 13),
      ).cleanTitle,
      'Lunch',
    );
  });
}
