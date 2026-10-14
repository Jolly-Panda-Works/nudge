import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

enum ExportOutcome { saved, cancelled, unsupported }

final class ExportResult {
  const ExportResult(this.outcome, {this.location});

  final ExportOutcome outcome;

  /// Where the file was written, when the platform tells us.
  final String? location;
}

/// Saves an export file. The content is sensitive and never logged.
abstract interface class DataExporter {
  Future<ExportResult> save({
    required String fileName,
    required String content,
  });
}

/// Android: the system file picker (Storage Access Framework).
final class ChannelDataExporter implements DataExporter {
  ChannelDataExporter({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('app.nudge/export');

  final MethodChannel _channel;

  @override
  Future<ExportResult> save({
    required String fileName,
    required String content,
  }) async {
    final saved =
        await _channel.invokeMethod<bool>('saveDocument', <String, Object?>{
          'fileName': fileName,
          'content': content,
        }) ??
        false;
    return ExportResult(saved ? ExportOutcome.saved : ExportOutcome.cancelled);
  }
}

/// Desktop: writes into a "Nudge" folder inside the user's documents folder.
final class FileDataExporter implements DataExporter {
  const FileDataExporter();

  @override
  Future<ExportResult> save({
    required String fileName,
    required String content,
  }) async {
    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory('${documents.path}${Platform.pathSeparator}Nudge');
    await folder.create(recursive: true);
    final file = File('${folder.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(content);
    return ExportResult(ExportOutcome.saved, location: file.path);
  }
}

DataExporter createDataExporter() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return ChannelDataExporter();
  }
  return const FileDataExporter();
}
