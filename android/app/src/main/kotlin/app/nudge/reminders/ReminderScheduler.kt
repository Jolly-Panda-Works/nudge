package app.nudge.reminders

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

/** Sets and cancels the system alarms for reminders. */
internal object ReminderScheduler {
    const val ACTION_FIRE = "app.nudge.reminders.FIRE"
    const val ACTION_SNOOZE = "app.nudge.reminders.SNOOZE"
    const val EXTRA_TASK_ID = "taskId"
    const val EXTRA_TITLE = "title"
    const val SNOOZE_MILLIS = 10L * 60L * 1000L

    private fun alarmManager(context: Context): AlarmManager =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    /** Exact alarms need a permission the user can switch off on Android 12 and later. */
    fun canScheduleExact(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            alarmManager(context).canScheduleExactAlarms()

    private fun firePending(context: Context, taskId: String, title: String): PendingIntent {
        val intent = Intent(context, ReminderReceiver::class.java)
            .setAction(ACTION_FIRE)
            .putExtra(EXTRA_TASK_ID, taskId)
            .putExtra(EXTRA_TITLE, title)
        return PendingIntent.getBroadcast(
            context,
            taskId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    fun setAlarm(context: Context, entry: ReminderStore.Entry) {
        val manager = alarmManager(context)
        val pending = firePending(context, entry.taskId, entry.title)
        try {
            if (canScheduleExact(context)) {
                manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, entry.atMillis, pending)
            } else {
                manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, entry.atMillis, pending)
            }
        } catch (e: SecurityException) {
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, entry.atMillis, pending)
        }
    }

    private fun cancelAlarm(context: Context, entry: ReminderStore.Entry) {
        val pending = firePending(context, entry.taskId, entry.title)
        alarmManager(context).cancel(pending)
        pending.cancel()
    }

    /** Makes the alarms match [entries] exactly. */
    fun replaceAll(context: Context, entries: List<ReminderStore.Entry>) {
        for (old in ReminderStore.entries(context)) cancelAlarm(context, old)
        ReminderStore.saveEntries(context, entries)
        for (entry in entries) setAlarm(context, entry)
    }

    /**
     * After a restart or an update: set the alarms again. A reminder whose time
     * passed while the device was off is shown now instead of being lost.
     */
    fun rescheduleAll(context: Context) {
        val now = System.currentTimeMillis()
        for (entry in ReminderStore.entries(context)) {
            if (entry.atMillis <= now + 1000L) {
                ReminderStore.remove(context, entry.taskId)
                ReminderNotifier.show(context, entry.taskId, entry.title)
            } else {
                setAlarm(context, entry)
            }
        }
    }

    fun snooze(context: Context, taskId: String, title: String) {
        val until = System.currentTimeMillis() + SNOOZE_MILLIS
        val entry = ReminderStore.Entry(taskId, title, until)
        ReminderStore.upsert(context, entry)
        ReminderStore.addSnoozeEvent(context, taskId, until)
        setAlarm(context, entry)
    }
}
