import 'package:flutter/material.dart';

import 'app_info.dart';

void main() => runApp(const NudgeApp());

/// Placeholder shell. The real inbox UI arrives in M1 section 4.
class NudgeApp extends StatelessWidget {
  const NudgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const Scaffold(body: Center(child: Text('$appName v$appVersion'))),
    );
  }
}
