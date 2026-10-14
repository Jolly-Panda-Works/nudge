import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Heuristic guard for "never write notification content to logs". It cannot
/// prove the absence of leaks, but it fails when someone adds a print or a log
/// call that interpolates anything other than an exception type.
void main() {
  test('Dart code does not print or log', () {
    final pattern = RegExp(
      r'\b(print|debugPrint|debugPrintStack)\(|developer\.log\(',
    );
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) offenders.add('${entity.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty, reason: 'Remove logging from: $offenders');
  });

  test('Kotlin log calls only interpolate exception types', () {
    final directory = Directory('android/app/src/main/kotlin');
    expect(directory.existsSync(), isTrue);
    const allowed = r'${e.javaClass.simpleName}';
    final offenders = <String>[];
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.kt')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!RegExp(r'\bLog\.[a-z]\(').hasMatch(line)) continue;
        if (line.replaceAll(allowed, '').contains(r'$')) {
          offenders.add('${entity.path}:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'Unsafe log interpolation: $offenders');
  });
}
