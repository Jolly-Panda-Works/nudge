package app.nudge.capture

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Saves an export through the system file picker (Storage Access Framework),
 * so the app needs no storage permission. The content is written only to the
 * location the user chooses and is never logged.
 */
object DocumentExporter {
    private const val CHANNEL = "app.nudge/export"
    private const val REQUEST_CODE = 0x4E44

    private var pendingResult: MethodChannel.Result? = null
    private var pendingContent: String? = null

    fun register(messenger: BinaryMessenger, activity: Activity) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "saveDocument") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val fileName = call.argument<String>("fileName")
            val content = call.argument<String>("content")
            if (fileName == null || content == null) {
                result.error("bad_args", "fileName and content are required", null)
            } else {
                start(activity, fileName, content, result)
            }
        }
    }

    private fun start(
        activity: Activity,
        fileName: String,
        content: String,
        result: MethodChannel.Result,
    ) {
        if (pendingResult != null) {
            result.error("busy", "An export is already in progress", null)
            return
        }
        pendingResult = result
        pendingContent = content
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/json"
            putExtra(Intent.EXTRA_TITLE, fileName)
        }
        try {
            activity.startActivityForResult(intent, REQUEST_CODE)
        } catch (e: ActivityNotFoundException) {
            pendingResult = null
            pendingContent = null
            result.error("no_picker", "No file picker is available", null)
        }
    }

    /** Returns true if the result belonged to an export. */
    fun onActivityResult(
        activity: Activity,
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val result = pendingResult
        val content = pendingContent
        pendingResult = null
        pendingContent = null
        if (result == null || content == null) return true

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(false)
            return true
        }
        try {
            val stream = activity.contentResolver.openOutputStream(uri)
            if (stream == null) {
                result.error("write_failed", "Could not open the file", null)
                return true
            }
            stream.use { it.write(content.toByteArray(Charsets.UTF_8)) }
            result.success(true)
        } catch (e: Exception) {
            result.error("write_failed", e.javaClass.simpleName, null)
        }
        return true
    }
}
