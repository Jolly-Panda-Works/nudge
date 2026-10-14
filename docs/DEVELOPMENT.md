# Development

## Toolchain
Flutter 3.35.0 (stable, Dart 3.9), JDK 17, Android SDK; Visual Studio 2022 (C++ desktop workload) for Windows. The version is pinned in `pubspec.yaml` and every workflow.

## Local commands
```bash
flutter pub get
dart run build_runner build
dart format .
flutter analyze --no-fatal-infos   # same as CI
flutter test
```

## Working without a local Flutter installation
All steps run on GitHub Actions, so a browser and git are enough:

1. Push to `main`.
2. **Format code** runs automatically and commits formatting changes, then starts CI on that commit.
3. **CI** builds the Android debug APK and the Windows release, runs analysis and tests in parallel, and publishes a GitHub release for the commit. On any other branch the outputs stay in the run's artifacts, named with the branch and commit, so experiments never touch `main` or the releases.
4. When something fails, open the failed step in the Actions run; the log is what maintainers need.

## Workflows
| Workflow | Trigger | What it does |
|---|---|---|
| CI | push to any branch, version tags (`v*`), PRs from forks, manual | decides the version; in parallel: analyze and tests, the Android debug APK, the Windows build; `main` and `v*` tags publish a GitHub release (see [RELEASING.md](RELEASING.md)) |
| Format code | push to `main`, manual | `dart format`, commits (formatting only, so no extra build) |
| Bootstrap platforms | manual, once | generates `android/` and `windows/`; does nothing when they exist |
| Rename app to Nudge | manual, once | renames the generated Android/Windows projects (already done once it has been run) |
| Wire Android capture service | manual, after changes to `tools/wire_capture.py` | runs `tools/wire_capture.py`: patches `MainActivity.kt` (capture and export channels, share intent, file picker result) and `AndroidManifest.xml` (listener service, `<queries>` entry, share target); idempotent and upgrades older installs |

Commits made by workflows with `GITHUB_TOKEN` do not trigger other workflows, which is why the Bootstrap, Rename and Wire workflows start CI explicitly. The Format workflow does not: its commit only changes formatting.

## Versioning and outputs
The version is in `pubspec.yaml` and `lib/app_info.dart` (a test keeps them equal). Build outputs carry it in the file name: `Nudge_v<version>_android-debug.apk`, `Nudge_v<version>_windows-x64.zip`. Every push to `main` creates a release; named versions come from `vX.Y.Z` tags.

## Notes
- `*.g.dart` files are generated and not committed.
- Never print notification titles or bodies in logs or tests.

## Trying notification capture on a phone
Capture works only on Android and needs the **Wire Android capture service** workflow to have been run on this version (it is safe to run again).

1. Install the APK from the latest release.
2. On Android 13 and later, a sideloaded app cannot be given Notification Access until you allow restricted settings: open Settings > Apps > Nudge, open the three-dot menu and choose **Allow restricted settings**.
3. Open Nudge and tap **Open Notification Access settings**, then enable Nudge.
4. Return to the app. The status screen should show access granted and the listener connected.
5. Trigger a notification from another app. It appears in the inbox. Tap it to see the details.
6. Dismiss the notification on the phone. It disappears from **Active** and shows as *Dismissed* under **All**.
7. Open Settings: access and listener state, capture mode, the app filter and the two toggles should reflect what you choose. Try "Only selected apps" with one app selected and confirm other apps stop appearing.
8. Turn Notification Access off in the system settings and return to Nudge: the banner "Notification access is off" should appear.

If something does not match, note the Android version, the device manufacturer and what the status screen shows, and open an issue (without real notification content).

## Trying import, export and deletion on a phone
1. **Share target:** in another app, select some text, tap Share and choose Nudge. Open Nudge: the text should appear in the inbox under the source "Shared" (open the details to see "Shared or imported text"). Sharing while Nudge is already open should add it without restarting.
2. **Import button:** tap the plus button in the inbox, enter some text and import it.
3. **Export:** Settings > Export data > Export. The system file picker should open; save the file, then open it in a text viewer and check that it is valid JSON with your notifications.
4. **Delete one:** open a notification, tap the trash icon and confirm.
5. **Retention:** Settings > Keep notifications for > choose a period. Notifications older than that disappear.
6. **Delete all:** Settings > Delete all notifications > confirm; the inbox is empty and the counts show 0.
