# Roadmap

Where Nudge stands and what is left. Last updated: 2026-10-13 (version 0.5.1).

**How to read the status**

- `[x]` implemented: the code and its tests are in the repository. The CI badge in the README shows whether they currently pass.
- `[ ]` not implemented yet.
- "Not verified on a device": nothing has been run on a physical Android phone or on Windows hardware yet. Items that depend on device behavior are called out explicitly.

## Summary

| Milestone | Scope | Progress |
|---|---|---|
| M1 | Android notification capture and local inbox | All 5 sections done in code; device verification and 4 open items remain |
| M2 | Task conversion and source navigation | Not started |
| M3 | Calendar UI with Persian (Jalali, RTL) support | Not started |
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
- [ ] Verified against the real Drift versions resolved on CI (versions are not pinned exactly yet)

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
- [ ] Retention must not delete notifications linked to tasks (M2)

M1 is complete when capture and the UI are verified on a physical device and the open items above (background ingestion, redacted content, restart and OEM behavior) are resolved or consciously deferred.

## M2: Task conversion and source navigation (not started)
- [ ] Convert an inbox notification into a task or timed reminder, preserving the source notification ID
- [ ] Edit title, notes, due date, time and destination calendar
- [ ] "Open original" on notification details and linked task details
- [ ] Three-step fallback: live content action, then launch intent of the source app, then a clear "unavailable" state with saved content kept
- [ ] Complete, snooze and archive tasks; prevent duplicate tasks per notification
- [ ] App-owned tasks stay independent of external calendar events
- [ ] Retention purge must not delete notifications linked to tasks
- [ ] Source navigation tested independently for each supported app
- [ ] Tests for task-source relationships and fallback navigation

## M3: Calendar UI with Persian date support (not started)
- [ ] Evaluate calendar libraries (gestures, customization, performance, accessibility, license) and choose one, or build custom
- [ ] Month, week, day and agenda views
- [ ] Persian right-to-left UI and Jalali dates, with correct Gregorian conversion for external APIs
- [ ] Calendar colors and visibility toggles; event indicators in month view
- [ ] Tappable dates with an agenda for the selected day
- [ ] Fast task and reminder creation
- [ ] Clear distinction between external events, internal tasks and reminders
- [ ] Localize the whole app UI (Persian, right-to-left); today all app text is English
- [ ] Light and dark themes; responsive Android and Windows layouts
- [ ] Accessible typography, loading, empty and error states

## M4: Android Calendar Provider (not started)
- [ ] Discover readable and writable calendars; show names, accounts, colors and write capability
- [ ] Request calendar permissions only when the user enables the integration
- [ ] Let users choose calendars for display and for event creation
- [ ] Provider abstraction with tests for provider behavior
- [ ] Verify Google and Samsung account availability on physical devices

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
- [x] Rolling `nightly` pre-release with versioned file names after every push to `main`
- [x] Builds for every branch (artifacts named with branch and commit) and permanent releases from `v*` tags
- [ ] Verify the branch-build and tag-release workflows (first run pending)
- [x] Automatic formatting workflow
- [x] Open-source files: LICENSE (MIT), CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, PRIVACY, CHANGELOG, issue and PR templates
- [ ] Pin exact versions of Drift, drift_dev, drift_flutter and build_runner (needs one successful dependency resolution log)
- [ ] Release-signed builds (the nightly APK is debug-signed)
- [ ] Screenshots in the README (the UI exists now; screenshots need a device or emulator)

## Known risks and unverified assumptions
- The Kotlin code (listener, queue, channels) has only been compiled by CI, never run on a device. The wiring script that patches the generated `MainActivity.kt` and `AndroidManifest.xml` has not been run yet.
- Sideloaded debug APKs may need "Allow restricted settings" (Android 13+) before Notification Access can be enabled.
- Until background ingestion exists, notifications that arrive while the app is closed wait in a small native queue (plain JSON in app-private, no-backup storage) until the app is opened.
- The first CI runs for the Drift code and tests have not been confirmed green.
- Windows CI installs Flutter from its git tag because the setup action could not resolve the version there; this is untested over time.
- The rolling release needs the repository to allow workflows to write contents.
- Notification Access behavior (redaction on the lock screen, restart behavior, OEM battery restrictions) can only be verified on physical devices.
- Samsung Calendar accounts may not have an independent public API; the Android Calendar Provider is the first integration path.
- Android does not expose notifications from before access was granted, and hidden content stays hidden.

## Open decisions
- Calendar approach: library versus custom widgets (decided in M3 after the evaluation).
- License: MIT is a placeholder choice; change it before the first public release if needed.
- Distribution: debug nightly builds only for now; store release and signing are undecided.
