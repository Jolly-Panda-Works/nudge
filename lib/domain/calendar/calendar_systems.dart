import 'calendar_system.dart';
import 'gregorian_calendar.dart';
import 'jalali_calendar.dart';

/// The calendar systems the app knows, by id.
abstract final class CalendarSystems {
  static const CalendarSystem jalali = JalaliCalendar();
  static const CalendarSystem gregorian = GregorianCalendar();

  /// The system shown when nothing was chosen: Jalali.
  static const String defaultId = 'jalali';

  static const List<CalendarSystem> all = <CalendarSystem>[jalali, gregorian];

  /// The system with [id]; an unknown or missing id gives the default.
  static CalendarSystem byId(String? id) =>
      id == gregorian.id ? gregorian : jalali;
}
