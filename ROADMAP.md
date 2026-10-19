# Roadmap

Where Nudge stands and what is left. Last updated: 2026-10-16 (version 0.6.0).

**How to read the status**

- `[x]` implemented: the code and its tests are in the repository. The CI badge in the README shows whether they currently pass.
- `[ ]` not implemented yet.
- "Not verified on a device": nothing has been run on a physical Android phone or on Windows hardware yet. Items that depend on device behavior are called out explicitly.

## Summary

| Milestone | Scope | Progress |
|---|---|---|
| M1 | Android notification capture and local inbox | All 5 sections done in code; device verification and 4 open items remain |
| M2 | Task conversion and source navigation | All 4 sections done in code; nothing compiled or verified on a device yet |
| M3 | Calendar UI with Persian (Jalali, RTL) support | In progress: sections 1 (date math), 2 (month view), 3 (week, day, agenda), 4 (Persian) and 5 (themes, wide layouts) done in code |
| M4 | Android Calendar Provider integration | Not started |
| M5 | Windows build and secure synchronization | Not started |
| M6 | Optional direct Google Calendar API integration | Not started |

Today the app captures notifications on Android, stores them locally, shows them in an inbox, lets you share or paste text into it, filter apps, export or delete your data and set a retention period. All of it exists in code, but none of it has been run on a physical device, and there are no screenshots yet.

## Done so far

| Version | Date | What was delivered |
|---|---|---|
| 0.1.0 | 2026-10-12 | M1 section 1: domain model, notification mapper, ingest/dedupe policy, unit tests, first CI |
| 0.1.1 | 2026-10-12 | Bootstrap workflow (generates `android/` and `windows/` without a local Flutter install) |
| 0.2.0 | 2026-10-12 | M1 section 2: Drift database and repositories; app renamed to Nudge; build_runner in CI |
| 0.2.1 | 2026-10-13 | Open-source project files; CI publishes a rolling `nightly` pre-release after every push to `main` |
| 0.2.2 | 2026-10-13 | Documentation in English only; this roadmap |
| 0.3.0 | 2026-10-13 | M1 section 3: Kotlin listener service, durable native queue, platform bridge, ingestion into the database, temporary status screen, wiring workflow |
| 0.4.0 | 2026-10-13 | M1 section 4: inbox, notification details, settings, app filter screen, permission banner |
| 0.5.0 | 2026-10-13 | M1 section 5: share target and text import, JSON export, per-notification and bulk delete, retention setting, logging guard test |
| 0.5.1 | 2026-10-13 | CI: builds for every branch, permanent releases from version tags, docs/RELEASING.md |
| 0.5.2 | 2026-10-14 | Fixes for the first CI analysis run, exact dependency pins, repository links |
| 0.5.3 | 2026-10-14 | Workflows rewritten: a release per push to `main`, builds independent of tests, version built into the app |
| 0.5.4 | 2026-10-14 | CI generates the Android and Windows projects when missing; one-time workflows and Dependabot removed; lock file restored |
| 0.5.5 | 2026-10-15 | Fix for the first Android compile (nested comment openers in two Kotlin files), guard test, setup-java v5 |
| 0.6.0 | 2026-10-16 | M2 section 1: tasks and reminders storage (Drift schema version 2), duplicate prevention, status changes, snooze, retention exemption |

## M1: Notification capture and local inbox

### Section 1: domain foundation (done, 0.1.0)
- [x] Raw payload parsing with validation (no `PendingIntent` ever crosses the channel)
- [x] Mapper: trimming, redacted-content detection, UTC time, content hash
- [x] Source reference model (key, package, content-action presence, action titles)
- [x] Ingest policy: insert / update / duplicate / filtered
- [x] Allowlist and blocklist filtering, own-app, ongoing and group-summary rules
- [x] Duplicate handling: same key, changed content, removed-then-reposted, identical content re-posted under a new key
- [x] Readable content is never overwritten by a redacted version
- [x] Unit tests for mapping and duplicate handling

### Section 2: local storage (done, 0.2.0)
- [x] Drift/SQLite tables: notifications, source rules, settings
- [x] Atomic ingest in one transaction
- [x] Removal marking that keeps content
- [x] Reconciliation of stored state against the active notification set (`markRemovedExcept`)
- [x] Retention purge by age and delete-all (storage layer only)
- [x] Settings storage: filter mode, rules, ongoing and group-summary toggles, retention days
- [x] Repository tests on in-memory SQLite
- [x] Drift code generation runs on CI with the pinned versions (drift 2.31.0); the repository tests have not been confirmed passing yet

### Section 3: Android capture service (done in code, 0.3.0; not verified on a device)
- [x] Kotlin `NotificationListenerService`: connect, post, remove, and rebind request on disconnect
- [x] Notification Access detection and a button that opens the system settings screen
- [x] Reconcile currently active notifications after the listener connects (queued posts plus a snapshot of active keys)
- [x] Capture source package, app label, title, text, timestamp, key, group metadata and action metadata
- [x] Keep `PendingIntent`s in memory only, keyed by notification key, dropped on removal and disconnect
- [x] Platform channel bridge behind an interface, with fake-platform tests of the ingestion logic
- [x] Durable native queue so captures survive while the app is closed; acknowledged events are deleted
- [x] Temporary status screen (replaced by the settings screen in 0.4.0)
- [x] Detect permission revocation (the screen updates when the listener disconnects)
- [ ] Verify all of the above on a physical Android device
- [ ] Ingest while the app UI is closed (headless Flutter engine). Today the queue is drained only while the app runs, and it keeps at most 1000 events
- [ ] Redacted content end to end (only the "secret visibility" hint is detected; Android 15 sensitive-content redaction is unverified)
- [ ] Device restart and OEM-specific behavior (for example Samsung battery restrictions), verified on physical devices

### Section 4: inbox UI and permissions (done in code, 0.4.0; not verified on a device)
- [x] Inbox list with an Active/All filter, live updates, and a details screen
- [x] Loading, empty and error states
- [x] Permission banner: access off, listener not connected; refreshes when the app returns to the foreground
- [x] Source-app allowlist/blocklist screen (choose from apps seen so far, or add by package name)
- [x] Settings: capture mode, ongoing and group-summary toggles, access state, stored counts, version
- [x] Widget tests with in-memory repositories (no database, no device)
- [ ] Visual and usability review on a device (no screenshots yet)
- [ ] Accessibility review (TalkBack, large fonts, contrast)
- [ ] Hide notification content in the app switcher / optional screen security (not done)

### Section 5: import, export and deletion (done in code, 0.5.0; not verified on a device)
- [x] Import: Android share target for plain text, and an "Import text" button in the inbox (works on every platform). Imported entries bypass the app filters
- [x] Data export as a JSON file (Android: system file picker; desktop: a Nudge folder in Documents), with a warning that the file is not encrypted
- [x] Delete one notification from its details screen; delete all (also clears the native queue)
- [x] Retention setting (forever, 7, 30 or 90 days), applied at startup and when changed
- [x] Automated guard test against printing or logging notification content (a heuristic, not a proof)
- [x] Wiring script upgrades older installs (share intent filter, export channel, activity result)
- [ ] Verify on devices: sharing from several apps, the file picker, delete, retention
- [ ] Windows export location and behavior (written to Documents/Nudge, unverified)
- [ ] Export of tasks and calendar data (arrives with M2 and M3)
- [x] Retention does not delete notifications linked to tasks (0.6.0)

M1 is complete when capture and the UI are verified on a physical device and the open items above (background ingestion, redacted content, restart and OEM behavior) are resolved or consciously deferred.

## M2: Task conversion and source navigation (in progress)

### Section 1: tasks and reminders storage (done in code, 0.6.0)
- [x] Task model: title, notes, kind (task or reminder), status (open, done, archived), due time, snooze time, optional destination calendar id
- [x] Source reference kept as a snapshot (notification key, package, app label, whether an action existed), so a task still knows its source after the notification is deleted or purged
- [x] Create a task from a notification, with a title and notes derived from it, or with a draft the user edited
- [x] Duplicate prevention: one task per source notification unless the earlier one is archived
- [x] Complete, reopen, archive, restore, snooze, edit, delete; changes that do not apply are no-ops
- [x] Ordering: open tasks by reminder time, then newest; then done; then archived
- [x] Retention never deletes a notification that an open or done task points to
- [x] Database migration from schema version 1 to 2 (adds the tasks table)
- [x] App-owned tasks are independent of external calendar events
- [x] Unit tests for the draft rules and the repository on in-memory SQLite
- [ ] The migration has not been exercised on a database created by an older version

### Section 2: source navigation (done in code, 0.7.0; not compiled or run yet)
- [x] Kotlin side: open the original notification action while it is still live, otherwise the source app's launch intent
- [x] Dart side: a service that tries both in order and reports "unavailable" with the saved content kept
- [x] Tests for the fallback order with a fake platform
- [ ] Tested on a device for each supported app

### Section 3: screens (done in code, 0.8.0; not compiled or run yet)
- [x] "Create task" and "Create reminder" from a notification, with an editable form (title, notes, due date and time)
- [ ] Destination calendar in the form (arrives with the calendar milestone)
- [x] Task list and task details with complete, snooze, archive and delete
- [x] A visible "Open original" action on notification details and on task details
- [x] Tasks included in export; a separate "Delete all tasks" in Settings
- [ ] Verify the screens on a device

### Section 4: reminder delivery (done in code, 0.9.0; not compiled or run yet)
- [x] Alert at the reminder time (scheduled with the system alarm service), including after a restart; a reminder that came due while the phone was off is shown at start-up
- [x] Notification permission (asked when a reminder is saved) and exact-alarm handling: exact when allowed, otherwise a few minutes late, with Settings > Reminders explaining and linking to the right system screen
- [x] Snooze from the alert itself (10 minutes), applied to the task the next time the app syncs
- [x] The alarms follow the task list: done, archived, deleted, edited or snoozed tasks update them
- [ ] Verify on devices, including Samsung battery restrictions and Android 14 exact-alarm defaults
- [ ] A "Done" button on the alert and a choice of snooze lengths

## M3: Calendar UI with Persian date support (in progress)
Decision and layers: see [docs/CALENDAR.md](docs/CALENDAR.md).

### Section 1: date math and month layout (done in code, 0.10.0; not compiled or run yet)
- [x] Decision: custom widgets, no calendar library (recorded in docs/CALENDAR.md)
- [x] Jalali and Gregorian calendar systems with exact conversion (Jalali years 1178 to 1632), checked against an independent library for every supported day
- [x] Month grid with Saturday-first Jalali weeks and Monday-first Gregorian weeks, 4 to 6 weeks, neighbouring days marked
- [x] Persian and English month and weekday names, Persian digits
- [x] Unit tests for the conversions, leap years, month lengths and grids
- [ ] Not yet compiled or run (the Dart port was written without a Flutter toolchain)

### Section 2: month view (done in code, 0.11.0; not compiled or run yet)
- [x] Month view with tappable days, task and reminder dots, and an agenda for the selected day
- [x] Right-to-left Jalali layout (Saturday first, Persian names and digits) and a left-to-right Gregorian layout, switchable and remembered
- [x] Month navigation by arrows and swipe, a Today button, quick task creation on the selected day
- [x] Widget tests for both calendars, navigation, the agenda, the choice being saved and creating a task
- [ ] Visual, gesture and accessibility review on a device (no screenshots yet)

### Section 3: week, day and agenda views (done in code, 0.12.0; not compiled or run yet)
- [x] A switch between Month, Week, Day and Agenda over the same tasks and reminders
- [x] Week view: one row per day (the seven days of the week, Saturday first for Jalali), tasks under their date; tapping a date opens that day
- [x] Day view: 24 hours, each task under the hour it is due, opening near 07:00
- [x] Agenda: the next 60 days that have tasks, one heading per day
- [x] Previous/next steps a month, a week or a day depending on the view; swipe works in every view and follows the reading direction
- [x] Widget tests for the week title, steps, Gregorian week, day view, agenda, empty agenda and carrying the day between views
- [ ] Wide layout for Windows (week as seven columns, month and agenda side by side)
- [ ] Time grid with task durations (tasks have a time but no length yet)

### Section 5: themes, wide layouts and accessibility (done in code, 0.14.0; not compiled or run yet)
- [x] Theme setting: system, light or dark, stored and applied at once
- [x] Wide layouts: month and day list side by side, week as seven columns, other screens centred at a readable width
- [x] Large-text widget tests for the calendar views, Settings and Tasks; segmented buttons scroll instead of overflowing
- [ ] TalkBack, contrast and Windows Narrator review on devices
- [ ] Two-pane inbox, keyboard shortcuts and hover states for Windows

### Remaining in M3
- [x] Month, week, day and agenda views
- [x] Persian right-to-left UI and Jalali dates in the calendar screens (the rest of the app is not localized yet)
- [ ] Calendar colors and visibility toggles (needs external calendars, M4)
- [x] Tappable dates with an agenda for the selected day (month view)
- [x] Fast task and reminder creation (the + button on the selected day)
- [ ] Clear distinction between external events, internal tasks and reminders
- [x] Localize the whole app UI (Persian, right-to-left) (0.13.0: see docs/LOCALIZATION.md; Persian texts not yet reviewed by a native speaker; the reminder alert text is still English)
- [x] Light and dark themes (Settings > Theme); responsive wide layouts (0.14.0, see docs/UI.md; not yet seen on a device)
- [ ] Accessible typography, loading, empty and error states: large-text tests and labels are done; a TalkBack and contrast review on a device is not

## M4: Android Calendar Provider (in progress)
Design and status: [docs/CALENDAR_INTEGRATION.md](docs/CALENDAR_INTEGRATION.md).

### Section 1: discovery, permission and choices (done in code, 0.15.0; not compiled or run yet)
- [x] Discover readable and writable calendars; show names, accounts, colors and write capability
- [x] Request calendar permissions only when the user enables the integration
- [x] Let users choose calendars for display and for event creation (stored)
- [x] Provider abstraction with tests for provider behavior (platform bridge parsing, permission flow, visibility and default rules)
- [ ] Verify Google and Samsung account availability on physical devices

### Next sections
### Section 2: events in the calendar views (done in code, 0.16.0; not compiled or run yet)
- [x] Read the events (recurring ones expanded) of the shown calendars for the range on screen
- [x] Show them in the month (square markers), week, day (all-day block, hour rows) and agenda views, clearly different from tasks and reminders (calendar icon and colour, calendar name)
- [x] Tap an event for its details and open it in the device's calendar app
- [x] Provider failures are shown without breaking tasks; nothing is read while the integration is off
- [ ] Verify on devices: recurring events, all-day events across time zones, large calendars

### Next
- [ ] Section 3: create, edit and delete events in the chosen calendar; link tasks to events without duplicates; handle read-only calendars and sync failures

## M5: Windows build and secure synchronization (not started)
- [x] Windows release build runs in CI (the app is still a placeholder)
- [ ] Windows app with synchronized app-owned tasks
- [ ] External calendars on Windows through documented providers only
- [ ] Optional, off-by-default sync with encrypted transport and credentials in platform secure storage
- [ ] Data export and deletion covering synced data

## M6: Optional Google Calendar API (not started)
- [ ] Direct Google Calendar integration for cross-device access
- [ ] Track external event IDs and prevent duplicates
- [ ] Show sync failures and read-only calendars clearly

## Project infrastructure
- [x] GitHub Actions: analyze, test, Android debug APK, Windows build, artifact upload
- [x] A GitHub release with versioned file names for every push to `main` (replaces the rolling nightly release)
- [x] Builds for every branch (artifacts named with branch and commit) and permanent releases from `v*` tags
- [x] CI regenerates and wires the Android project (confirmed on CI on 2026-10-15); the Windows project is generated the same way but unconfirmed
- [ ] Verify the workflows end to end: Android build, Windows build, release creation (first successful run pending)
- [x] Automatic formatting workflow
- [x] Open-source files: LICENSE (MIT), CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, PRIVACY, CHANGELOG, issue and PR templates
- [x] Exact versions of Drift, drift_dev, drift_flutter, build_runner and the other direct dependencies (resolved on CI, pinned in 0.5.2)
- [ ] Release-signed builds (release APKs are debug-signed)
- [ ] Screenshots in the README (the UI exists now; screenshots need a device or emulator)

## Known risks and unverified assumptions
- The Kotlin code (listener, queue, channels) reached the compiler for the first time on 2026-10-15 and failed on two syntax errors (fixed in 0.5.5); further compile errors are possible, and it has never run on a device. The wiring script that patches the generated `MainActivity.kt` and `AndroidManifest.xml` was tested on a copy of the generated project from the repository history (not on a fresh `flutter create` output) and has never run in CI.
- Sideloaded debug APKs may need "Allow restricted settings" (Android 13+) before Notification Access can be enabled.
- Until background ingestion exists, notifications that arrive while the app is closed wait in a small native queue (plain JSON in app-private, no-backup storage) until the app is opened.
- The first full CI run resolved dependencies and generated the Drift code, but its analysis step failed on three issues (fixed in 0.5.2). The tests, the Android build and the Windows build have not been confirmed yet.
- Windows CI installs Flutter from its git tag because the setup action could not resolve the version there; this is untested over time.
- The rolling release needs the repository to allow workflows to write contents.
- Notification Access behavior (redaction on the lock screen, restart behavior, OEM battery restrictions) can only be verified on physical devices.
- Samsung Calendar accounts may not have an independent public API; the Android Calendar Provider is the first integration path.
- Android does not expose notifications from before access was granted, and hidden content stays hidden.

## Open decisions
- Calendar approach: library versus custom widgets (decided in M3 after the evaluation).
- License: MIT is a placeholder choice; change it before the first public release if needed.
- Distribution: debug builds only for now; store release and signing are undecided.
