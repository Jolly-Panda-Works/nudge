import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Cheap guard that runs before the slow Android build. Block comments nest in
/// Kotlin, so a comment that contains "/*" (for example a path or a MIME type
/// ending in a wildcard) never closes and the whole build fails.
void main() {
  test('Kotlin sources have balanced block comments', () {
    final directory = Directory('android/app/src/main/kotlin');
    expect(directory.existsSync(), isTrue);

    final offenders = <String>[];
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.kt')) continue;
      final text = entity.readAsStringSync();
      final openers = '/*'.allMatches(text).length;
      final closers = '*/'.allMatches(text).length;
      if (openers != closers) {
        offenders.add('${entity.path}: $openers "/*" vs $closers "*/"');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'Do not write "/*" inside Kotlin comments: $offenders',
    );
  });
}
