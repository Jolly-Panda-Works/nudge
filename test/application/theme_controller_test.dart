import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/application/theme_controller.dart';

import '../support/in_memory_repositories.dart';

void main() {
  late InMemorySettingsRepository settings;

  setUp(() => settings = InMemorySettingsRepository());

  test('starts as system', () {
    final controller = ThemeController(settings);
    expect(controller.setting, 'system');
    expect(controller.mode, ThemeMode.system);
  });

  test('load applies the stored setting', () async {
    settings.themeMode = 'dark';
    final controller = ThemeController(settings);

    await controller.load();

    expect(controller.mode, ThemeMode.dark);
  });

  test('an unknown stored value means system', () async {
    settings.themeMode = 'sepia';
    final controller = ThemeController(settings);

    await controller.load();

    expect(controller.setting, 'system');
  });

  test('choose saves and notifies', () async {
    final controller = ThemeController(settings);
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.choose('light');

    expect(controller.mode, ThemeMode.light);
    expect(settings.themeMode, 'light');
    expect(notified, 1);

    await controller.choose('nonsense');
    expect(settings.themeMode, 'system');
  });
}
