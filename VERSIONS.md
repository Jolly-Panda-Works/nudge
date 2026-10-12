# Pinned versions (M1 / Section 1, app version 0.1.1+2)

| Item | Version | Status |
|---|---|---|
| Flutter (stable) | 3.35.0 | pinned in pubspec + CI; NOT verified in the generation sandbox |
| Dart SDK | >=3.9.0 <4.0.0 | matches Flutter 3.35 |
| crypto | ^3.0.6 | not resolved in the sandbox (no pub.dev access) |
| flutter_lints | ^5.0.0 | not resolved in the sandbox |
| JDK (CI/Android) | 17 | |
| actions | checkout@v4, setup-java@v4, flutter-action@v2, upload-artifact@v4 | |

If your local `flutter --version` differs, tell me and I will re-pin
pubspec.yaml and ci.yml to it.
