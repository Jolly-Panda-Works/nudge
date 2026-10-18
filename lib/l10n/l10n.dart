import 'fa_strings.dart';

/// The app language: English text is the source, and `tr` looks up its
/// Persian translation when the language is Persian.
///
/// The language is a single global value, set by the app root before the
/// screens are built, so `tr` can be used anywhere (also outside widgets).
abstract final class L10n {
  /// `en` or `fa`.
  static String _language = 'en';

  static String get language => _language;

  static bool get isPersian => _language == 'fa';

  /// Sets the language; anything other than `fa` means English.
  static void setLanguage(String code) {
    _language = code == 'fa' ? 'fa' : 'en';
  }

  /// The language a device locale code (`fa`, `fa_IR`, `en_US`...) maps to.
  static String resolve(String setting, String deviceLanguageCode) {
    if (setting == 'fa' || setting == 'en') return setting;
    return deviceLanguageCode.toLowerCase().startsWith('fa') ? 'fa' : 'en';
  }
}

/// Translates [english] into the current language and fills `{name}`
/// placeholders from [params]. Whole numbers are written with Persian digits
/// when the language is Persian; other values are inserted as they are.
///
/// A text without a Persian translation is shown in English (a test checks
/// that every text passed to `tr` has one).
String tr(String english, [Map<String, Object?> params = const {}]) {
  var text = L10n.isPersian ? (faStrings[english] ?? english) : english;
  if (params.isNotEmpty) {
    params.forEach((name, value) {
      final shown = value is int && L10n.isPersian
          ? toPersianDigits('$value')
          : '$value';
      text = text.replaceAll('{$name}', shown);
    });
  }
  return text;
}

/// Replaces the digits 0-9 with the Persian digits ۰-۹.
String toPersianDigits(String text) {
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
