import 'dart:async';

import 'package:nudge/domain/raw_notification_payload.dart';
import 'package:nudge/platform/capture_event.dart';
import 'package:nudge/platform/capture_platform.dart';
import 'package:nudge/platform/capture_signal.dart';

/// In-memory stand-in for the native queue and listener.
final class FakeCapturePlatform implements CapturePlatform {
  final List<CaptureEvent> queue = <CaptureEvent>[];
  final StreamController<CaptureSignal> _signals =
      StreamController<CaptureSignal>.broadcast();

  int lastAck = 0;
  int _seq = 0;
  bool accessGranted = false;
  bool connected = false;
  bool settingsAvailable = true;
  int rebindRequests = 0;
  String package = 'app.nudge.nudge';

  void addPosted(RawNotificationPayload payload) =>
      queue.add(PostedEvent(++_seq, payload));

  void addRemoved(String key) => queue.add(RemovedEvent(++_seq, key));

  void addSnapshot(Set<String> keys) =>
      queue.add(SnapshotEvent(++_seq, keys));

  void addMalformed() => queue.add(MalformedEvent(++_seq));

  void signal(CaptureSignal signal) => _signals.add(signal);

  @override
  Future<String> packageName() async => package;

  @override
  Future<bool> isAccessGranted() async => accessGranted;

  @override
  Future<bool> isServiceConnected() async => connected;

  @override
  Future<bool> openAccessSettings() async => settingsAvailable;

  @override
  Future<void> requestRebind() async {
    rebindRequests++;
  }

  @override
  Future<List<CaptureEvent>> peek({int max = 100}) async =>
      queue.take(max).toList(growable: false);

  @override
  Future<void> ack(int upToSeq) async {
    lastAck = upToSeq;
    queue.removeWhere((event) => event.seq <= upToSeq);
  }

  @override
  Stream<CaptureSignal> get signals => _signals.stream;
}
