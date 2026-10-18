package app.nudge.reminders

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

/** Shows the alert for a reminder. The text is the task title the user wrote. */
internal object ReminderNotifier {
    private const val CHANNEL_ID = "nudge_reminders"

    fun notificationId(taskId: String): Int = taskId.hashCode()

    private fun manager(context: Context): NotificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun ensureChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Reminders",
            NotificationManager.IMPORTANCE_HIGH,
        )
        channel.description = "Alerts for the reminders you set in Nudge"
        manager.createNotificationChannel(channel)
    }

    fun show(context: Context, taskId: String, title: String) {
        val manager = manager(context)
        ensureChannel(manager)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }

        val icon = context.applicationInfo.icon
        builder.setSmallIcon(if (icon != 0) icon else android.R.drawable.ic_popup_reminder)
        builder.setContentTitle(if (title.isEmpty()) "Reminder" else title)
        builder.setContentText("Reminder")
        builder.setAutoCancel(true)
        builder.setCategory(Notification.CATEGORY_REMINDER)

        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
        if (launch != null) {
            builder.setContentIntent(
                PendingIntent.getActivity(
                    context,
                    taskId.hashCode(),
                    launch,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )
        }

        val snooze = Intent(context, ReminderReceiver::class.java)
            .setAction(ReminderScheduler.ACTION_SNOOZE)
            .putExtra(ReminderScheduler.EXTRA_TASK_ID, taskId)
            .putExtra(ReminderScheduler.EXTRA_TITLE, title)
        val snoozePending = PendingIntent.getBroadcast(
            context,
            taskId.hashCode() xor 0x5A5A,
            snooze,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        @Suppress("DEPRECATION")
        builder.addAction(0, "Snooze 10 min", snoozePending)

        try {
            manager.notify(notificationId(taskId), builder.build())
        } catch (e: SecurityException) {
            // Notifications are not allowed; the Settings screen explains how to fix it.
        }
    }

    fun cancel(context: Context, taskId: String) {
        manager(context).cancel(notificationId(taskId))
    }
}
