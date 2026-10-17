import 'package:flutter/material.dart';

/// Result of the import dialog.
final class ImportedText {
  const ImportedText({required this.text, this.title});

  final String text;
  final String? title;
}

class ImportTextDialog extends StatefulWidget {
  const ImportTextDialog({super.key});

  @override
  State<ImportTextDialog> createState() => _ImportTextDialogState();
}

class _ImportTextDialogState extends State<ImportTextDialog> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _text = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _text.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Enter some text to import');
      return;
    }
    final title = _title.text.trim();
    Navigator.of(context).pop(
      ImportedText(text: text, title: title.isEmpty ? null : title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import text'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title (optional)'),
            ),
            TextField(
              controller: _text,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(labelText: 'Text', errorText: _error),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Import')),
      ],
    );
  }
}
