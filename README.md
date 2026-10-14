# Nudge

[![CI](https://github.com/Jolly-Panda-Works/nudge/actions/workflows/ci.yml/badge.svg)](https://github.com/Jolly-Panda-Works/nudge/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Flutter 3.35](https://img.shields.io/badge/Flutter-3.35.0-02569B?logo=flutter)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20Windows-lightgrey)

**Nudge turns your notifications into tasks, and puts them on a calendar you actually enjoy using.**

It combines an inbox of accessible Android notifications, one-tap conversion to tasks or reminders (with a persistent link back to the original source), and a Persian-first calendar with Jalali dates.

> **Status: early development (v0.5.x).** Notification capture, local storage, an inbox, text import, export and deletion exist in code, but nothing has been verified on a physical device yet, and there are no tasks or calendar. See [Project status](#project-status) for exactly what is implemented.

## Features

| Area | Goal | Status |
|---|---|---|
| Notification capture | Capture accessible Android notifications via `NotificationListenerService` | Implemented in code (Kotlin service, durable queue, ingestion); not verified on a device |
| Inbox UI | List, details, settings, app filter screens, permission banner | Implemented in code; not verified on a device |
| Share / import | Share text to Nudge from other Android apps, or paste it in the app | Implemented in code; not verified on a device |
| Export and deletion | JSON export, delete one or all, retention period | Implemented in code; not verified on a device |
| Deduplication | Handle updates, re-posts, removals, redacted content | Implemented in domain code, covered by unit tests |
| Local storage | On-device database, retention purge, delete all | Implemented (Drift/SQLite), covered by unit tests |
| Source filters | Allowlist / blocklist of source apps | Rules stored; UI planned |
| Tasks & reminders | Convert a notification into a task, snooze, archive | Planned (M2) |
| Open original | Open the source notification, else the app, else show "unavailable" | Planned (M2) |
| Calendar UI | Month / week / day / agenda, Jalali dates, RTL, light and dark | Planned (M3) |
| Android calendars | Read/write via Android Calendar Provider | Planned (M4) |
| Windows & sync | Windows build, optional encrypted sync | Planned (M5) |
| Google Calendar API | Optional direct integration | Planned (M6) |

"Implemented" means the code and its tests are in this repository. The CI badge shows whether they currently pass. Nothing has been verified on a physical device yet.

## What Nudge will and will not do

- It only sees notifications that Android exposes to a user-approved Notification Access listener. It cannot read past notifications from before access was granted, and hidden or redacted content stays hidden.
- It does not use an Accessibility Service, root access or hidden APIs.
- It never fabricates deep links. If the original notification action is gone, it falls back to launching the source app, and otherwise tells you the source is unavailable while keeping the saved content.
- Calendar permissions are requested only when you enable calendar integration.

Details: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and [PRIVACY.md](PRIVACY.md).

## Download

| What | Where |
|---|---|
| Latest build | the newest entry on the [Releases](https://github.com/Jolly-Panda-Works/nudge/releases) page (one release per push to `main`) |
| A named version | the release for that `vX.Y.Z` tag on the same page |
| Another branch | the artifacts of that branch's [CI run](https://github.com/Jolly-Panda-Works/nudge/actions/workflows/ci.yml), named with the branch and commit |

Each build contains `Nudge_v<version>_android-debug.apk` and `Nudge_v<version>_windows-x64.zip`; releases also include `SHA256SUMS.txt`. These are debug builds for testing only. See [docs/RELEASING.md](docs/RELEASING.md).

## Build from source

Requirements: Flutter **3.35.0** (stable), JDK 17 and the Android SDK for Android, Visual Studio 2022 with the C++ desktop workload for Windows.

```bash
git clone https://github.com/Jolly-Panda-Works/nudge.git
cd nudge
flutter pub get
dart run build_runner build   # generates Drift code
flutter analyze
flutter test
flutter run                      # connected Android device
flutter run -d windows           # Windows
```

No local Flutter installation? Everything also runs on GitHub Actions; see [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md), which also explains how to try notification capture on a phone.

## Project layout

```
lib/
  domain/       pure Dart: models, mapper, ingest/dedupe policy, repository interfaces
  data/         Drift database and repository implementations
  platform/     bridge to the Android listener (events, channels, no-op for other platforms)
  application/  capture ingestor, text importer, retention, status controller
  ui/           inbox, notification details, settings, app filter and import screens
  main.dart     app entry point
android/app/src/main/kotlin/app/nudge/capture/   Kotlin listener service, queue, channels
tools/          one-off scripts (wiring the Android service into the generated project)
test/           unit and widget tests
ROADMAP.md      what is done and what remains
docs/           architecture and development guides
.github/        CI, formatting and release workflows, issue and PR templates
```

## Project status

Milestones (each is independently testable):

| Milestone | Scope | State |
|---|---|---|
| M1 | Notification capture and local inbox | All 5 sections done in code; device verification and a few open items remain |
| M2 | Task conversion and source navigation | Not started |
| M3 | Calendar UI with Persian dates | Not started |
| M4 | Android Calendar Provider | Not started |
| M5 | Windows build and secure sync | Not started |
| M6 | Optional Google Calendar API | Not started |

Detailed progress and remaining work: [ROADMAP.md](ROADMAP.md). Release notes: [CHANGELOG.md](CHANGELOG.md).

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md) first. For security issues see [SECURITY.md](SECURITY.md); please do not paste real notification content into public issues.

## License

[MIT](LICENSE). Nudge does not copy Samsung's proprietary assets or UI; the calendar design is original and only inspired by usability patterns of mobile calendars.
