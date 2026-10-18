import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/application/language_controller.dart';
import 'package:nudge/l10n/l10n.dart';

import '../support/in_memory_repositories.dart';

void main() {
  late InMemorySettingsRepository settings;

  setUp(() => settings = InMemorySettingsRepository());
  tearDown(() => L10n.setLanguage('en'));

  test('starts as system and follows the device language', () {
    final fa = LanguageController(settings, deviceLanguage: () => 'fa');
    final en = LanguageController(settings, deviceLanguage: () => 'en');

    expect(fa.setting, 'system');
    expect(fa.language, 'fa');
    expect(en.language, 'en');
  });

  test('load applies the stored setting', () async {
    settings.language = 'fa';
    final controller = LanguageController(settings, deviceLanguage: () => 'en');

    await controller.load();

    expect(controller.setting, 'fa');
    expect(L10n.language, 'fa');
  });

  test('load of an unknown value falls back to system', () async {
    settings.language = 'klingon';
    final controller = LanguageController(settings, deviceLanguage: () => 'fa');

    await controller.load();

    expect(controller.setting, 'system');
    expect(L10n.language, 'fa');
  });

  test('choose applies, saves and notifies', () async {
    final controller = LanguageController(settings, deviceLanguage: () => 'en');
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.choose('fa');

    expect(L10n.language, 'fa');
    expect(settings.language, 'fa');
    expect(notified, 1);

    await controller.choose('system');
    expect(settings.language, 'system');
    expect(L10n.language, 'en');
  });

  test('choose cleans an invalid value', () async {
    final controller = LanguageController(settings, deviceLanguage: () => 'en');

    await controller.choose('nonsense');

    expect(controller.setting, 'system');
    expect(settings.language, 'system');
  });
}
