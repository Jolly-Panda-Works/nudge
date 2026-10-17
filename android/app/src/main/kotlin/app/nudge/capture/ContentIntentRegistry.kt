package app.nudge.capture

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
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

    /** Fires the live content action. False when it is gone or was cancelled. */
    fun send(key: String): Boolean {
        val intent = intents[key] ?: return false
        return try {
            intent.send()
            true
        } catch (e: PendingIntent.CanceledException) {
            intents.remove(key)
            false
        } catch (e: Exception) {
            false
        }
    }

    /** Opens the launcher activity of a package. False when there is none. */
    fun openLauncher(context: Context, packageName: String): Boolean {
        if (packageName.isEmpty()) return false
        val launch = context.packageManager.getLaunchIntentForPackage(packageName)
            ?: return false
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(launch)
            true
        } catch (e: Exception) {
            false
        }
    }
}
