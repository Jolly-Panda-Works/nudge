import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_info.dart';
import 'app_services.dart';
import 'l10n/l10n.dart';
import 'ui/inbox_page.dart';

Future<void> main() async {
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
    // The language is read first so the first screen is already in it.
    await services.language.load();
    await services.theme.load();
    unawaited(
      services.start().then<void>((_) {}, onError: (Object _) {
        // Queued events are retried on the next native signal.
      }),
    );
  } else {
    L10n.setLanguage(
      L10n.resolve('system', PlatformDispatcher.instance.locale.languageCode),
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
    if (services == null) return _app(null, ThemeMode.system);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        services.language,
        services.theme,
      ]),
      builder: (context, _) {
        L10n.setLanguage(services.language.language);
        return _app(services, services.theme.mode);
      },
    );
  }

  Widget _app(AppServices? services, ThemeMode themeMode) {
    return MaterialApp(
      title: appName,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: themeMode,
      locale: Locale(L10n.language),
      supportedLocales: const <Locale>[Locale('en'), Locale('fa')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Screens are rebuilt in place when the language changes.
      builder: (context, child) => _RebuildOnLanguage(
        language: L10n.language,
        child: child ?? const SizedBox.shrink(),
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
                      Text(tr('Startup failed: {error}', {'error': startupError})),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Texts are written with `tr(...)`, which widgets do not depend on, so a
/// language change does not rebuild them by itself. This marks every widget
/// below for rebuilding (like a hot reload does), keeping the open screens
/// and their state.
class _RebuildOnLanguage extends StatefulWidget {
  const _RebuildOnLanguage({required this.language, required this.child});

  final String language;
  final Widget child;

  @override
  State<_RebuildOnLanguage> createState() => _RebuildOnLanguageState();
}

class _RebuildOnLanguageState extends State<_RebuildOnLanguage> {
  @override
  void didUpdateWidget(_RebuildOnLanguage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _markAllForRebuild();
      });
    }
  }

  void _markAllForRebuild() {
    void visit(Element element) {
      element.markNeedsBuild();
      element.visitChildren(visit);
    }

    (context as Element).visitChildren(visit);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
