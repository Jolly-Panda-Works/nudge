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

Commits made by workflows with `GITHUB_TOKEN` do not trigger other workflows, which is why the Format, Bootstrap and Rename workflows start CI explicitly.

## Versioning and outputs
The version is in `pubspec.yaml` and `lib/app_info.dart` (a test keeps them equal). Build outputs carry it in the file name: `Nudge_v<version>_android-debug.apk`, `Nudge_v<version>_windows-x64.zip`. The nightly release is replaced on every successful push.

## Notes
- `*.g.dart` files are generated and not committed.
- Never print notification titles or bodies in logs or tests.
