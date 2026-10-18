# Calendar design

## Decision: custom calendar widgets, no calendar library
M3 started with the question "library or custom". The choice is **custom**, for these reasons:

- **Jalali and right-to-left are the core requirement.** The common Flutter calendar packages are built around the Gregorian calendar; adding Jalali means wrapping or forking them, and their layout, gestures and accessibility could not be fixed from outside.
- **No new dependency to trust.** Every dependency is pinned to an exact version and this project cannot look up or verify new packages in its build environment. The date math is small and fully testable, so it is written in the project instead.
- **Design freedom.** The calendar is meant to be a pleasure to use and original in design; a generic default widget is not the finished UI (see ROADMAP).

This can be revisited if a package turns out to solve a concrete problem better (for example virtualized scrolling of many months).

## Layers
| Layer | Files | State |
|---|---|---|
| Date math | `lib/domain/calendar/jalali_calendar.dart`, `gregorian_calendar.dart`, `calendar_system.dart`, `calendar_date.dart` | Written, with tests |
| Month layout | `lib/domain/calendar/month_grid.dart` | Written, with tests |
| Names and digits (Persian and English) | `lib/domain/calendar/calendar_names.dart` | Written, with tests |
| Month, week, day and agenda views, the shell, themes | `lib/ui/...` | Not started |
| Localization of the whole app | | Not started |

## Rules
- **Stored data never depends on the calendar system.** Tasks, reminders and external events store instants (UTC). A `CalendarSystem` only names and lays out local days.
- **External calendars always get Gregorian dates.** Every conversion goes through `CalendarSystem.fromDate` / `toDate`.
- **Jalali accuracy.** The arithmetic is a port of the `jalaali-js` algorithm. Before it was written in Dart, the same algorithm was compared with an independent library (`jdatetime`) for every day from 1 Farvardin 1178 (1799-03-21) to 29 Esfand 1632 (2254-03-20): zero differences. The Dart tests repeat the round trip over the same range and check known dates.
- **Supported years:** Jalali 1178 to 1632 (Gregorian 1799 to 2254). Outside it the conversions throw `RangeError`; the UI must keep navigation inside it.
- **Week start:** Saturday for Jalali, Monday for Gregorian, both overridable in `MonthGrid.build`.
- **Official holidays and the Iranian "official" calendar** (which can differ from the astronomical one by a day in rare cases) are not part of this layer.
