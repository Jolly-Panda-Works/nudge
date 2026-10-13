package app.nudge.capture

import android.app.PendingIntent
import java.util.concurrent.ConcurrentHashMap

/**
 * In-memory only. A PendingIntent is not durable or serializable, so it is
 * never written to disk or sent to Dart; it is dropped when the notification is
 * removed or the listener disconnects.
 */
internal object ContentIntentRegistry {
    private val intents = ConcurrentHashMap<String, PendingIntent>()

    fun put(key: String, intent: PendingIntent?) {
        if (intent != null) intents[key] = intent else intents.remove(key)
    }

    fun remove(key: String) {
        intents.remove(key)
    }

    fun clear() {
        intents.clear()
    }

    fun has(key: String): Boolean = intents.containsKey(key)
}
