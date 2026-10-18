/// Names and digits for showing dates. English and Persian only; the rest of
/// the app text is localized in a later step.
abstract final class CalendarNames {
  static const List<String> jalaliMonthsFa = <String>[
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static const List<String> jalaliMonthsEn = <String>[
    'Farvardin',
    'Ordibehesht',
    'Khordad',
    'Tir',
    'Mordad',
    'Shahrivar',
    'Mehr',
    'Aban',
    'Azar',
    'Dey',
    'Bahman',
    'Esfand',
  ];

  static const List<String> gregorianMonthsEn = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> gregorianMonthsFa = <String>[
    'ژانویه',
    'فوریه',
    'مارس',
    'آوریل',
    'مه',
    'ژوئن',
    'ژوئیه',
    'اوت',
    'سپتامبر',
    'اکتبر',
    'نوامبر',
    'دسامبر',
  ];

  /// Index 0 is Monday ... 6 is Sunday, like `DateTime.weekday - 1`.
  static const List<String> weekdaysEn = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> weekdaysShortEn = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  // \u200C is the zero-width non-joiner used in Persian spelling.
  static const List<String> weekdaysFa = <String>[
    'دوشنبه',
    'سه\u200Cشنبه',
    'چهارشنبه',
    'پنجشنبه',
    'جمعه',
    'شنبه',
    'یکشنبه',
  ];

  /// One-letter names, as in most Persian calendars.
  static const List<String> weekdaysShortFa = <String>[
    'د',
    'س',
    'چ',
    'پ',
    'ج',
    'ش',
    'ی',
  ];

  /// Name of [month] (1-12) in the calendar system with id [systemId].
  static String month(String systemId, int month, {required bool persian}) {
    if (month < 1 || month > 12) {
      throw RangeError.range(month, 1, 12, 'month');
    }
    final names = switch ((systemId, persian)) {
      ('jalali', true) => jalaliMonthsFa,
      ('jalali', false) => jalaliMonthsEn,
      (_, true) => gregorianMonthsFa,
      (_, false) => gregorianMonthsEn,
    };
    return names[month - 1];
  }

  /// Name of a weekday given as `DateTime.weekday` (1 = Monday ... 7 = Sunday).
  static String weekday(int weekday, {required bool persian, bool short = false}) {
    if (weekday < 1 || weekday > 7) {
      throw RangeError.range(weekday, 1, 7, 'weekday');
    }
    final names = persian
        ? (short ? weekdaysShortFa : weekdaysFa)
        : (short ? weekdaysShortEn : weekdaysEn);
    return names[weekday - 1];
  }

  /// Replaces the digits 0-9 with the Persian digits ۰-۹.
  static String toPersianDigits(String text) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (final unit in text.codeUnits) {
      if (unit >= 0x30 && unit <= 0x39) {
        buffer.write(persian[unit - 0x30]);
      } else {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }

  /// A number as text, in Persian digits when [persian] is true.
  static String number(int value, {required bool persian}) =>
      persian ? toPersianDigits('$value') : '$value';
}
