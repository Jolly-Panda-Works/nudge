package app.nudge.calendars

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.CalendarContract
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Reads the calendars the system exposes through the Calendar Provider (the
 * accounts the user added to Android, such as Google or Samsung). Nothing is
 * read until the user turns the integration on and allows the permission.
 * Names and accounts are returned to the app and never logged.
 */
object CalendarChannels {
    private const val CHANNEL = "app.nudge/calendars"
    private const val REQUEST_CODE = 0x4E46

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
                    "read" to granted(context, Manifest.permission.READ_CALENDAR),
                    "write" to granted(context, Manifest.permission.WRITE_CALENDAR),
                ),
            )
            "requestPermissions" -> result.success(requestPermissions(activity))
            "openAppSettings" -> result.success(openAppSettings(activity))
            "listCalendars" -> {
                try {
                    result.success(listCalendars(context))
                } catch (e: SecurityException) {
                    result.error("permission_denied", "Calendar permission is not granted", null)
                } catch (e: Exception) {
                    result.error("query_failed", "The calendars could not be read", null)
                }
            }
            "listEvents" -> {
                val from = (call.argument<Number>("fromMillis"))?.toLong()
                val to = (call.argument<Number>("toMillis"))?.toLong()
                val ids = call.argument<List<String>>("calendarIds")
                if (from == null || to == null || ids == null) {
                    result.error("bad_args", "fromMillis, toMillis and calendarIds are required", null)
                } else {
                    try {
                        result.success(listEvents(context, from, to, ids))
                    } catch (e: SecurityException) {
                        result.error("permission_denied", "Calendar permission is not granted", null)
                    } catch (e: Exception) {
                        result.error("query_failed", "The events could not be read", null)
                    }
                }
            }
            "openEvent" -> {
                val id = call.argument<String>("eventId")?.toLongOrNull()
                val begin = (call.argument<Number>("beginMillis"))?.toLong()
                val end = (call.argument<Number>("endMillis"))?.toLong()
                val allDay = call.argument<Boolean>("allDay") ?: false
                if (id == null || begin == null || end == null) {
                    result.error("bad_args", "eventId, beginMillis and endMillis are required", null)
                } else {
                    result.success(openEvent(activity, id, begin, end, allDay))
                }
            }
            "createEvent" -> writeCall(result) {
                val calendarId = call.argument<String>("calendarId")?.toLongOrNull()
                val values = eventValues(call)
                if (calendarId == null || values == null) {
                    result.error("bad_args", "calendarId, title and times are required", null)
                } else {
                    values.put(CalendarContract.Events.CALENDAR_ID, calendarId)
                    val uri = context.contentResolver.insert(CalendarContract.Events.CONTENT_URI, values)
                    val id = uri?.lastPathSegment
                    if (id == null) {
                        result.error("write_failed", "The event could not be saved", null)
                    } else {
                        result.success(id)
                    }
                }
            }
            "updateEvent" -> writeCall(result) {
                val eventId = call.argument<String>("eventId")?.toLongOrNull()
                val values = eventValues(call)
                if (eventId == null || values == null) {
                    result.error("bad_args", "eventId, title and times are required", null)
                } else {
                    val uri = ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, eventId)
                    result.success(context.contentResolver.update(uri, values, null, null) > 0)
                }
            }
            "deleteEvent" -> writeCall(result) {
                val eventId = call.argument<String>("eventId")?.toLongOrNull()
                if (eventId == null) {
                    result.error("bad_args", "eventId is required", null)
                } else {
                    val uri = ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, eventId)
                    result.success(context.contentResolver.delete(uri, null, null) > 0)
                }
            }
            "eventExists" -> {
                val eventId = call.argument<String>("eventId")?.toLongOrNull()
                if (eventId == null) {
                    result.success(false)
                } else {
                    try {
                        result.success(eventExists(context, eventId))
                    } catch (e: SecurityException) {
                        result.error("permission_denied", "Calendar permission is not granted", null)
                    } catch (e: Exception) {
                        result.error("query_failed", "The event could not be checked", null)
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun granted(context: Context, permission: String): Boolean =
        context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    /** True when reading is already allowed; otherwise asks and returns false. */
    private fun requestPermissions(activity: Activity): Boolean {
        val context = activity.applicationContext
        if (granted(context, Manifest.permission.READ_CALENDAR)) return true
        activity.requestPermissions(
            arrayOf(Manifest.permission.READ_CALENDAR, Manifest.permission.WRITE_CALENDAR),
            REQUEST_CODE,
        )
        return false
    }

    private fun openAppSettings(activity: Activity): Boolean {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.parse("package:" + activity.packageName))
        return try {
            activity.startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    private fun listCalendars(context: Context): List<Map<String, Any?>> {
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            CalendarContract.Calendars.ACCOUNT_NAME,
            CalendarContract.Calendars.ACCOUNT_TYPE,
            CalendarContract.Calendars.OWNER_ACCOUNT,
            CalendarContract.Calendars.CALENDAR_COLOR,
            CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
            CalendarContract.Calendars.VISIBLE,
        )
        val calendars = ArrayList<Map<String, Any?>>()
        val cursor = context.contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            null,
            null,
            CalendarContract.Calendars.ACCOUNT_NAME + " ASC, " +
                CalendarContract.Calendars.CALENDAR_DISPLAY_NAME + " ASC",
        ) ?: return calendars
        cursor.use {
            while (it.moveToNext()) {
                val accountName = it.getString(2) ?: ""
                val owner = it.getString(4) ?: ""
                val access = it.getInt(6)
                calendars.add(
                    mapOf(
                        "id" to it.getLong(0).toString(),
                        "displayName" to (it.getString(1) ?: ""),
                        "accountName" to accountName,
                        "accountType" to (it.getString(3) ?: ""),
                        "color" to if (it.isNull(5)) null else it.getInt(5),
                        "canWrite" to (access >= CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR),
                        "isOwner" to (owner.isNotEmpty() && owner == accountName),
                        "visible" to (it.getInt(7) != 0),
                    ),
                )
            }
        }
        return calendars
    }

    private const val MAX_INSTANCES = 3000

    /** The occurrences overlapping [from, to) in the given calendars; recurring events are expanded. */
    private fun listEvents(
        context: Context,
        from: Long,
        to: Long,
        calendarIds: List<String>,
    ): List<Map<String, Any?>> {
        val events = ArrayList<Map<String, Any?>>()
        if (calendarIds.isEmpty()) return events
        val builder = CalendarContract.Instances.CONTENT_URI.buildUpon()
        ContentUris.appendId(builder, from)
        ContentUris.appendId(builder, to)
        val projection = arrayOf(
            CalendarContract.Instances.EVENT_ID,
            CalendarContract.Instances.CALENDAR_ID,
            CalendarContract.Instances.TITLE,
            CalendarContract.Instances.BEGIN,
            CalendarContract.Instances.END,
            CalendarContract.Instances.ALL_DAY,
            CalendarContract.Instances.CALENDAR_COLOR,
        )
        val placeholders = calendarIds.joinToString(",") { "?" }
        val cursor = context.contentResolver.query(
            builder.build(),
            projection,
            CalendarContract.Instances.CALENDAR_ID + " IN (" + placeholders + ")",
            calendarIds.toTypedArray(),
            CalendarContract.Instances.BEGIN + " ASC",
        ) ?: return events
        val rows = ArrayList<Map<String, Any?>>()
        cursor.use {
            while (it.moveToNext() && rows.size < MAX_INSTANCES) {
                rows.add(
                    mapOf(
                        "eventId" to it.getLong(0).toString(),
                        "calendarId" to it.getLong(1).toString(),
                        "title" to (it.getString(2) ?: ""),
                        "beginMillis" to it.getLong(3),
                        "endMillis" to it.getLong(4),
                        "allDay" to (it.getInt(5) != 0),
                        "color" to if (it.isNull(6)) null else it.getInt(6),
                    ),
                )
            }
        }
        // Repeating events are marked, so that the app does not edit them.
        val repeating = repeatingEventIds(context, rows.map { it["eventId"] as String }.toSet())
        for (row in rows) {
            val copy = HashMap<String, Any?>(row)
            copy["recurring"] = repeating.contains(row["eventId"] as String)
            events.add(copy)
        }
        return events
    }

    private fun openEvent(
        activity: Activity,
        eventId: Long,
        begin: Long,
        end: Long,
        allDay: Boolean,
    ): Boolean {
        val intent = Intent(Intent.ACTION_VIEW)
            .setData(ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, eventId))
            .putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, begin)
            .putExtra(CalendarContract.EXTRA_EVENT_END_TIME, end)
            .putExtra(CalendarContract.EXTRA_EVENT_ALL_DAY, allDay)
        return try {
            activity.startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    /** Ids (as text) among [ids] whose event repeats. Asked in chunks: SQLite limits the number of arguments. */
    private fun repeatingEventIds(context: Context, ids: Set<String>): Set<String> {
        val found = HashSet<String>()
        for (chunk in ids.toList().chunked(400)) {
            val placeholders = chunk.joinToString(",") { "?" }
            val cursor = context.contentResolver.query(
                CalendarContract.Events.CONTENT_URI,
                arrayOf(
                    CalendarContract.Events._ID,
                    CalendarContract.Events.RRULE,
                    CalendarContract.Events.RDATE,
                ),
                CalendarContract.Events._ID + " IN (" + placeholders + ")",
                chunk.toTypedArray(),
                null,
            ) ?: continue
            cursor.use {
                while (it.moveToNext()) {
                    val rule = it.getString(1) ?: ""
                    val dates = it.getString(2) ?: ""
                    if (rule.isNotEmpty() || dates.isNotEmpty()) found.add(it.getLong(0).toString())
                }
            }
        }
        return found
    }

    /** Runs a write and turns the usual failures into error codes. */
    private fun writeCall(result: MethodChannel.Result, block: () -> Unit) {
        try {
            block()
        } catch (e: SecurityException) {
            result.error("permission_denied", "Calendar permission is not granted", null)
        } catch (e: Exception) {
            result.error("write_failed", "The change could not be saved", null)
        }
    }

    /**
     * The event columns for an insert or update. All-day events are stored the
     * way Android expects: UTC midnights and the UTC time zone. Nothing from
     * the content is logged.
     */
    private fun eventValues(call: MethodCall): ContentValues? {
        val title = call.argument<String>("title") ?: return null
        val begin = (call.argument<Number>("beginMillis"))?.toLong() ?: return null
        val end = (call.argument<Number>("endMillis"))?.toLong() ?: return null
        val allDay = call.argument<Boolean>("allDay") ?: false
        val values = ContentValues()
        values.put(CalendarContract.Events.TITLE, title)
        values.put(CalendarContract.Events.DTSTART, begin)
        values.put(CalendarContract.Events.DTEND, end)
        values.put(CalendarContract.Events.ALL_DAY, if (allDay) 1 else 0)
        values.put(
            CalendarContract.Events.EVENT_TIMEZONE,
            if (allDay) "UTC" else java.util.TimeZone.getDefault().id,
        )
        val notes = call.argument<String>("notes")
        if (notes != null) values.put(CalendarContract.Events.DESCRIPTION, notes)
        return values
    }

    /** True when the event is still in the calendar (not deleted). */
    private fun eventExists(context: Context, eventId: Long): Boolean {
        val uri = ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, eventId)
        val cursor = context.contentResolver.query(
            uri,
            arrayOf(CalendarContract.Events._ID, CalendarContract.Events.DELETED),
            null,
            null,
            null,
        ) ?: return false
        cursor.use {
            return it.moveToFirst() && it.getInt(1) == 0
        }
    }
}
