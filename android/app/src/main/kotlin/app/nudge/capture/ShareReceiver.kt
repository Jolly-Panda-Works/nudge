package app.nudge.capture

import android.content.Context
import android.content.Intent
import android.util.Log
import org.json.JSONObject

/**
 * Queues plain text that the user shares with Nudge from another app
 * (ACTION_SEND with a text MIME type). The text is chosen by the user, so it is stored like
 * a captured notification but is not subject to the app filters. Content is
 * never logged.
 */
object ShareReceiver {
    private const val TAG = "NudgeShare"

    fun handle(context: Context, intent: Intent?) {
        if (intent == null || intent.action != Intent.ACTION_SEND) return
        val type = intent.type ?: return
        if (!type.startsWith("text/")) return

        val text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()?.trim()
        if (text.isNullOrEmpty()) return
        val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)
            ?: intent.getStringExtra(Intent.EXTRA_TITLE)

        val event = JSONObject()
            .put("type", "shared")
            .put("text", text)
            .put("postTimeMillis", System.currentTimeMillis())
        if (!subject.isNullOrBlank()) event.put("title", subject)

        try {
            CaptureQueues.get(context).append(event)
        } catch (e: Exception) {
            Log.w(TAG, "Could not queue shared text (${e.javaClass.simpleName})")
            return
        }
        CaptureState.emit(mapOf("type" to "wake"))
    }
}
