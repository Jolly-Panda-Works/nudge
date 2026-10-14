import 'package:nudge/platform/data_exporter.dart';

class FakeDataExporter implements DataExporter {
  ExportResult result = const ExportResult(
    ExportOutcome.saved,
    location: '/fake/Nudge/export.json',
  );
  bool failOnSave = false;
  String? lastFileName;
  String? lastContent;

  @override
  Future<ExportResult> save({
    required String fileName,
    required String content,
  }) async {
    if (failOnSave) throw Exception('disk full');
    lastFileName = fileName;
    lastContent = content;
    return result;
  }
}
