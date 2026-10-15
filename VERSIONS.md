# Pinned versions (Nudge 0.5.4+12)

Direct dependencies are pinned to exact versions in `pubspec.yaml`. The versions below were resolved by pub on the GitHub Actions runner (Ubuntu, Flutter 3.35.0) on 2026-10-14. `pubspec.lock` is committed, so transitive dependencies are locked too.

| Item | Version | Status |
|---|---|---|
| Flutter (stable) | 3.35.0 | verified on the Linux runner; the Windows job installs it from the git tag (unverified) |
| Dart SDK | >=3.9.0 <4.0.0 | matches Flutter 3.35 |
| crypto | 3.0.7 | verified (resolved on CI) |
| drift | 2.31.0 | verified (resolved on CI; 2.35.2 exists) |
| drift_dev | 2.31.0 | verified (code generation ran on CI) |
| drift_flutter | 0.2.8 | verified (resolved on CI; 0.3.1 exists) |
| path_provider | 2.1.5 | verified (resolved on CI) |
| build_runner | 2.15.1 | verified (code generation ran on CI) |
| flutter_lints | 5.0.0 | verified |
| JDK (CI/Android) | 17 | not yet exercised (the Android build has not run) |
| Runners | ubuntu-24.04, windows-2022 | ubuntu verified |
| actions | checkout@v5, setup-java@v4, flutter-action@v2, upload-artifact@v4, download-artifact@v4; `gh` CLI preinstalled on runners | checkout and flutter-action verified |

Newer versions exist for several packages (for example drift 2.35, sqlite3 3.x, drift_flutter 0.3). They are not adopted yet; upgrading is a deliberate change that needs its own test run.
