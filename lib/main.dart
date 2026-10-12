import 'package:flutter/material.dart';

void main() => runApp(const UnifiedInboxApp());

/// Placeholder shell. The real inbox UI arrives in M1 section 4.
class UnifiedInboxApp extends StatelessWidget {
  const UnifiedInboxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unified Inbox',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('Unified Inbox - scaffold')),
      ),
    );
  }
}
