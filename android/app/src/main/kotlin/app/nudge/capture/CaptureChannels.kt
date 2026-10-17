package app.nudge.capture

import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.service.notification.NotificationListenerService
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Registers the method and event channels used by the Dart code in lib/platform. */
object CaptureChannels {
    private const val METHODS = "app.nudge/capture"
    private const val EVENTS = "app.nudge/capture/events"

    fun register(messenger: BinaryMessenger, context: Context) {
        val appContext = context.applicationContext
        MethodChannel(messenger, METHODS).setMethodCallHandler { call, result ->
            handle(appContext, call, result)
        }
        EventChannel(messenger, EVENTS).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    CaptureState.attachSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    CaptureState.attachSink(null)
                }
            },
        )
    }

    private fun handle(context: Context, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "packageName" -> result.success(context.packageName)
            "isAccessGranted" -> result.success(isAccessGranted(context))
            "isServiceConnected" -> result.success(CaptureState.serviceConnected)
            "openAccessSettings" -> result.success(openAccessSettings(context))
            "requestRebind" -> {
                requestRebind(context)
                result.success(null)
            }
            "hasLiveContentIntent" ->
                result.success(ContentIntentRegistry.has(call.argument<String>("key") ?: ""))
            "openLiveContent" ->
                result.success(ContentIntentRegistry.send(call.argument<String>("key") ?: ""))
            "openSourceApp" ->
                result.success(
                    ContentIntentRegistry.openLauncher(
                        context,
                        call.argument<String>("package") ?: "",
                    ),
                )
            "peekQueue" -> {
                val max = call.argument<Int>("max") ?: 100
                result.success(CaptureQueues.get(context).peek(max))
            }
            "clearQueue" -> {
                CaptureQueues.get(context).clear()
                result.success(null)
            }
            "ackQueue" -> {
                val upToSeq = call.argument<Number>("upToSeq")?.toLong()
                if (upToSeq == null) {
                    result.error("bad_args", "upToSeq is required", null)
                } else {
                    CaptureQueues.get(context).ack(upToSeq)
                    result.success(null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun isAccessGranted(context: Context): Boolean {
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        return enabled.split(":")
            .mapNotNull { ComponentName.unflattenFromString(it) }
            .any { it.packageName == context.packageName }
    }

    private fun openAccessSettings(context: Context): Boolean {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    private fun requestRebind(context: Context) {
        try {
            NotificationListenerService.requestRebind(
                ComponentName(context, NotificationCaptureService::class.java),
            )
        } catch (e: Exception) {
            // Not granted or not supported on this device.
        }
    }
}
