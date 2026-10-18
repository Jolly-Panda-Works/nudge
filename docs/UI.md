# UI: themes, layouts and accessibility

## Themes
Settings > Theme: *System default*, *Light* or *Dark* (settings key `theme_mode`). The app uses one Material 3 colour scheme (seed: indigo) for both; screens take their colours from the scheme, so nothing is hard-coded for one theme. Changing the theme applies at once and keeps the Settings screen open (the language change, by contrast, rebuilds every screen).

## Wide layouts
- `wideBreakpoint` is 840 logical pixels (`lib/ui/content_width.dart`).
- **Calendar, month view:** at or above the breakpoint the month and the selected day's list are side by side; below it they are stacked.
- **Calendar, week view:** at or above the breakpoint the seven days are columns; below it they are rows.
- **Other screens** (inbox, tasks, settings, details, forms, app filter): the content is centred and at most 720 px wide (`ContentWidth`), so lines stay readable on tablets and Windows windows.
- Not done: a two-pane inbox (list and details side by side), keyboard shortcuts and mouse-hover states for Windows.

## Accessibility
Done in code (not verified with a screen reader):
- **Large text:** widget tests render the four calendar views at double text size on a 400 x 800 screen, and Settings and Tasks at 1.5 times, and fail on any overflow. Segmented buttons scroll sideways instead of overflowing; day cells scale down instead of overflowing.
- **Spoken labels:** every calendar day has a label (weekday, date, task count) and a selected state; icon buttons have tooltips; the task checkbox has a label.
- **Touch targets:** buttons and list rows use the Material minimum sizes; calendar days are at least as large as the grid allows (they shrink only on very small screens).
- **Colour:** meaning is never carried by colour alone: today has an outline, the selected day a filled circle, tasks are dots plus a list, Friday is also labelled by its name.
- **Direction:** Persian is right to left throughout; the Jalali grid is right to left even when the app is English.

Still to do, on a device: a TalkBack pass (reading order, announcements when the view changes), checking contrast of the dot colours and dimmed days in both themes, and Windows Narrator.
