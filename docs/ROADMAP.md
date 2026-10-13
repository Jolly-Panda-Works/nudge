# Roadmap

Each milestone is independently testable. Status reflects code in this repository.

## M1: Notification capture and local inbox (in progress)
1. Done: scaffold, domain model, mapper, ingest/dedupe policy, CI.
2. Done: Drift database and repositories.
3. Next: Kotlin `NotificationListenerService`, platform channels, Notification Access flow, reconciliation after connect, restart handling.
4. UI: inbox list and detail, permission states, allowlist/blocklist screen.
5. Share/import path, data export and deletion, retention setting.

## M2: Task conversion and source navigation
Convert a notification to a task or timed reminder, editable title/notes/date/time/calendar, "Open original" with the three-step fallback, completion, snooze, archive, duplicate prevention. Tested independently per supported app.

## M3: Calendar UI with Persian date support
Month, week, day and agenda views; RTL and Jalali display with correct Gregorian conversion for external APIs; calendar colors and visibility; event indicators; fast task creation; light and dark themes; responsive Android and Windows layouts. Calendar libraries are evaluated (gestures, customization, performance, accessibility, license) before one is chosen.

## M4: Android Calendar Provider
Discover readable/writable calendars, show accounts, colors and write capability, permissions requested only when the integration is enabled, verification of Google and Samsung accounts on physical devices.

## M5: Windows build and secure synchronization
Windows app with synchronized app-owned tasks, documented calendar providers, optional encrypted sync with credentials in platform secure storage.

## M6: Optional direct Google Calendar API integration
Cross-device access, external event IDs tracked to prevent duplicates, visible sync failures and read-only calendars.
