# Changelog

All notable changes are documented here. Format based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[Semantic Versioning](https://semver.org/) (pre-1.0).

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
