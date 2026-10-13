package app.nudge.capture

import android.app.Notification
import android.content.Context
import android.content.pm.PackageManager
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.ConcurrentHashMap

/** Converts a StatusBarNotification into the plain map Dart expects. */
internal object NotificationPayloadMapper {
    private val labelCache = ConcurrentHashMap<String, String>()

    fun toPayload(context: Context, sbn: StatusBarNotification): JSONObject {
        val notification = sbn.notification
        val extras = notification.extras
        val title = extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString()
        val text = (
            extras?.getCharSequence(Notification.EXTRA_BIG_TEXT)
                ?: extras?.getCharSequence(Notification.EXTRA_TEXT)
            )?.toString()

        val actionTitles = JSONArray()
        notification.actions?.forEach { action ->
            action.title?.toString()?.let { actionTitles.put(it) }
        }

        val flags = notification.flags
        val ongoingMask = Notification.FLAG_ONGOING_EVENT or Notification.FLAG_FOREGROUND_SERVICE

        val payload = JSONObject()
        payload.put("key", sbn.key)
        payload.put("packageName", sbn.packageName)
        payload.put("postTimeMillis", sbn.postTime)
        payload.put("isGroupSummary", (flags and Notification.FLAG_GROUP_SUMMARY) != 0)
        payload.put("isOngoing", (flags and ongoingMask) != 0)
        payload.put("hasContentAction", notification.contentIntent != null)
        payload.put("actionTitles", actionTitles)
        payload.put("redactedHint", notification.visibility == Notification.VISIBILITY_SECRET)
        appLabel(context, sbn.packageName)?.let { payload.put("appLabel", it) }
        title?.let { payload.put("title", it) }
        text?.let { payload.put("text", it) }
        sbn.groupKey?.let { payload.put("groupKey", it) }
        return payload
    }

    private fun appLabel(context: Context, packageName: String): String? {
        labelCache[packageName]?.let { return it }
        return try {
            val pm = context.packageManager
            @Suppress("DEPRECATION")
            val label = pm.getApplicationLabel(pm.getApplicationInfo(packageName, 0)).toString()
            labelCache[packageName] = label
            label
        } catch (e: PackageManager.NameNotFoundException) {
            null
        }
    }
}
