# Privacy

Nudge handles notification text, which can be sensitive. These are the rules the project follows. Where something is not implemented yet, it says so.

## What is collected
- Notifications that Android delivers to Nudge after you grant **Notification Access**: source app (package and label), title, text if available, timestamp, grouping information, and whether a content action existed.
- Tasks, reminders and calendar references you create.

## Where it is stored
- **Only on your device**, in a local SQLite database. The current version has no network code and no cloud sync.
- Cloud sync, if it is ever added (M5), will be optional, off by default and encrypted in transit, with credentials kept in platform secure storage.

## What is never stored
- Authentication tokens or notification bodies in application logs or CI logs.
- `PendingIntent` objects. Only the fact that an action existed is saved, because a PendingIntent cannot be persisted.

## Temporary native queue
The Android listener appends each event (including notification title and text) to a small file in the app's private, no-backup storage so that nothing is lost while the app is closed. The app moves the events into its database and deletes them from the file as soon as they are stored. The file keeps at most 1000 events and is not encrypted; it is protected by Android's app sandbox like the database. Events are never written to logs.

Until background ingestion is implemented, notifications that arrive while the app is closed stay in this file until the app is opened.

## Your controls
- You can revoke Notification Access in Android settings at any time; capture stops.
- Source apps can be allowlisted or blocklisted from Settings > Choose apps.
- Retention and "delete everything" exist in the storage layer. The screens for export and deletion are planned for M1 section 5.

## Known gaps
- The app shows captured text on its own screens. Android may show those screens in the app switcher; hiding them is not implemented yet.
- Per-notification deletion, export and the retention setting have no screens yet (planned for M1 section 5).

## What Nudge does not do
- It does not use an Accessibility Service, root access or hidden APIs to read content Android does not expose.
- It does not read notifications from before you granted access.
