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

/// Short, human-friendly timestamp in the device's local time zone.
/// Gregorian only; Jalali display arrives with the calendar milestone.
String formatTimestamp(DateTime time, {required DateTime now}) {
  final local = time.toLocal();
  final current = now.toLocal();
  final difference = current.difference(local);
  if (difference.inSeconds < 60) return 'just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';

  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(local.year, local.month, local.day);
  final days = today.difference(day).inDays;
  if (days == 0) return _clock(local);
  if (days == 1) return 'Yesterday ${_clock(local)}';
  if (local.year == current.year) {
    return '${_months[local.month - 1]} ${local.day}, ${_clock(local)}';
  }
  return '${local.year}-${_two(local.month)}-${_two(local.day)}';
}

/// Full timestamp for the detail screen.
String formatFullTimestamp(DateTime time) {
  final local = time.toLocal();
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
  return '${local.year}-${_two(local.month)}-${_two(local.day)} '
      '${_clock(local)}';
}

/// Hour and minute in local time: 09:00.
String formatTimeOfDay(DateTime time) => _clock(time.toLocal());
