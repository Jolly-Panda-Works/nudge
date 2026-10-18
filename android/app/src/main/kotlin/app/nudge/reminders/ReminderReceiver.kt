package app.nudge.reminders

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Receives the alarm for a reminder and the Snooze button of its alert. */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val taskId = intent.getStringExtra(ReminderScheduler.EXTRA_TASK_ID) ?: return
        val title = intent.getStringExtra(ReminderScheduler.EXTRA_TITLE) ?: ""
        when (intent.action) {
            ReminderScheduler.ACTION_FIRE -> {
                ReminderStore.remove(context, taskId)
                ReminderNotifier.show(context, taskId, title)
            }
            ReminderScheduler.ACTION_SNOOZE -> {
                ReminderNotifier.cancel(context, taskId)
                ReminderScheduler.snooze(context, taskId, title)
            }
        }
    }
}
