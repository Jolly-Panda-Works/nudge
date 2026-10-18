import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

import '../domain/capture_settings_repository.dart';

/// Holds the theme setting (`system`, `light` or `dark`). Listeners (the app
/// root) rebuild when it changes.
final class ThemeController extends ChangeNotifier {
  ThemeController(this._settings);

  final CaptureSettingsRepository _settings;

  String _setting = 'system';

  /// `system`, `light` or `dark`, as stored.
  String get setting => _setting;

  ThemeMode get mode => switch (_setting) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  /// Reads the stored setting. A read failure keeps `system`.
  Future<void> load() async {
    try {
      _setting = _clean(await _settings.getThemeMode());
    } on Exception {
      _setting = 'system';
    }
    notifyListeners();
  }

  Future<void> choose(String setting) async {
    _setting = _clean(setting);
    notifyListeners();
    await _settings.setThemeMode(_setting);
  }

  static String _clean(String value) =>
      value == 'light' || value == 'dark' ? value : 'system';
}
