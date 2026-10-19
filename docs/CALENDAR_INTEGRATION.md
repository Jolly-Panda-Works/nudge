# Device calendars (Android Calendar Provider)

Android keeps the calendars of every account the user added (Google, Samsung and others) in the **Calendar Provider**. Nudge reads them through `CalendarContract`; it does not talk to Google or Samsung servers and needs no account of its own. This is the first integration path (M4); direct Google Calendar access is a later, optional step (M6).

## What exists (0.15.0, section 1)
- **Settings > Calendars**: a switch "Show device calendars". It is off by default.
- **Permission only on demand**: `READ_CALENDAR` and `WRITE_CALENDAR` are declared in the manifest, but the system dialog is shown only when the user turns the switch on. Nothing is read while it is off. If the user refuses, the screen says so and links to the app's system settings; if the permission is later taken away, the screen shows a warning.
- **Discovery**: every calendar the provider exposes, grouped by account (kind: Google, Samsung, Device or the raw account type; and the account name), with its colour, whether it is **read only**, whether it is the account's own calendar and whether the device's calendar app shows it.
- **Choices**: which calendars Nudge shows (until the user chooses, the ones the device's calendar app shows) and which writable calendar new events are saved to (until chosen: the first own writable calendar). Both are stored in the settings table (`calendar_integration`, `calendar_visible_ids`, `calendar_default_id`). A read-only calendar can never be the default.
- **Provider abstraction**: `CalendarPlatform` (method channel on Android, no-op elsewhere, fake in tests) and `CalendarIntegration` (the rules above), both with tests.

## What does not exist yet
- Showing the calendars' events in the calendar views, and telling them apart from tasks and reminders (section 2).
- Creating, editing or deleting events, and linking a task to an event without creating duplicates (section 3).
- Windows: there is no calendar provider; external calendars on Windows will only come through a documented provider (M5/M6).

## Privacy
Calendar names and account names are shown on screen and are never logged or exported. Only calendar ids are stored (to remember the choices). Event content is not read in this section.

## Verify on devices (not done)
- A phone with a Google account and one with a Samsung account (with Samsung Calendar): both appear? Are Samsung's own calendars (for example "My calendar") listed and writable?
- Accounts that are synced but whose calendars are hidden in the device's calendar app: do they appear with the right visibility?
- Refuse the permission, allow it later from the system settings, and take it away again while the app runs.
- Work profiles and managed accounts may hide calendars from the provider.
