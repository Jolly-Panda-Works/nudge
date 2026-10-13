# Nudge

[![CI](https://github.com/Usef-Farahmand/nudge/actions/workflows/ci.yml/badge.svg)](https://github.com/Usef-Farahmand/nudge/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Flutter 3.35](https://img.shields.io/badge/Flutter-3.35.0-02569B?logo=flutter)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20Windows-lightgrey)

**Nudge turns your notifications into tasks, and puts them on a calendar you actually enjoy using.**

It combines an inbox of accessible Android notifications, one-tap conversion to tasks or reminders (with a persistent link back to the original source), and a Persian-first calendar with Jalali dates.

> **Status: early development (v0.2.x).** Only the foundations exist so far (domain model, deduplication, local storage). There is no usable UI and no notification capture yet. See [Project status](#project-status) for exactly what is implemented. Persian version: [README.fa.md](README.fa.md).

## Features

| Area | Goal | Status |
|---|---|---|
| Notification inbox | Capture accessible Android notifications via `NotificationListenerService` | Planned (M1, section 3) |
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

Every push to `main` that passes the checks publishes a rolling pre-release called **nightly** with:

- `Nudge_v<version>_android-debug.apk`
- `Nudge_v<version>_windows-x64.zip`

Find it under [Releases](https://github.com/Usef-Farahmand/nudge/releases/tag/nightly), or download the same files from the artifacts of the latest [CI run](https://github.com/Usef-Farahmand/nudge/actions/workflows/ci.yml). These are debug builds for testing only.

## Build from source

Requirements: Flutter **3.35.0** (stable), JDK 17 and the Android SDK for Android, Visual Studio 2022 with the C++ desktop workload for Windows.

```bash
git clone https://github.com/Usef-Farahmand/nudge.git
cd nudge
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates Drift code
flutter analyze
flutter test
flutter run                      # connected Android device
flutter run -d windows           # Windows
```

No local Flutter installation? Everything also runs on GitHub Actions; see [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## Project layout

```
lib/
  domain/   pure Dart: models, mapper, ingest/dedupe policy, repository interfaces
  data/     Drift database and repository implementations
  main.dart app shell (placeholder UI)
test/       unit and widget tests
docs/       architecture, development and roadmap
.github/    CI, formatting and release workflows, issue and PR templates
```

## Project status

Milestones (each is independently testable):

| Milestone | Scope | State |
|---|---|---|
| M1 | Notification capture and local inbox | In progress: sections 1-2 done (domain, storage); 3-5 pending (Kotlin service, inbox UI, share/import and export/delete) |
| M2 | Task conversion and source navigation | Not started |
| M3 | Calendar UI with Persian dates | Not started |
| M4 | Android Calendar Provider | Not started |
| M5 | Windows build and secure sync | Not started |
| M6 | Optional Google Calendar API | Not started |

Full plan: [docs/ROADMAP.md](docs/ROADMAP.md). Release notes: [CHANGELOG.md](CHANGELOG.md).

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md) first. For security issues see [SECURITY.md](SECURITY.md); please do not paste real notification content into public issues.

## License

[MIT](LICENSE). Nudge does not copy Samsung's proprietary assets or UI; the calendar design is original and only inspired by usability patterns of mobile calendars.
