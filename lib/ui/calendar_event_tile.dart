import 'package:flutter/material.dart';

import '../domain/calendar/calendar_names.dart';
import '../domain/external_event.dart';
import '../l10n/l10n.dart';
import 'time_format.dart';

/// The colour of an event: its calendar's colour, or a neutral grey.
Color eventColor(ExternalEvent event) => Color(event.color ?? 0xFF9E9E9E);

/// One event of a device calendar in a list. It looks different from a task
/// or a reminder: a coloured calendar icon instead of a check or alarm.
class CalendarEventTile extends StatelessWidget {
  const CalendarEventTile({
    required this.event,
    required this.persian,
    required this.onTap,
    this.showTime = true,
    super.key,
  });

  final ExternalEvent event;
  final bool persian;
  final VoidCallback onTap;

  /// False where the time is already shown by the surrounding layout.
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (showTime) eventTimeText(event, persian: persian),
      if (event.calendarLabel.isNotEmpty) event.calendarLabel,
    ];
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Icon(Icons.event, color: eventColor(event)),
      title: Text(
        event.title.isEmpty ? tr('(no title)') : event.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: parts.isEmpty ? null : Text(parts.join(' · ')),
    );
  }
}

/// "All day", or "09:00 – 10:30".
String eventTimeText(ExternalEvent event, {required bool persian}) {
  if (event.allDay) return tr('All day');
  final text =
      '${formatTimeOfDay(event.start)} – ${formatTimeOfDay(event.end)}';
  return persian ? CalendarNames.toPersianDigits(text) : text;
}

/// A read-only look at an event, with a way to open it in the calendar app.
Future<void> showEventDetails(
  BuildContext context,
  ExternalEvent event, {
  required Future<bool> Function() onOpenInCalendarApp,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(event.title.isEmpty ? tr('(no title)') : event.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.calendarLabel.isNotEmpty)
            Row(
              children: [
                Icon(Icons.event, size: 18, color: eventColor(event)),
                const SizedBox(width: 8),
                Flexible(child: Text(event.calendarLabel)),
              ],
            ),
          const SizedBox(height: 12),
          if (event.allDay)
            Text('${formatDay(event.start)} · ${tr('All day')}')
          else ...[
            Text(formatDue(event.start)),
            Text(formatDue(event.end)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final opened = await onOpenInCalendarApp();
            if (!dialogContext.mounted) return;
            if (!opened) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text(tr('Could not open the calendar app.'))),
              );
            }
          },
          child: Text(tr('Open in calendar app')),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(tr('Close')),
        ),
      ],
    ),
  );
}
