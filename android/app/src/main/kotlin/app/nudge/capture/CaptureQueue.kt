package app.nudge.capture

import android.content.Context
import org.json.JSONException
import org.json.JSONObject
import java.io.File

/**
 * Small durable queue (JSON lines) between the listener service and Flutter.
 *
 * It lets captures survive while the Flutter engine is not running. The file
 * lives in the no-backup directory and is deleted as soon as Dart acknowledges
 * the events, so notification text is kept for as short a time as possible.
 * Events are never logged.
 */
internal class CaptureQueue(
    private val file: File,
    private val maxEvents: Int = 1000,
) {
    private val lock = Any()
    private var nextSeq: Long = 0L

    fun append(event: JSONObject) {
        synchronized(lock) {
            val lines = readLines()
            if (nextSeq == 0L) nextSeq = lastSeq(lines) + 1
            event.put("seq", nextSeq)
            nextSeq += 1
            lines.add(event.toString())
            writeLines(if (lines.size > maxEvents) lines.takeLast(maxEvents) else lines)
        }
    }

    /** Oldest events first, as raw JSON strings that each contain "seq". */
    fun peek(max: Int): List<String> = synchronized(lock) {
        readLines().filter { seqOf(it) != null }.take(max)
    }

    /** Removes every event with seq <= [upToSeq] (and any unreadable line). */
    fun ack(upToSeq: Long) {
        synchronized(lock) {
            val remaining = readLines().filter { line ->
                val seq = seqOf(line)
                seq != null && seq > upToSeq
            }
            if (remaining.isEmpty()) {
                file.delete()
            } else {
                writeLines(remaining)
            }
        }
    }

    /** Drops every queued event (used by "delete all data"). */
    fun clear() {
        synchronized(lock) {
            file.delete()
        }
    }

    private fun seqOf(line: String): Long? = try {
        JSONObject(line).getLong("seq")
    } catch (e: JSONException) {
        null
    }

    private fun lastSeq(lines: List<String>): Long =
        lines.asReversed().firstNotNullOfOrNull { seqOf(it) } ?: 0L

    private fun readLines(): MutableList<String> =
        if (file.exists()) {
            file.readLines().filter { it.isNotBlank() }.toMutableList()
        } else {
            mutableListOf()
        }

    private fun writeLines(lines: List<String>) {
        val tmp = File(file.parentFile, file.name + ".tmp")
        tmp.writeText(lines.joinToString(separator = "\n", postfix = "\n"))
        if (!tmp.renameTo(file)) {
            file.delete()
            tmp.renameTo(file)
        }
    }
}

internal object CaptureQueues {
    @Volatile
    private var instance: CaptureQueue? = null

    fun get(context: Context): CaptureQueue =
        instance ?: synchronized(this) {
            instance ?: CaptureQueue(
                File(context.applicationContext.noBackupFilesDir, "capture_queue.jsonl"),
            ).also { instance = it }
        }
}
