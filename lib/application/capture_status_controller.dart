import 'dart:async';

import 'package:flutter/widgets.dart';

import '../platform/capture_platform.dart';
import '../platform/capture_signal.dart';

final class CaptureStatus {
  const CaptureStatus({
    required this.accessGranted,
    required this.listenerConnected,
  });

  final bool accessGranted;
  final bool listenerConnected;
}

/// Keeps the notification-access and listener state fresh for the UI.
/// Refreshes on native signals and when the app returns to the foreground
/// (for example after the user visits the system settings screen).
class CaptureStatusController extends ChangeNotifier
    with WidgetsBindingObserver {
  CaptureStatusController(this._platform);

  final CapturePlatform _platform;
  StreamSubscription<CaptureSignal>? _subscription;
  CaptureStatus? _status;
  bool _started = false;
  bool _disposed = false;

  CaptureStatus? get status => _status;

  bool get isSupported => _platform.isSupported;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _subscription = _platform.signals.listen((_) => unawaited(refresh()));
    unawaited(refresh());
  }

  Future<void> refresh() async {
    try {
      final granted = await _platform.isAccessGranted();
      final connected = await _platform.isServiceConnected();
      if (_disposed) return;
      _status = CaptureStatus(
        accessGranted: granted,
        listenerConnected: connected,
      );
      notifyListeners();
    } on Exception {
      // Keep the previous status; the next refresh will try again.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(refresh());
  }

  @override
  void dispose() {
    _disposed = true;
    if (_started) WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
