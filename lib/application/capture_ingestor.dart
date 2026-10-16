import 'dart:async';

import '../domain/capture_settings_repository.dart';
import '../domain/notification_mapper.dart';
import '../domain/notification_repository.dart';
import '../platform/capture_event.dart';
import '../platform/capture_platform.dart';
import 'text_importer.dart';

/// Moves events from the native queue into the database.
///
/// Events are acknowledged only after they were stored, so a failure leaves
/// them in the native queue and the next drain retries. Notification content is
/// never logged.
final class CaptureIngestor {
  CaptureIngestor({
    required CapturePlatform platform,
    required NotificationRepository notifications,
    required CaptureSettingsRepository settings,
    NotificationMapper? mapper,
    TextImporter? importer,
    int batchSize = 100,
  }) : _platform = platform,
       _notifications = notifications,
       _settings = settings,
       _mapper = mapper ?? NotificationMapper(),
       _importer =
           importer ??
           TextImporter(notifications: notifications, mapper: mapper),
       _batchSize = batchSize;

  final CapturePlatform _platform;
  final NotificationRepository _notifications;
  final CaptureSettingsRepository _settings;
  final NotificationMapper _mapper;
  final TextImporter _importer;
  final int _batchSize;

  final StreamController<int> _drained = StreamController<int>.broadcast();
  StreamSubscription<Object?>? _subscription;
  Future<void> _tail = Future<void>.value();

  /// Emits the number of processed events after a drain that did work.
  Stream<int> get onDrained => _drained.stream;

  /// Starts listening for native wake-ups and drains once.
  Future<void> start() async {
    _subscription ??= _platform.signals.listen((_) {
      unawaited(
        drain().then<void>(
          (_) {},
          onError: (Object _) {
            // Events stay queued natively and are retried on the next signal.
          },
        ),
      );
    });
    await drain();
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> dispose() async {
    await stop();
    await _drained.close();
  }

  /// Processes everything queued natively. Runs are serialized.
  Future<int> drain() {
    final run = _tail.then((_) => _drainOnce());
    _tail = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }

  Future<int> _drainOnce() async {
    final ownPackage = await _platform.packageName();
    final policy = await _settings.loadPolicy(
      ownPackageName: ownPackage.isEmpty ? null : ownPackage,
    );
    var processed = 0;
    var lastAcked = 0;
    while (true) {
      final events = await _platform.peek(max: _batchSize);
      if (events.isEmpty || events.last.seq <= lastAcked) break;
      for (final event in events) {
        switch (event) {
          case PostedEvent(:final payload):
            await _notifications.ingest(_mapper.map(payload), policy);
          case RemovedEvent(:final key):
            await _notifications.markRemoved(key);
          case SnapshotEvent(:final activeKeys):
            await _notifications.markRemovedExcept(activeKeys);
          case SharedEvent(:final text, :final title, :final postedAt):
            await _importer.importText(
              text: text,
              title: title,
              postedAt: postedAt,
            );
          case MalformedEvent():
            break;
        }
        processed++;
      }
      lastAcked = events.last.seq;
      await _platform.ack(lastAcked);
    }
    if (processed > 0 && !_drained.isClosed) _drained.add(processed);
    return processed;
  }
}
