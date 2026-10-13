# Development

## Toolchain
Flutter 3.35.0 (stable, Dart 3.9), JDK 17, Android SDK; Visual Studio 2022 (C++ desktop workload) for Windows. The version is pinned in `pubspec.yaml` and every workflow.

## Local commands
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format .
flutter analyze
flutter test
```

## Working without a local Flutter installation
All steps run on GitHub Actions, so a browser and git are enough:

1. Push to `main`.
2. **Format code** runs automatically and commits formatting changes, then starts CI on that commit.
3. **CI** analyzes, tests, builds the Android debug APK and the Windows release, and publishes the `nightly` pre-release.
4. When something fails, open the failed step in the Actions run; the log is what maintainers need.

## Workflows
| Workflow | Trigger | What it does |
|---|---|---|
| CI | push to `main`, PRs, manual | build_runner, analyze, tests, APK, Windows build, nightly pre-release |
| Format code | push to `main`, manual | `dart format`, commits, starts CI |
| Bootstrap platforms | manual, once | generates `android/` and `windows/` (already done for this repo) |
| Rename app to Nudge | manual, once | renames the generated Android/Windows projects (already done once it has been run) |
| Wire Android capture service | manual, once | runs `tools/wire_capture.py`: registers the capture channels in `MainActivity.kt` and declares the listener service and `<queries>` entry in `AndroidManifest.xml`; safe to run again |

Commits made by workflows with `GITHUB_TOKEN` do not trigger other workflows, which is why the Format, Bootstrap, Rename and Wire workflows start CI explicitly.

## Versioning and outputs
The version is in `pubspec.yaml` and `lib/app_info.dart` (a test keeps them equal). Build outputs carry it in the file name: `Nudge_v<version>_android-debug.apk`, `Nudge_v<version>_windows-x64.zip`. The nightly release is replaced on every successful push.

## Notes
- `*.g.dart` files are generated and not committed.
- Never print notification titles or bodies in logs or tests.

## Trying notification capture on a phone
Capture works only on Android and needs the one-time **Wire Android capture service** workflow to have been run.

1. Install the APK from the `nightly` release.
2. On Android 13 and later, a sideloaded app cannot be given Notification Access until you allow restricted settings: open Settings > Apps > Nudge, open the three-dot menu and choose **Allow restricted settings**.
3. Open Nudge and tap **Open Notification Access settings**, then enable Nudge.
4. Return to the app. The status screen should show access granted and the listener connected.
5. Trigger a notification from another app. The stored count increases. The screen never shows notification text.
6. Dismiss the notification. The "active" count decreases while the stored count stays.

If something does not match, note the Android version, the device manufacturer and what the status screen shows, and open an issue (without real notification content).
