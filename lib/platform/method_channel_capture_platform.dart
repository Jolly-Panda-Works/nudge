import 'package:flutter/services.dart';

import 'capture_event.dart';
import 'capture_platform.dart';
import 'capture_signal.dart';

/// Android implementation backed by the Kotlin `CaptureChannels`.
final class MethodChannelCapturePlatform implements CapturePlatform {
  MethodChannelCapturePlatform({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  }) : _methods = methodChannel ?? const MethodChannel('app.nudge/capture'),
       _events =
           eventChannel ?? const EventChannel('app.nudge/capture/events');

  final MethodChannel _methods;
  final EventChannel _events;

  // One shared broadcast stream: the native side supports a single listener.
  late final Stream<CaptureSignal> _signals = _events
      .receiveBroadcastStream()
      .map<CaptureSignal>((Object? event) {
        if (event is Map<Object?, Object?> && event['type'] == 'state') {
          return StateSignal(connected: event['connected'] == true);
        }
        return const WakeSignal();
      });

  @override
  bool get isSupported => true;

  @override
  Stream<CaptureSignal> get signals => _signals;

  @override
  Future<String> packageName() async =>
      await _methods.invokeMethod<String>('packageName') ?? '';

  @override
  Future<bool> isAccessGranted() async =>
      await _methods.invokeMethod<bool>('isAccessGranted') ?? false;

  @override
  Future<bool> isServiceConnected() async =>
      await _methods.invokeMethod<bool>('isServiceConnected') ?? false;

  @override
  Future<bool> openAccessSettings() async =>
      await _methods.invokeMethod<bool>('openAccessSettings') ?? false;

  @override
  Future<void> requestRebind() => _methods.invokeMethod<void>('requestRebind');

  @override
  Future<List<CaptureEvent>> peek({int max = 100}) async {
    final lines =
        await _methods.invokeListMethod<String>('peekQueue', <String, Object?>{
          'max': max,
        }) ??
        const <String>[];
    final events = <CaptureEvent>[];
    for (final line in lines) {
      try {
        events.add(CaptureEvent.fromJson(line));
      } on FormatException {
        // Unreadable line: the native queue drops it on the next ack.
      }
    }
    return events;
  }

  @override
  Future<void> clearQueue() => _methods.invokeMethod<void>('clearQueue');

  @override
  Future<void> ack(int upToSeq) {
    return _methods.invokeMethod<void>('ackQueue', <String, Object?>{
      'upToSeq': upToSeq,
    });
  }
}
