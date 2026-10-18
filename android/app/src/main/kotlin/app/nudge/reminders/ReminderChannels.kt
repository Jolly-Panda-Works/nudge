package app.nudge.reminders

import android.app.Activity
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** The method channel used by lib/platform/method_channel_reminder_platform.dart. */
object ReminderChannels {
    private const val CHANNEL = "app.nudge/reminders"
    private const val REQUEST_CODE = 0x4E45

    fun register(messenger: BinaryMessenger, activity: Activity) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            handle(activity, call, result)
        }
    }

    private fun handle(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        val context = activity.applicationContext
        when (call.method) {
            "permissions" -> result.success(
                mapOf(
                    "notifications" to notificationsAllowed(context),
                    "exactAlarms" to ReminderScheduler.canScheduleExact(context),
                ),
            )
            "requestNotificationPermission" -> result.success(requestNotifications(activity))
            "openNotificationSettings" -> result.success(openNotificationSettings(activity))
            "openExactAlarmSettings" -> result.success(openExactAlarmSettings(activity))
            "sync" -> {
                val raw = call.argument<List<Map<String, Any?>>>("entries")
                if (raw == null) {
                    result.error("bad_args", "entries is required", null)
                } else {
                    val entries = raw.mapNotNull { item ->
                        val id = item["taskId"] as? String
                        val at = (item["atMillis"] as? Number)?.toLong()
                        if (id.isNullOrEmpty() || at == null) {
                            null
                        } else {
                            ReminderStore.Entry(id, item["title"] as? String ?: "", at)
                        }
                    }
                    ReminderScheduler.replaceAll(context, entries)
                    result.success(null)
                }
            }
            "drainEvents" -> result.success(ReminderStore.drainEvents(context))
            else -> result.notImplemented()
        }
    }

    private fun notificationsAllowed(context: Context): Boolean {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return manager.areNotificationsEnabled()
    }

    /** True when alerts are already allowed; otherwise asks (Android 13 and later) and returns false. */
    private fun requestNotifications(activity: Activity): Boolean {
        if (notificationsAllowed(activity.applicationContext)) return true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.requestPermissions(
                arrayOf("android.permission.POST_NOTIFICATIONS"),
                REQUEST_CODE,
            )
        }
        return false
    }

    private fun openNotificationSettings(activity: Activity): Boolean {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)
        return start(activity, intent)
    }

    private fun openExactAlarmSettings(activity: Activity): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return false
        val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
            .setData(Uri.parse("package:" + activity.packageName))
        return start(activity, intent)
    }

    private fun start(activity: Activity, intent: Intent): Boolean {
        return try {
            activity.startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }
}
