import 'package:flutter/services.dart';

import '../domain/external_calendar.dart';
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
}
