package app.nudge.capture

import android.content.ComponentName
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

/**
 * Listens to notifications that Android exposes to a user-approved Notification
 * Access listener. It never uses an Accessibility Service, root or hidden APIs.
 *
 * Every event is appended to [CaptureQueue]; Flutter is only told "something
 * arrived" and drains the queue itself. Notification content is never logged.
 */
class NotificationCaptureService : NotificationListenerService() {

    override fun onListenerConnected() {
        super.onListenerConnected()
        CaptureState.serviceConnected = true
        reconcileActiveNotifications()
        CaptureState.emit(mapOf("type" to "state", "connected" to true))
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        CaptureState.serviceConnected = false
        ContentIntentRegistry.clear()
        CaptureState.emit(mapOf("type" to "state", "connected" to false))
        try {
            NotificationListenerService.requestRebind(
                ComponentName(this, NotificationCaptureService::class.java),
            )
        } catch (e: Exception) {
            // Access was probably revoked; nothing to rebind.
            Log.i(TAG, "Rebind not possible (${e.javaClass.simpleName})")
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        capture(sbn)
        wakeFlutter()
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        if (sbn == null) return
        ContentIntentRegistry.remove(sbn.key)
        try {
            CaptureQueues.get(this).append(
                JSONObject().put("type", "removed").put("key", sbn.key),
            )
        } catch (e: Exception) {
            Log.w(TAG, "Could not queue a removal (${e.javaClass.simpleName})")
        }
        wakeFlutter()
    }

    /** Queues all currently active notifications plus a snapshot of their keys. */
    private fun reconcileActiveNotifications() {
        val active: Array<StatusBarNotification>? = try {
            activeNotifications
        } catch (e: SecurityException) {
            null
        }
        if (active == null) return

        val keys = JSONArray()
        for (sbn in active) {
            capture(sbn)
            keys.put(sbn.key)
        }
        try {
            CaptureQueues.get(this).append(
                JSONObject().put("type", "snapshot").put("keys", keys),
            )
        } catch (e: Exception) {
            Log.w(TAG, "Could not queue the active snapshot (${e.javaClass.simpleName})")
        }
        wakeFlutter()
    }

    private fun capture(sbn: StatusBarNotification) {
        try {
            val payload = NotificationPayloadMapper.toPayload(applicationContext, sbn)
            ContentIntentRegistry.put(sbn.key, sbn.notification.contentIntent)
            CaptureQueues.get(this).append(
                JSONObject().put("type", "posted").put("payload", payload),
            )
        } catch (e: Exception) {
            Log.w(TAG, "Could not capture a notification (${e.javaClass.simpleName})")
        }
    }

    private fun wakeFlutter() {
        CaptureState.emit(mapOf("type" to "wake"))
    }

    private companion object {
        const val TAG = "NudgeCapture"
    }
}
