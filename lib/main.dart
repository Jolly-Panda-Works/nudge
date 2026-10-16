import 'dart:async';

import 'package:flutter/material.dart';

import 'app_info.dart';
import 'app_services.dart';
import 'ui/inbox_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppServices? services;
  String? startupError;
  try {
    services = AppServices.create();
  } catch (error) {
    // Show the shell with the error type instead of crashing at startup.
    startupError = error.runtimeType.toString();
  }
  if (services != null) {
    unawaited(
      services.start().then<void>((_) {}, onError: (Object _) {
        // Queued events are retried on the next native signal.
      }),
    );
  }
  runApp(NudgeApp(services: services, startupError: startupError));
}

class NudgeApp extends StatelessWidget {
  const NudgeApp({super.key, this.services, this.startupError});

  final AppServices? services;
  final String? startupError;

  @override
  Widget build(BuildContext context) {
    final services = this.services;
    return MaterialApp(
      title: appName,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: services != null
          ? InboxPage(services: services)
          : Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('$appName v$appVersion'),
                    if (startupError != null)
                      Text('Startup failed: $startupError'),
                  ],
                ),
              ),
            ),
    );
  }
}
