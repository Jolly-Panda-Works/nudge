# Device calendars (Android Calendar Provider)

Android keeps the calendars of every account the user added (Google, Samsung and others) in the **Calendar Provider**. Nudge reads them through `CalendarContract`; it does not talk to Google or Samsung servers and needs no account of its own. This is the first integration path (M4); direct Google Calendar access is a later, optional step (M6).

## What exists (0.15.0 and 0.16.0)
- **Settings > Calendars**: a switch "Show device calendars". It is off by default.
- **Permission only on demand**: `READ_CALENDAR` and `WRITE_CALENDAR` are declared in the manifest, but the system dialog is shown only when the user turns the switch on. Nothing is read while it is off. If the user refuses, the screen says so and links to the app's system settings; if the permission is later taken away, the screen shows a warning.
- **Discovery**: every calendar the provider exposes, grouped by account (kind: Google, Samsung, Device or the raw account type; and the account name), with its colour, whether it is **read only**, whether it is the account's own calendar and whether the device's calendar app shows it.
- **Choices**: which calendars Nudge shows (until the user chooses, the ones the device's calendar app shows) and which writable calendar new events are saved to (until chosen: the first own writable calendar). Both are stored in the settings table (`calendar_integration`, `calendar_visible_ids`, `calendar_default_id`). A read-only calendar can never be the default.
- **Provider abstraction**: `CalendarPlatform` (method channel on Android, no-op elsewhere, fake in tests) and `CalendarIntegration` (the rules above), both with tests.

## Events in the calendar views (0.16.0, section 2)
- The events of the **shown** calendars appear in the month, week, day and agenda views. Recurring events are expanded by the provider (`CalendarContract.Instances`), so every occurrence shows. Only the range on screen is read (plus a day on each side), again after changing the month, week or day and when the app returns to the front.
- **Telling events from tasks:** an event has a coloured calendar icon (the calendar's colour) and its calendar's name; a task has a check or an alarm icon. In the month grid tasks are round dots and events are small squares in the calendar's colour. In the day and agenda lists events come first.
- **Time:** an event over midnight appears on each day it covers; an event ending exactly at midnight does not appear on the next day. All-day events are stored by Android as UTC midnights; they are shown on the local day with the same date, in an "All day" block at the top of the day view.
- **Details:** tapping an event shows its calendar and time, with "Open in calendar app" (the device's own calendar app shows the full event). Editing is not possible yet.
- If the provider fails, a line says so and tasks still work; with the integration off, unsupported or not allowed, nothing is read.
- Limits: at most 3000 occurrences per read; an event spanning more than 31 days is shown on its first 31 days.

## Creating and changing events (0.17.0, section 3)
- **New event:** on the Calendar screen the `+` button offers *New task* or *New event* when device calendars are available. An event has a title, a calendar (only writable ones are offered; the default is the one chosen in Settings > Calendars), an all-day switch and start and end dates and times. It is written to the Calendar Provider, so the account's own sync sends it on.
- **Edit and delete:** tapping an event shows *Edit* and *Delete* when its calendar accepts changes and the event does not repeat. The calendar of an event cannot be changed. Deleting asks first.
- **Repeating events** are never changed by Nudge (changing one occurrence or the whole series is easy to get wrong); the details say so and offer "Open in calendar app". **Read-only calendars** (holidays, subscribed) only show.
- **Tasks:** a task with a date and time has *Add to calendar* in its details. It creates a one-hour event with the task's title and notes in the default calendar and remembers the link (settings key `task_event:<task id>`), so the same task is never added twice. If the event is later deleted in a calendar app, the link is forgotten and the task can be added again. Deleting the task forgets the link and leaves the event.
- **Times:** timed events are written as instants in the device's time zone; all-day events as UTC midnights with the UTC zone (the way Android stores them), the end being the midnight after the last day.
- **Safety rules in code:** nothing is written while the integration is off or the write permission is missing; a calendar is checked to be writable before every write; an invalid draft (empty title, end not after the start) is refused before anything is sent.
- Not done: reminders/alerts and guests on events, choosing a different calendar for an existing event, editing repeating events, showing the task link on the event, and updating the event when the task changes.

## What does not exist yet
- Windows: there is no calendar provider; external calendars on Windows will only come through a documented provider (M5/M6).

## Privacy
Calendar names and account names are shown on screen and are never logged or exported. Only calendar ids are stored (to remember the choices). Since 0.16.0 the title, time and calendar of the events in the range on screen are read into memory to be shown; they are not stored, logged or exported, and event locations, notes and attendees are not read. Since 0.17.0 Nudge writes events the user creates or edits, and stores only the id of the event a task was added to.

## Verify on devices (not done)
- A phone with a Google account and one with a Samsung account (with Samsung Calendar): both appear? Are Samsung's own calendars (for example "My calendar") listed and writable?
- Accounts that are synced but whose calendars are hidden in the device's calendar app: do they appear with the right visibility?
- Refuse the permission, allow it later from the system settings, and take it away again while the app runs.
- Work profiles and managed accounts may hide calendars from the provider.
