/// Display name and version shown in the UI.
///
/// CI passes the exact build version with `--dart-define=NUDGE_VERSION=...`.
/// Without it (local runs, tests) the default below is used; it must match the
/// `version:` in pubspec.yaml before the "+" (checked by test/app_info_test.dart).
const String appName = 'Nudge';
const String appVersion = String.fromEnvironment(
  'NUDGE_VERSION',
  defaultValue: '0.14.0',
);
