import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/l10n/fa_strings.dart';
import 'package:nudge/l10n/l10n.dart';

/// The texts passed to `tr(...)` in lib/, with adjacent string pieces joined.
Set<String> sourceKeys() {
  final call = RegExp(r"(?<![\w.])tr\(\s*((?:'(?:[^'\\]|\\.)*'\s*)+)");
  final piece = RegExp(r"'((?:[^'\\]|\\.)*)'");
  final keys = <String>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final source = entity.readAsStringSync();
    for (final match in call.allMatches(source)) {
      final buffer = StringBuffer();
      for (final p in piece.allMatches(match.group(1)!)) {
        buffer.write(
          p.group(1)!.replaceAllMapped(RegExp(r'\\(.)'), (m) {
            final c = m.group(1)!;
            return c == 'n' ? '\n' : c;
          }),
        );
      }
      keys.add(buffer.toString());
    }
  }
  return keys;
}

void main() {
  tearDown(() => L10n.setLanguage('en'));

  test('English text is returned as it is', () {
    L10n.setLanguage('en');
    expect(tr('Cancel'), 'Cancel');
    expect(tr('Deleted {count} tasks', {'count': 3}), 'Deleted 3 tasks');
  });

  test('Persian text and Persian digits for whole numbers', () {
    L10n.setLanguage('fa');
    expect(tr('Cancel'), 'انصراف');
    expect(tr('Deleted {count} tasks', {'count': 12}), '۱۲ وظیفه حذف شد');
  });

  test('values that are not whole numbers are inserted unchanged', () {
    L10n.setLanguage('fa');
    expect(
      tr('Exported to {location}', {'location': 'Documents/Nudge 2'}),
      'در Documents/Nudge 2 ذخیره شد',
    );
  });

  test('a text without a translation falls back to English', () {
    L10n.setLanguage('fa');
    expect(tr('Not in the table {x}', {'x': 1}), 'Not in the table ۱');
  });

  test('anything other than fa means English', () {
    L10n.setLanguage('de');
    expect(L10n.language, 'en');
    expect(L10n.isPersian, isFalse);
  });

  test('resolve follows the setting, then the device language', () {
    expect(L10n.resolve('fa', 'en'), 'fa');
    expect(L10n.resolve('en', 'fa'), 'en');
    expect(L10n.resolve('system', 'fa'), 'fa');
    expect(L10n.resolve('system', 'fa_IR'), 'fa');
    expect(L10n.resolve('system', 'en'), 'en');
    expect(L10n.resolve('system', 'de'), 'en');
  });

  test('every text passed to tr has a Persian translation', () {
    final missing = sourceKeys().where((k) => !faStrings.containsKey(k));
    expect(missing, isEmpty, reason: 'add these to lib/l10n/fa_strings.dart');
  });

  test('the Persian table has no stale entries', () {
    final used = sourceKeys();
    final stale = faStrings.keys.where((k) => !used.contains(k));
    expect(stale, isEmpty, reason: 'no longer used in lib/');
  });

  test('translations keep the placeholders and are not empty', () {
    final placeholder = RegExp(r'\{\w+\}');
    faStrings.forEach((english, persian) {
      expect(persian.trim(), isNotEmpty, reason: english);
      expect(
        placeholder.allMatches(persian).map((m) => m.group(0)).toList()..sort(),
        placeholder.allMatches(english).map((m) => m.group(0)).toList()..sort(),
        reason: english,
      );
    });
  });
}
