import 'package:flutter/foundation.dart';

import '../domain/capture_settings_repository.dart';
import '../l10n/l10n.dart';

/// Holds the language setting (`system`, `en` or `fa`) and applies it to
/// [L10n]. Listeners (the app root) rebuild when it changes.
final class LanguageController extends ChangeNotifier {
  LanguageController(this._settings, {String Function()? deviceLanguage})
    : _deviceLanguage = deviceLanguage ?? _defaultDeviceLanguage;

  final CaptureSettingsRepository _settings;
  final String Function() _deviceLanguage;

  String _setting = 'system';

  static String _defaultDeviceLanguage() =>
      PlatformDispatcher.instance.locale.languageCode;

  /// `system`, `en` or `fa`, as stored.
  String get setting => _setting;

  /// The language in use: `en` or `fa`.
  String get language => L10n.resolve(_setting, _deviceLanguage());

  /// Reads the stored setting and applies it. A read failure keeps `system`.
  Future<void> load() async {
    try {
      _setting = _clean(await _settings.getLanguage());
    } on Exception {
      _setting = 'system';
    }
    _apply();
  }

  Future<void> choose(String setting) async {
    _setting = _clean(setting);
    _apply();
    await _settings.setLanguage(_setting);
  }

  /// Applies the language without notifying (used before the first build).
  void applyNow() => L10n.setLanguage(language);

  void _apply() {
    L10n.setLanguage(language);
    notifyListeners();
  }

  static String _clean(String value) =>
      value == 'en' || value == 'fa' ? value : 'system';
}
