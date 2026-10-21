import 'package:flutter/services.dart';

import '../domain/external_calendar.dart';
import '../domain/event_draft.dart';
import '../domain/external_event.dart';
import 'calendar_platform.dart';

/// Android implementation backed by the Kotlin `CalendarChannels`.
final class MethodChannelCalendarPlatform implements CalendarPlatform {
  MethodChannelCalendarPlatform({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('app.nudge/calendars');

  final MethodChannel _channel;

  @override
  bool get isSupported => true;

  @override
  Future<CalendarPermissions> permissions() async {
    final map = await _channel.invokeMapMethod<String, Object?>('permissions');
    return CalendarPermissions(
      read: map?['read'] == true,
      write: map?['write'] == true,
    );
  }

  @override
  Future<bool> requestPermissions() async =>
      await _channel.invokeMethod<bool>('requestPermissions') ?? false;

  @override
  Future<bool> openAppSettings() async =>
      await _channel.invokeMethod<bool>('openAppSettings') ?? false;

  @override
  Future<List<ExternalCalendar>> listCalendars() async {
    try {
      final raw =
          await _channel.invokeListMethod<Map<Object?, Object?>>(
            'listCalendars',
          ) ??
          const <Map<Object?, Object?>>[];
      final calendars = <ExternalCalendar>[];
      for (final item in raw) {
        final id = item['id'];
        if (id is! String || id.isEmpty) continue;
        final color = item['color'];
        calendars.add(
          ExternalCalendar(
            id: id,
            displayName: item['displayName'] as String? ?? '',
            accountName: item['accountName'] as String? ?? '',
            accountType: item['accountType'] as String? ?? '',
            color: color is int ? color : null,
            canWrite: item['canWrite'] == true,
            isOwner: item['isOwner'] == true,
            visibleInProvider: item['visible'] == true,
          ),
        );
      }
      return calendars;
    } on PlatformException catch (error) {
      throw CalendarPlatformException(
        error.code == 'permission_denied'
            ? 'permission_denied'
            : 'query_failed',
      );
    }
  }

  @override
  Future<List<ExternalEvent>> listEvents({
    required DateTime from,
    required DateTime to,
    required Set<String> calendarIds,
  }) async {
    if (calendarIds.isEmpty) return const <ExternalEvent>[];
    try {
      final raw =
          await _channel.invokeListMethod<Map<Object?, Object?>>(
            'listEvents',
            <String, Object?>{
              'fromMillis': from.millisecondsSinceEpoch,
              'toMillis': to.millisecondsSinceEpoch,
              'calendarIds': calendarIds.toList(),
            },
          ) ??
          const <Map<Object?, Object?>>[];
      final events = <ExternalEvent>[];
      for (final item in raw) {
        final eventId = item['eventId'];
        final calendarId = item['calendarId'];
        final begin = item['beginMillis'];
        final end = item['endMillis'];
        if (eventId is! String ||
            calendarId is! String ||
            begin is! num ||
            end is! num) {
          continue;
        }
        final allDay = item['allDay'] == true;
        final color = item['color'];
        events.add(
          ExternalEvent(
            eventId: eventId,
            calendarId: calendarId,
            title: item['title'] as String? ?? '',
            start: _instant(begin.toInt(), allDay: allDay),
            end: _instant(end.toInt(), allDay: allDay),
            allDay: allDay,
            color: color is int ? color : null,
            recurring: item['recurring'] == true,
          ),
        );
      }
      return events;
    } on PlatformException catch (error) {
      throw CalendarPlatformException(
        error.code == 'permission_denied'
            ? 'permission_denied'
            : 'query_failed',
      );
    }
  }

  /// All-day events are stored as UTC midnights; they mean the local days
  /// with the same year, month and day.
  static DateTime _instant(int millis, {required bool allDay}) {
    final utc = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    if (!allDay) return utc.toLocal();
    return DateTime(utc.year, utc.month, utc.day);
  }

  @override
  Future<bool> openEvent(ExternalEvent event) async {
    // The calendar app expects all-day times as UTC midnights.
    DateTime shown(DateTime t) =>
        event.allDay ? DateTime.utc(t.year, t.month, t.day) : t;
    return await _channel.invokeMethod<bool>('openEvent', <String, Object?>{
          'eventId': event.eventId,
          'beginMillis': shown(event.start).millisecondsSinceEpoch,
          'endMillis': shown(event.end).millisecondsSinceEpoch,
          'allDay': event.allDay,
        }) ??
        false;
  }

  Map<String, Object?> _draftArguments(EventDraft draft) => <String, Object?>{
    'title': draft.cleanTitle,
    'notes': draft.notes,
    'beginMillis': draft.beginMillis,
    'endMillis': draft.endMillis,
    'allDay': draft.allDay,
  };

  /// Runs a write and maps the platform's error codes.
  Future<T> _write<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PlatformException catch (error) {
      throw CalendarPlatformException(
        error.code == 'permission_denied'
            ? 'permission_denied'
            : 'write_failed',
      );
    }
  }

  @override
  Future<String> createEvent(EventDraft draft) => _write(() async {
    final id = await _channel.invokeMethod<String>(
      'createEvent',
      <String, Object?>{
        ..._draftArguments(draft),
        'calendarId': draft.calendarId,
      },
    );
    if (id == null || id.isEmpty) {
      throw const CalendarPlatformException('write_failed');
    }
    return id;
  });

  @override
  Future<bool> updateEvent(String eventId, EventDraft draft) => _write(
    () async =>
        await _channel.invokeMethod<bool>('updateEvent', <String, Object?>{
          ..._draftArguments(draft),
          'eventId': eventId,
        }) ??
        false,
  );

  @override
  Future<bool> deleteEvent(String eventId) => _write(
    () async =>
        await _channel.invokeMethod<bool>('deleteEvent', <String, Object?>{
          'eventId': eventId,
        }) ??
        false,
  );

  @override
  Future<bool> eventExists(String eventId) async {
    try {
      return await _channel.invokeMethod<bool>('eventExists', <String, Object?>{
            'eventId': eventId,
          }) ??
          false;
    } on PlatformException catch (error) {
      throw CalendarPlatformException(
        error.code == 'permission_denied'
            ? 'permission_denied'
            : 'query_failed',
      );
    }
  }
}
