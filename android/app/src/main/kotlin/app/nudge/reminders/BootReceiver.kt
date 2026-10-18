package app.nudge.reminders

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Sets the reminder alarms again after a restart, an update or a permission change. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        ReminderScheduler.rescheduleAll(context)
    }
}
