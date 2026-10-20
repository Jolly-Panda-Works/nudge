# Localization

Nudge is available in **English** and **Persian (فارسی)**. Persian switches the whole app to right-to-left, uses Persian digits and shows dates in the Jalali calendar.

## Choosing the language
Settings > Language: *System default* (follows the device: Persian if the device language is Persian, English otherwise), *English* or *فارسی*. The choice is stored in the settings table (key `language`). Changing it rebuilds every open screen in place (the Settings screen stays open).

## How texts are translated
- The English text is the source. Code writes `tr('Delete task?')`; in Persian `tr` looks the English text up in `lib/l10n/fa_strings.dart`. A text without an entry is shown in English.
- Placeholders: `tr('Deleted {count} tasks', {'count': n})`. Whole numbers (`int`) get Persian digits in Persian; other values are inserted unchanged. Persian entries must keep the same placeholders.
- `tr` reads one global language (`L10n`), set by the app root before screens are built, so it works anywhere, including outside widgets. `LanguageController` holds the setting.
- Material widgets (date and time pickers, dialogs) use `flutter_localizations` for English and Persian.

## Adding or changing a text
1. Write the text with `tr('...')` (no `const` around it; adjacent string pieces are fine for long texts).
2. Add the Persian entry to `lib/l10n/fa_strings.dart`.
3. `test/l10n/translations_test.dart` fails if a text passed to `tr` has no Persian entry, if an entry is no longer used, or if a placeholder differs.

Texts that are not translated on purpose: the app name, package names, file names, the language names in the language dialog, and the data in the export file.

## Dates and times
- Persian: relative times ("۵ دقیقه پیش", "دیروز ۰۹:۰۵"), older times as a Jalali date, full timestamps as `۱۴۰۵/۰۷/۲۶ ۰۹:۰۰`. English formats are unchanged.
- The calendar shows Persian names and digits when the calendar system is Jalali **or** the app language is Persian; Jalali is always laid out right to left and Gregorian left to right (see CALENDAR.md).

## Known gaps
- Not compiled or run: CI is the first check, and the Persian texts were not reviewed by a native speaker. Please read them on a device and report wording that sounds wrong.
- Android's own permission dialogs and system settings screens follow the device language, not the app language.
- The reminder alert on the lock screen ("Reminder", "Snooze 10 min") and its channel name are written in the Kotlin code and are still English.
- Terms used: *وظیفه* (task), *یادآور* (reminder), *اعلان* (notification), *تعویق* (snooze), *بایگانی* (archive).
