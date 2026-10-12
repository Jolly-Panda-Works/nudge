# Changelog

## 0.2.0+3 - M1 / Section 2
- App renamed to **Nudge** (Dart package `nudge`, display name Nudge).
- Drift database (`Notifications`, `SourceRules`, `AppSettings` tables).
- `NotificationRepository` + `DriftNotificationRepository`: atomic ingest using
  the Section 1 dedupe policy, removal marking, listener reconciliation,
  retention purge, delete-all, watch stream.
- `CaptureSettingsRepository` + Drift implementation (allow/blocklist rules,
  ongoing/group-summary toggles, retention days).
- CI: build_runner step, pinned runners, Windows install from git tag.
- New workflows: `format.yml` (auto format), `rename-app.yml` (one-time rename
  of the generated Android/Windows projects).

## 0.1.1+2
- `bootstrap.yml` workflow so Flutter does not need to be installed locally.

## 0.1.0+1
- M1 / Section 1: domain model, mapper, ingest policy, tests, CI.
