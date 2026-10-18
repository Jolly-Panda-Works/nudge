import '../domain/calendar/calendar_date.dart';
import '../domain/calendar/calendar_names.dart';
import '../domain/calendar/calendar_systems.dart';
import '../l10n/l10n.dart';

const List<String> _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _two(int value) => value.toString().padLeft(2, '0');

String _clock(DateTime time) => '${_two(time.hour)}:${_two(time.minute)}';

/// Persian digits when the app language is Persian.
String _digits(String text) => L10n.isPersian ? toPersianDigits(text) : text;

/// The Jalali date of [local]. Falls back to the Gregorian one for days
/// outside the years the Jalali calendar supports.
CalendarDate _jalali(DateTime local) {
  try {
    return CalendarSystems.jalali.fromDate(local);
  } on RangeError {
    return CalendarDate(local.year, local.month, local.day);
  }
}

/// 1405/07/26 in Persian digits.
String _jalaliNumeric(DateTime local) {
  final d = _jalali(local);
  return _digits('${d.year}/${_two(d.month)}/${_two(d.day)}');
}

/// Short, human-friendly timestamp in the device's local time zone.
/// In Persian, dates are Jalali with Persian digits.
String formatTimestamp(DateTime time, {required DateTime now}) {
  final local = time.toLocal();
  final current = now.toLocal();
  final difference = current.difference(local);
  if (difference.inSeconds < 60) return tr('just now');
  if (difference.inMinutes < 60) {
    return tr('{n} min ago', {'n': difference.inMinutes});
  }

  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(local.year, local.month, local.day);
  final days = today.difference(day).inDays;
  if (days == 0) return _digits(_clock(local));
  if (days == 1) {
    return tr('Yesterday {time}', {'time': _digits(_clock(local))});
  }
  if (L10n.isPersian) {
    final d = _jalali(local);
    if (local.year == current.year) {
      final month = CalendarNames.month('jalali', d.month, persian: true);
      return '${_digits('${d.day}')} $month، ${_digits(_clock(local))}';
    }
    return _jalaliNumeric(local);
  }
  if (local.year == current.year) {
    return '${_months[local.month - 1]} ${local.day}, ${_clock(local)}';
  }
  return '${local.year}-${_two(local.month)}-${_two(local.day)}';
}

/// Full timestamp for the detail screen.
String formatFullTimestamp(DateTime time) {
  final local = time.toLocal();
  if (L10n.isPersian) {
    return '${_jalaliNumeric(local)} '
        '${_digits('${_clock(local)}:${_two(local.second)}')}';
  }
  return '${local.year}-${_two(local.month)}-${_two(local.day)} '
      '${_clock(local)}:${_two(local.second)}';
}

/// Compact stamp for file names, for example 20261013-142530.
String formatFileStamp(DateTime time) {
  final local = time.toLocal();
  return '${local.year}${_two(local.month)}${_two(local.day)}-'
      '${_two(local.hour)}${_two(local.minute)}${_two(local.second)}';
}

/// Date and time of a due or reminder time, in local time: 2026-10-18 09:00.
String formatDue(DateTime time) {
  final local = time.toLocal();
  if (L10n.isPersian) {
    return '${_jalaliNumeric(local)} ${_digits(_clock(local))}';
  }
  return '${local.year}-${_two(local.month)}-${_two(local.day)} '
      '${_clock(local)}';
}

/// Hour and minute in local time: 09:00.
String formatTimeOfDay(DateTime time) => _digits(_clock(time.toLocal()));

/// The date of a day without a time: 2026-10-18, or 1405/07/26 in Persian.
String formatDay(DateTime day) {
  final local = day.toLocal();
  if (L10n.isPersian) return _jalaliNumeric(local);
  return '${local.year}-${_two(local.month)}-${_two(local.day)}';
}
