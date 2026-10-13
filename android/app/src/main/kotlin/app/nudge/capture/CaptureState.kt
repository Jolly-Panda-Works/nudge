package app.nudge.capture

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Process-wide state shared by the listener service and the Flutter channels.
 * The event sink is only a "wake-up" line: all data travels through [CaptureQueue].
 */
internal object CaptureState {
    @Volatile
    var serviceConnected: Boolean = false

    @Volatile
    private var sink: EventChannel.EventSink? = null

    private val mainHandler = Handler(Looper.getMainLooper())

    fun attachSink(newSink: EventChannel.EventSink?) {
        sink = newSink
    }

    fun emit(event: Map<String, Any?>) {
        mainHandler.post { sink?.success(event) }
    }
}
