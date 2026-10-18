# Nudge: goal, current status and remaining work

Last updated: 2026-10-18. Latest delivered version: 0.11.0.
Repository: https://github.com/Jolly-Panda-Works/nudge

---

## 1. Goal of the app

Nudge is a productivity app for **Android and Windows**, built with Flutter and native Android code where needed. It combines three things:

1. **A notification inbox.** It collects the Android notifications the system exposes to a user-approved Notification Access listener.
2. **One-tap tasks and reminders.** Any notification can become a task or a timed reminder. The task keeps a persistent reference to the original notification, with an "Open original" action.
3. **A calendar people enjoy using.** It is original in design but inspired by the usability of Samsung Calendar, with Persian right-to-left UI and Jalali dates. It integrates with the calendars available on Android (Google and Samsung accounts, when the system exposes them) and later with Google Calendar directly.

### Rules the project follows
- No Accessibility Service, root access or hidden APIs to get around platform limits.
- No promise of access to historical or hidden notifications. Android only shows what it exposes after access is granted, and redacted content stays redacted.
- Never fabricate deep links. Opening the original follows a fixed fallback: the live notification action, then the source app's launch intent, then a clear "unavailable" state with the saved content kept.
- A `PendingIntent` is never stored: it is not durable.
- Privacy first: local database, cloud sync optional and off by default, minimal retention of notification text, export and deletion available, and notification text or tokens never written to logs.
- No copying of Samsung's proprietary assets or exact UI.
- Every report separates what is implemented from what is mocked or unverified.

---

## 2. Current status in one paragraph

All five sections of milestone M1 (notification capture and local inbox) are **written**: domain logic, local storage, the Android listener service, the inbox and settings screens, text import, export and deletion. The delivery pipeline (GitHub Actions) builds on every push. **Nothing has been verified on a phone**, the **Android build has not yet succeeded in CI**, and the tests have not been confirmed passing. Milestone M2 has started: the storage for tasks and reminders (section 1 of 4) and source navigation (section 2, `SourceNavigator` plus Kotlin) are written; the task screens (section 3: list, form, detail, create from a notification, Open original buttons, export and delete) are written; reminder alerts (section 4: alarms, Snooze, restart handling, permission screens) are written. All four sections of M2 are therefore written but none has been compiled, tested or run. Milestone M3 has started: the calendar date math (Jalali and Gregorian conversion, month layout, Persian names and digits) is written and was checked against an independent library, and a month view with a day agenda (Jalali right to left, Gregorian left to right, task dots) is written, but nothing has been compiled or looked at on a device. The Android calendar provider (M4), Windows sync (M5) and Google Calendar (M6) have not been started.

---

## 3. What exists today

| Area | State |
|---|---|
| Notification capture (Kotlin listener, durable native queue, platform bridge, reconciliation after reconnect) | Written, never run on a device |
| Deduplication (same key, changed content, removed then re-posted, identical content under a new key, redacted never overwrites readable) | Written with unit tests |
| Local storage (Drift/SQLite: notifications, app filter rules, settings) with retention purge and delete all | Written with tests on in-memory SQLite |
| Inbox (Active/All filter, live updates), notification details, settings, app filter screen, permission banner | Written with widget tests |
| Share target for plain text (Android) and an "Import text" button (all platforms) | Written, not run on a device |
| JSON export (Android file picker, desktop writes to Documents/Nudge) | Written, not run on a device |
| Delete one or all, retention setting (forever, 7, 30, 90 days) | Written with tests |
| Version shown in the app (Settings > About) matches the installed build | Written |
| Open-source project files (README, LICENSE MIT, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, PRIVACY, CHANGELOG, ROADMAP, docs, issue and PR templates) | Done, English only |
| Tasks and reminders storage (create from a notification, duplicate prevention, complete, archive, snooze, edit; retention never deletes a linked notification) | Written with tests, no screens yet |
| Source navigation: live action, then launch intent, then unavailable (no button yet) | Written with tests, not compiled or run |
| Task screens, create from a notification, "Open original" buttons, tasks in export | Written with widget tests, not compiled or run |
| Reminder alerts: alarm, Snooze button, restart handling, Settings > Reminders | Written with tests, not compiled or run |
| Calendar date math: Jalali/Gregorian conversion, month grid, Persian names and digits (no screen yet) | Written with tests, not compiled or run |
| Month view with day agenda, Jalali/Gregorian switch, task dots | Written with widget tests, not compiled or run |
| Week, day and agenda views, colours, external calendars | Not started |
| Windows app features beyond a placeholder build, sync | Not started |

### Delivery pipeline (GitHub Actions)
- Every push builds the Android debug APK and the Windows app. Analysis and tests run in parallel and never block the outputs.
- Push to `main`: a permanent GitHub release `v0.5.<run number>` with the APK, the Windows zip, `SHA256SUMS.txt` and generated notes.
- Tag `vX.Y.Z`: a release with exactly that version.
- Other branches: files stay in the run's artifacts, named with version, branch and commit.
- The `android/` and `windows/` projects are not committed. CI generates them with `flutter create` when missing, then applies `tools/wire_capture.py` (listener service, share target, file picker, display name "Nudge").
- Pinned: Flutter 3.35.0, exact versions of all direct dependencies, committed `pubspec.lock`.

### What CI has actually confirmed so far
- Flutter 3.35.0 installs on the Linux runner; dependencies resolve; Drift code generation works.
- The self-generating Android step works: the project was generated and wired on the runner.
- Gradle and the Kotlin compiler run. The first compile failed on two comment syntax errors; fixed in 0.5.5, **result of that fix not yet seen**.
- **Not yet seen:** analysis and test results after the 0.5.2 fixes, a successful Android build, any Windows build result, a successfully created release.

---

## 4. Remaining work

### Immediate (to close M1)
1. Push 0.5.5 and get CI green: Android build, `verify` (analysis and tests), Windows build, release created. Send the log of any red step.
2. Install the APK on a phone and walk through the checklists in `docs/DEVELOPMENT.md` (capture, banner, filters, share, export, delete, retention). Report what fails, with Android version and phone brand.
3. Decide how to handle the M1 open items below.

### M1 open items
- [ ] Verify everything above on a physical Android device.
- [ ] **Ingest while the app is closed.** Today the native queue is only drained when the app runs, and it holds at most 1000 events (plain JSON in private no-backup storage). A headless Flutter engine would fix this.
- [ ] Redacted content end to end (only the "secret visibility" flag is detected; Android 15 hiding of sensitive content such as one-time codes is not).
- [ ] Behavior after a device restart and on manufacturer-specific battery restrictions (for example Samsung).
- [ ] Visual and usability review with screenshots; accessibility review (TalkBack, large fonts, contrast).
- [ ] Hide notification content in the app switcher / optional screen security.
- [ ] Windows export location and behavior.

### M2: tasks and source navigation
- [x] Task storage: create from a notification keeping its ID, edit fields, complete, archive, snooze, duplicate prevention (section 1, no screens yet).
- [ ] Screens to create and edit a task or reminder (title, notes, due date, time, destination calendar).
- [ ] "Open original" on notification details and on linked task details, with the three-step fallback.
- [ ] Complete, snooze, archive; prevent duplicate tasks for one notification.
- [x] App-owned tasks independent of external calendar events.
- [x] Retention does not delete notifications linked to tasks.
- [ ] Reminder alerts at the due time, including after a restart.
- [ ] Source navigation tested separately for each supported app.

### M3: calendar UI with Persian support
- [x] Decision: build custom calendar widgets, no library (docs/CALENDAR.md); no generic default widget as the finished UI.
- [x] Date math and month layout for Jalali and Gregorian (section 1).
- [ ] Month, week, day and agenda views; event indicators; tappable dates with an agenda.
- [ ] Persian right-to-left UI and Jalali dates, with correct Gregorian conversion for external APIs; localize the whole app (today all text is English).
- [ ] Calendar colors and visibility, fast task and reminder creation, clear distinction between external events, tasks and reminders.
- [ ] Light and dark themes; responsive Android and Windows layouts; accessible typography; loading, empty and error states.

### M4: Android Calendar Provider
- [ ] Discover readable and writable calendars; show names, accounts, colors, write capability.
- [ ] Ask for calendar permission only when the user enables the integration; choose calendars for display and for creating events.
- [ ] Provider abstraction with tests; verify Google and Samsung accounts on physical devices.

### M5: Windows and secure synchronization
- [ ] Windows app with synchronized app-owned tasks; external calendars on Windows only through documented providers.
- [ ] Optional sync, off by default: encrypted transport, credentials in platform secure storage, export and deletion that cover synced data.

### M6: Google Calendar API (optional)
- [ ] Direct integration for cross-device access; track external event IDs to prevent duplicates; show sync failures and read-only calendars.

### Project infrastructure
- [ ] Release-signed builds: the pipeline signs with a key from repository secrets (0.8.1) but the key has not been created or the secrets added yet, so builds are still debug-signed until then.
- [ ] README screenshots.
- [ ] Verify the Windows build in CI (Flutter is installed there from its git tag, which is untested).

---

## 5. Risks and open decisions

**Risks**
- The Kotlin code reached the compiler for the first time on 2026-10-15; more compile errors are possible, and it has never run on a device.
- Sideloaded debug APKs may need "Allow restricted settings" (Android 13+) before Notification Access can be switched on.
- Notification Access behavior (lock-screen redaction, restarts, manufacturer battery limits) can only be verified on real devices.
- Samsung Calendar accounts may have no independent public API; the Android Calendar Provider is the first integration path.
- One release is created per push to `main`, so releases accumulate; old ones have to be deleted by hand.
- Releases need the repository to allow workflows to write contents.

**Open decisions**
- Calendar approach: library or custom widgets (decide in M3 after the evaluation).
- License: MIT is a placeholder; confirm or change before the first public release.
- Distribution: debug builds only for now; signing and any store release are undecided.

---

## 6. How the project is worked on

- No local Flutter installation: everything is built and tested on GitHub Actions.
- Work is delivered as a zip of the whole project plus a suggested commit header (`GIT_COMMIT.txt`), applied by replacing the repository contents.
- Each section is delivered, then tested by the owner, then the next one starts. When testing is needed, it is requested explicitly.
- Documentation is English only. Detailed per-task checklists live in `ROADMAP.md`; release notes in `CHANGELOG.md`.
