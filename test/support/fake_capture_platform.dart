import 'dart:async';

import 'package:nudge/domain/raw_notification_payload.dart';
import 'package:nudge/platform/capture_event.dart';
import 'package:nudge/platform/capture_platform.dart';
import 'package:nudge/platform/capture_signal.dart';

/// In-memory stand-in for the native queue and listener.
class FakeCapturePlatform implements CapturePlatform {
  final List<CaptureEvent> queue = <CaptureEvent>[];
  final StreamController<CaptureSignal> _signals =
      StreamController<CaptureSignal>.broadcast();

  int lastAck = 0;
  int _seq = 0;
  bool accessGranted = false;
  bool connected = false;
  bool settingsAvailable = true;
  bool supported = true;
  int settingsOpens = 0;
  int clearedQueue = 0;
  int rebindRequests = 0;
  String package = 'app.nudge.nudge';
  final Set<String> liveKeys = <String>{};
  final Set<String> launchablePackages = <String>{};
  final List<String> openCalls = <String>[];

  void addPosted(RawNotificationPayload payload) =>
      queue.add(PostedEvent(++_seq, payload));

  void addRemoved(String key) => queue.add(RemovedEvent(++_seq, key));

  void addSnapshot(Set<String> keys) => queue.add(SnapshotEvent(++_seq, keys));

  void addMalformed() => queue.add(MalformedEvent(++_seq));

  void addShared({required String text, String? title}) => queue.add(
    SharedEvent(
      ++_seq,
      text: text,
      title: title,
      postedAt: DateTime.utc(2026, 10, 13, 9),
    ),
  );

  void signal(CaptureSignal signal) => _signals.add(signal);

  @override
  bool get isSupported => supported;

  @override
  Future<String> packageName() async => package;

  @override
  Future<bool> isAccessGranted() async => accessGranted;

  @override
  Future<bool> isServiceConnected() async => connected;

  @override
  Future<bool> openAccessSettings() async {
    settingsOpens++;
    return settingsAvailable;
  }

  @override
  Future<void> requestRebind() async {
    rebindRequests++;
  }

  @override
  Future<bool> openLiveContent(String notificationKey) async {
    openCalls.add('live:$notificationKey');
    return liveKeys.contains(notificationKey);
  }

  @override
  Future<bool> openSourceApp(String packageName) async {
    openCalls.add('app:$packageName');
    return launchablePackages.contains(packageName);
  }

  @override
  Future<List<CaptureEvent>> peek({int max = 100}) async =>
      queue.take(max).toList(growable: false);

  @override
  Future<void> clearQueue() async {
    clearedQueue++;
    queue.clear();
  }

  @override
  Future<void> ack(int upToSeq) async {
    lastAck = upToSeq;
    queue.removeWhere((event) => event.seq <= upToSeq);
  }

  @override
  Stream<CaptureSignal> get signals => _signals.stream;
}
