package app.nudge.reminders

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/**
 * The reminders the alarms were set for, plus snoozes done from the alert
 * that the Dart side has not seen yet. Kept in a file in private no-backup
 * storage so the alarms can be set again after a restart without the app
 * running. Holds task ids, titles and times; the content is never logged.
 */
internal object ReminderStore {
    private const val FILE = "reminders.json"
    private const val MAX_EVENTS = 500

    data class Entry(val taskId: String, val title: String, val atMillis: Long)

    @Synchronized
    fun entries(context: Context): List<Entry> {
        val array = read(context).optJSONArray("entries") ?: return emptyList()
        val list = ArrayList<Entry>(array.length())
        for (i in 0 until array.length()) {
            val item = array.optJSONObject(i) ?: continue
            val id = item.optString("taskId", "")
            if (id.isEmpty()) continue
            list.add(Entry(id, item.optString("title", ""), item.optLong("atMillis", 0L)))
        }
        return list
    }

    @Synchronized
    fun saveEntries(context: Context, entries: List<Entry>) {
        val root = read(context)
        val array = JSONArray()
        for (e in entries) {
            array.put(
                JSONObject()
                    .put("taskId", e.taskId)
                    .put("title", e.title)
                    .put("atMillis", e.atMillis),
            )
        }
        root.put("entries", array)
        write(context, root)
    }

    @Synchronized
    fun upsert(context: Context, entry: Entry) {
        val list = entries(context).filter { it.taskId != entry.taskId } + entry
        saveEntries(context, list)
    }

    @Synchronized
    fun remove(context: Context, taskId: String) {
        saveEntries(context, entries(context).filter { it.taskId != taskId })
    }

    @Synchronized
    fun addSnoozeEvent(context: Context, taskId: String, untilMillis: Long) {
        val root = read(context)
        val old = root.optJSONArray("events") ?: JSONArray()
        val array = JSONArray()
        val start = maxOf(0, old.length() - (MAX_EVENTS - 1))
        for (i in start until old.length()) array.put(old.get(i))
        array.put(
            JSONObject()
                .put("type", "snoozed")
                .put("taskId", taskId)
                .put("untilMillis", untilMillis),
        )
        root.put("events", array)
        write(context, root)
    }

    /** Returns every pending event as a JSON line and clears them. */
    @Synchronized
    fun drainEvents(context: Context): List<String> {
        val root = read(context)
        val array = root.optJSONArray("events") ?: return emptyList()
        val lines = ArrayList<String>(array.length())
        for (i in 0 until array.length()) {
            val item = array.optJSONObject(i) ?: continue
            lines.add(item.toString())
        }
        root.put("events", JSONArray())
        write(context, root)
        return lines
    }

    private fun file(context: Context) = File(context.noBackupFilesDir, FILE)

    private fun read(context: Context): JSONObject {
        val f = file(context)
        if (!f.exists()) return JSONObject()
        return try {
            JSONObject(f.readText())
        } catch (e: Exception) {
            JSONObject()
        }
    }

    private fun write(context: Context, root: JSONObject) {
        val target = file(context)
        val temp = File(target.parentFile, "$FILE.tmp")
        temp.writeText(root.toString())
        if (!temp.renameTo(target)) {
            target.writeText(root.toString())
            temp.delete()
        }
    }
}
