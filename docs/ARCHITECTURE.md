# Architecture

## Layers
```
Android (Kotlin)            Flutter / Dart
┌────────────────────┐      ┌───────────────────────────────────────┐
│ NotificationListener│ ──▶ │ platform channel (planned, M1 §3)      │
│ Service (planned)   │      │   └▶ RawNotificationPayload.fromMap    │
└────────────────────┘      │ domain/  mapper, ingest policy, models  │
                            │ data/    Drift DB + repositories        │
                            │ UI       inbox, tasks, calendar (later) │
                            └───────────────────────────────────────┘
```
- `lib/domain/` is pure Dart with no Flutter or database imports. It holds the models, `NotificationMapper`, `decideIngest`/`CapturePolicy` and the repository interfaces.
- `lib/data/` implements the interfaces with Drift (SQLite). Timestamps are stored as UTC epoch milliseconds.
- The platform side talks to Dart through a `MethodChannel`/`EventChannel` behind an interface, so everything else is testable without a device.

## Notification ingest
1. The native listener sends a plain map (no `PendingIntent`) for each posted notification.
2. `RawNotificationPayload.fromMap` validates it; `NotificationMapper` trims text, detects redacted content and computes a content hash (package + title + text, no timestamp).
3. `decideIngest` returns one of `insert`, `update`, `ignoreDuplicate`, `ignoreFiltered`:
   - filtered by the capture policy (allowlist/blocklist, own app, ongoing, group summaries);
   - same key and same content is a duplicate;
   - same key with changed content is an update; a removed entry that reappears is reactivated;
   - readable content is never overwritten by a redacted version;
   - identical content under a new key within a short window is a duplicate re-post.
4. `DriftNotificationRepository.ingest` runs the lookup, decision and write in one transaction.
5. Removal marks the entry as removed but keeps its content (so tasks created from it stay valid). After the listener reconnects, `markRemovedExcept(activeKeys)` reconciles the stored state.

## Source navigation (design; implemented in M2)
`SourceRef` stores the notification key, package name and whether a content action existed. A `PendingIntent` is never serialized. Opening the source tries, in order: the live content action while it is still usable; a supported launch intent for the source app; a clear "unavailable" state with the saved content preserved.

## Database
| Table | Purpose |
|---|---|
| `notifications` | captured notifications, primary key = notification key, index on (package, content hash) |
| `source_rules` | package names for the allowlist/blocklist |
| `app_settings` | key/value settings: filter mode, ongoing and group-summary toggles, retention days |

Generated Drift code (`*.g.dart`) is not committed; `build_runner` creates it locally and in CI.

## Testing
- Domain: plain unit tests with a fixed clock.
- Data: repositories run against in-memory SQLite.
- Planned: fake platform channel tests for the listener bridge, per-app source navigation tests, calendar provider tests.
- Device-only behavior (OEM battery restrictions, reboot, lock-screen redaction) cannot be covered by CI and is verified manually.
