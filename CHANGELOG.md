# Changelog

All notable changes are documented here. Format based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[Semantic Versioning](https://semver.org/) (pre-1.0).

## [0.12.0] - 2026-10-18
### Added
- M3 section 3: week, day and agenda views next to the month view, chosen with a switch above the calendar. The week view shows one row per day with its tasks and a title naming the range; tapping a date opens it in the day view. The day view lists the 24 hours with each task under its hour. The agenda lists the next 60 days that have tasks.
- The arrows and swiping step by a month, a week or a day depending on the view; Previous/Next tooltips say which. Switching views keeps the day (or the month that was on screen).
- `calendar_widgets.dart` (shared task tile, `calendarDayText`, `calendarHeading`, `startOfWeek`) and the three view files.
- Tests: the new views with a fixed clock (Jalali and Gregorian weeks, day view, agenda, empty agenda, carrying the day between views) and the formatting helpers.
### Changed
- `CalendarPage` was reorganized around a view mode; the month view looks and behaves as in 0.11.0, and the app bar title is now "Calendar" with the month shown above the grid.
### Known limitations
- Not compiled, tested or run: CI is the first check; nothing was seen on a device. No wide layout for Windows yet, no durations or time grid, and calendar colours and visibility wait for external calendars (M4).

## [0.11.0] - 2026-10-18
### Added
- M3 section 2: a month view (`CalendarPage`), opened from the calendar icon in the inbox. Jalali is shown right to left, Saturday first, with Persian month and weekday names and Persian digits; Gregorian is shown left to right, Monday first. A button switches between them and the choice is remembered (settings key `calendar_system`).
- Tasks and reminders appear as dots on their day (up to three). Tapping a day shows its agenda below with the date in both calendars; tapping an item opens the task. The `+` button creates a task on the selected day. Arrows or swiping change the month, Today returns to the current day.
- `CalendarSystems` (registry), `groupTasksByDay` (tasks by local day of their reminder time), `formatTimeOfDay`, and `TaskFormPage.initialDate`.
- Tests: the page with a fixed clock (Persian text, right-to-left order, navigation, switching and saving, agenda, creating a task), `groupTasksByDay`, and the new setting in the Drift repository.
### Known limitations
- Not compiled, tested or run: CI is the first check. Not looked at on a device: layout, gestures and TalkBack are unreviewed. Only the month view exists; week, day, agenda, colours and external events come later. The rest of the app text is still English.

## [0.10.0] - 2026-10-18
### Added
- M3 section 1: calendar date math and month layout, in `lib/domain/calendar/`. `JalaliCalendar` and `GregorianCalendar` (behind a `CalendarSystem` interface) convert exactly between Jalali and Gregorian dates; `MonthGrid` lays a month out in weeks (Saturday first for Jalali, Monday first for Gregorian, 4 to 6 weeks, neighbouring days marked); `CalendarNames` has Persian and English month and weekday names and Persian digits.
- Jalali years 1178 to 1632 are supported (Gregorian 1799 to 2254). The algorithm (a port of `jalaali-js`) was compared with an independent library for every day in that range before it was ported to Dart, with zero differences. The Dart tests repeat the round trip over the same range.
- `docs/CALENDAR.md`: the decision to build custom calendar widgets instead of using a library, the layers, and the rules (stored data never depends on the calendar system; external calendars always get Gregorian dates).
### Known limitations
- No screen uses the calendar yet (views start in section 2). Not compiled, tested or run: the Dart code was written without a Flutter toolchain, so CI is the first check.

## [0.9.0] - 2026-10-18
### Added
- M2 section 4: reminder alerts. A reminder (or any open task with a date) alerts at its time through the Android alarm service, with a Snooze 10 min button. Alarms are set again after a restart or an app update; a reminder that came due while the phone was off is shown at start-up.
- `ReminderScheduler` keeps the alarms in step with the open tasks (future times only) and applies snoozes done from an alert while the app was closed.
- Kotlin `app.nudge.reminders`: store (private no-backup file), scheduler (exact alarm when allowed, otherwise `setAndAllowWhileIdle`), notifier with a "Reminders" channel, receivers for the alarm, Snooze and boot, and the `app.nudge/reminders` channel.
- Settings > Reminders: whether alerts are allowed and whether timing is exact, with a link to the right system screen for each. The notification permission is asked when a reminder is saved.
- `wire_capture.py` declares the permissions (`POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`) and receivers, and adds the channel to an already wired `MainActivity.kt`.
- Tests for the scheduler and the settings and permission flows with a fake platform. The widget test window is taller so long screens stay on screen.
### Known limitations
- Not compiled, tested or run: CI is the first check. Not tested on a device; Samsung battery restrictions and Android 14 exact-alarm defaults are unverified.
- Windows has no reminder alerts. A snooze done from an alert shows on the task the next time the app syncs (start, resume, or a task change).
- The alert shows only the task title. Done and other snooze lengths are not offered yet.

## [0.8.1] - 2026-10-18
### Changed
- The Android application id is now `com.jollypanda.nudge` (it was `app.nudge.nudge`). `tools/wire_capture.py` sets it in `build.gradle.kts` even on an already generated project, and CI generates new projects with `--org com.jollypanda`. This is a different app to Android: the old install stays next to it and its data is not moved.
- Release signing: the Android build reads a release key from repository secrets (`NUDGE_KEYSTORE_BASE64`, `NUDGE_KEYSTORE_PASSWORD`, `NUDGE_KEY_ALIAS`, optionally `NUDGE_KEY_PASSWORD`) and signs the APKs with it. Without the secrets it falls back to the debug key and says so in the release notes. The build summary shows the signing certificate.
### Added
- `tools/make_keystore.sh` creates the key and prints the secrets to add.
- `.gitignore` excludes `*.jks`, `*.keystore` and `key.properties`.
### Known limitations
- Not compiled or run: the Gradle patch was only tried on a sample of the Flutter template.

## [0.8.0] - 2026-10-18
### Added
- M2 section 3: task screens. A Tasks screen (Open, Done, Archived) with a checkbox to complete or reopen, a form to create or edit a task or reminder (title, notes, kind, date, time), and a task detail with Mark done, Reopen, Snooze, Archive, Restore, Edit and Delete.
- Notification details: Create task, Create reminder (or View task when one exists) and Open original. Task details also have Open original, using the live action, then the app, then a clear unavailable message.
- Export now includes tasks with their source snapshot. Settings has Delete all tasks.
- Tests: widget tests for creating, linking, completing, archiving and Open original; export tests for tasks; an in-memory task repository for widget tests.
### Known limitations
- A reminder's time is saved and shown but nothing alerts at that time yet (section 4). The destination calendar is not selectable until the calendar milestone. Not compiled, tested or run: written without a Flutter toolchain, so CI is the first check. Not tested on a device.

## [0.7.0] - 2026-10-18
### Added
- M2 section 2: source navigation. `SourceNavigator` opens the original of a notification in a fixed order: the live notification action, then the source app's launch intent, then an explicit "unavailable" result. No deep link is invented and no `PendingIntent` is stored.
- Kotlin: `ContentIntentRegistry.send` and `openLauncher`, and the channel methods `openLiveContent` and `openSourceApp`. A cancelled intent is dropped and reported as not opened.
- `CapturePlatform.openLiveContent` and `openSourceApp` (method channel, no-op and fake implementations).
- Tests for the fallback order with a fake platform.
### Changed
- Releases: a push to `main` is tagged automatically and becomes the Latest release; all older releases and their tags are deleted, except releases made from tags pushed by hand.
- Android output is now a release build split per architecture (arm64-v8a and armeabi-v7a) instead of one universal debug APK of about 140 MB.
### Known limitations
- No button calls it yet (screens arrive in section 3). Not compiled, tested or run: this version was written without a Flutter toolchain, so CI is the first check. Not tested on a device.

## [0.6.0] - 2026-10-16
### Added
- M2 section 1: tasks and reminders storage. `TaskItem`, `TaskDraft`, `TaskRepository` and `DriftTaskRepository`: create (also from a notification, with a derived or edited draft), duplicate prevention per source notification, complete, reopen, archive, restore, snooze, edit, delete, ordered lists, counts.
- A task keeps a snapshot of its source (notification key, package, app label, whether an action existed), so it survives the deletion of the notification.
- Drift schema version 2 with a migration that adds the `tasks` table.
- Tests for the draft rules and for the repository on in-memory SQLite.
### Changed
- Retention (`purgeOlderThan`) no longer deletes notifications that an open or done task points to.
- `AppServices` now exposes the task repository.
### Known limitations
- No screens yet for tasks. The migration from version 1 has not been exercised on a real older database.

## [0.5.5] - 2026-10-15
### Fixed
- The first Android build failed to compile: two Kotlin comments contained `/*` (a MIME type and a file pattern). Block comments nest in Kotlin, so they never closed. The comments are reworded and a test now checks that block comments in the Kotlin sources are balanced, so this fails in seconds instead of after a five-minute Gradle build.
### Changed
- `actions/setup-java` updated from v4 (deprecated) to v5.
### Verified by CI
- The self-healing Android step worked: it generated the project with `flutter create` and wired the manifest and `MainActivity.kt`.

## [0.5.4] - 2026-10-14
### Fixed
- Builds produced nothing after the 0.5.3 commit because that commit deleted the generated `android/` and `windows/` projects (zips never contained them, and replacing the repository contents with the zip removed them). CI now generates a missing platform project with `flutter create` and wires it with `tools/wire_capture.py` before every build, so the folders no longer have to be committed.
### Changed
- `tools/wire_capture.py` also sets the display name to "Nudge" (Android application label, Windows window title and file description) and accepts `--only android|windows`.
- `pubspec.lock` and `.gitignore` are part of the project again, so every transitive dependency version is pinned and a full replacement of the repository contents no longer drops them.
### Removed
- The one-time workflows Bootstrap platforms, Rename app to Nudge and Wire Android capture service (CI does their job on every build).
- Dependabot configuration: it opened a branch and a build for each proposed update, and the project pins its dependency versions on purpose. Updates are done deliberately.

## [0.5.3] - 2026-10-14
### Changed
- All workflows rewritten. Every push to `main` now creates a permanent GitHub release `v<MAJOR.MINOR.<run number>>` with the APK, the Windows zip, `SHA256SUMS.txt` and generated notes (replacing the rolling "nightly" release, which is removed on the first run). Version tags `vX.Y.Z` publish a release with exactly that version. Other branches keep their files in the run's artifacts.
- Builds no longer wait for analysis and tests: they run in parallel, so a red test never blocks the outputs.
- The build version is passed to the app (`--build-name`, `--build-number`, `NUDGE_VERSION`), so Settings > About shows the version of the installed file.
- The Format workflow no longer starts a second build; its commit only changes formatting.
- Bootstrap does nothing when the platform folders already exist.
### Removed
- The check that a tag matches the pubspec version, and the rolling nightly release.

## [0.5.2] - 2026-10-14
### Fixed
- Analyzer errors found by the first CI run: missing import of `CaptureStatus` in the inbox screen, missing `Size` import in the test harness, and a lint in the privacy guard test.
### Changed
- Direct dependencies are pinned to the exact versions CI resolved (drift 2.31.0, drift_dev 2.31.0, drift_flutter 0.2.8, build_runner 2.15.1, path_provider 2.1.5, crypto 3.0.7, flutter_lints 5.0.0).
- Removed the `--delete-conflicting-outputs` flag, which build_runner now ignores.
- Repository links point to `Jolly-Panda-Works/nudge`.

## [0.5.1] - 2026-10-13
### Added
- Builds for every branch: pushes to any branch are analyzed, tested and built, and the outputs are artifacts named with the version, branch and commit (kept 14 days; `main` 30 days).
- Permanent releases: pushing a tag `v<version>` publishes a GitHub release with the APK, the Windows zip, `SHA256SUMS.txt` and the changelog section as notes (versions starting with `0.` are pre-releases). If a release was drafted in the GitHub UI, the files are attached to it.
- `docs/RELEASING.md`.
### Changed
- CI runs on pushes to all branches; pull requests from this repository no longer run twice (forks still do).
- The nightly release also includes `SHA256SUMS.txt`.

## [0.5.0] - 2026-10-13
### Added
- Share target for plain text (Android) and an "Import text" button in the inbox; imported entries bypass the app filters.
- Data export as a JSON file (Android system file picker; desktop writes to Documents/Nudge).
- Delete one notification from its details screen; delete all notifications (also clears the native queue).
- Retention setting (forever, 7, 30 or 90 days), applied at startup and when changed.
- `TextImporter`, `RetentionService`, `DataExporter`, `exportNotificationsJson`, `NotificationRepository.listAll` and `deleteByKey`, `CapturePlatform.clearQueue`.
- Kotlin `ShareReceiver` and `DocumentExporter`; `tools/wire_capture.py` now also wires the share intent filter, the export channel and the file picker result, and upgrades installs wired by 0.3.0 and 0.4.0 (run the **Wire Android capture service** workflow again).
- Guard test that fails if code prints or logs notification content (heuristic).
- Direct dependency on `path_provider` (already used transitively).
### Known limitations
- Not verified on a physical device. Export files are not encrypted.

## [0.4.0] - 2026-10-13
### Added
- Inbox screen with an Active/All filter, live updates, and loading, empty and error states.
- Notification details screen.
- Settings screen: access and listener state, capture mode, ongoing and group-summary toggles, stored counts, version.
- App filter screen: choose apps seen so far or add one by package name.
- Permission banner (access off, listener not connected) that refreshes when the app returns to the foreground.
- `CaptureStatusController`, `SourceApp`, `NotificationRepository.listSourceApps`, `CaptureSettingsRepository.listRules`, `CapturePlatform.isSupported`.
- Widget tests with in-memory repositories; unit tests for time formatting and the status controller.
### Changed
- The temporary status screen is replaced by the inbox and settings screens.
- CI runs `flutter analyze --no-fatal-infos`: warnings and errors still fail the build, info-level hints do not.

## [0.3.0] - 2026-10-13
### Added
- Android capture (M1 section 3): Kotlin `NotificationListenerService`, durable native event queue, method/event channels, reconciliation of active notifications, in-memory-only `PendingIntent` registry.
- Dart side: capture events, platform interface with Android and no-op implementations, `CaptureIngestor` (native queue to database, acknowledge after storing).
- Temporary status screen (notification access, listener state, counts; never shows notification text).
- `NotificationRepository.count`.
- `Wire Android capture service` workflow and `tools/wire_capture.py` to patch the generated `MainActivity.kt` and `AndroidManifest.xml`.
### Known limitations
- Not verified on a physical device. Notifications that arrive while the app is closed are ingested only when the app runs.

## [0.2.2] - 2026-10-13
### Added
- `ROADMAP.md`: progress per milestone and section, what is done and what remains, known risks.
### Changed
- All documentation is English only; the Persian README was removed.

## [0.2.1] - 2026-10-13
### Added
- Open-source project files: README (English and Persian), LICENSE (MIT), CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, PRIVACY, docs (architecture, development, roadmap), issue and PR templates, Dependabot, editorconfig.
- CI publishes the outputs of every push to `main` as a rolling `nightly` pre-release (APK and Windows zip, version in the file name).
- Workflows that commit to `main` (format, bootstrap, rename) now start CI on the new commit.
### Changed
- Formatting check in CI is report-only; the Format workflow fixes it.
- CI no longer cancels a running build when a newer push arrives.

## [0.2.0] - 2026-10-12
### Added
- Drift database (notifications, source rules, settings) and repositories: atomic ingest with dedupe, removal marking, reconciliation, retention purge, delete-all.
- App renamed to Nudge; version shown in the app shell.
- Workflows: build_runner step, Format code, one-time rename.

## [0.1.1] - 2026-10-12
### Added
- Bootstrap workflow to generate platform folders without a local Flutter installation.

## [0.1.0] - 2026-10-12
### Added
- Domain model, notification mapper, ingest/dedupe policy, tests and CI.
