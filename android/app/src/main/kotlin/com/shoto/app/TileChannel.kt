package com.shoto.app

import android.app.StatusBarManager
import android.content.ComponentName
import android.graphics.drawable.Icon
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Asks Android to put Shoto's Quick Settings tile in the user's panel.
 *
 * **Without this the feature does not exist for anybody.** Adding a tile by
 * hand means pulling the panel down, finding the pencil, scrolling a drawer of
 * greyed-out tiles and dragging one up into the grid — four steps that have to
 * be *described* before they can be followed, on a screen the app cannot show
 * you. A feature whose install instructions are longer than the feature is a
 * feature nobody has.
 *
 * Android 13 added [StatusBarManager.requestAddTileService], which puts a
 * single system dialog in front of the user — the panel's own voice, asking
 * once — and drops the tile in if they accept. That is the whole difference
 * between shipping this and merely writing it.
 *
 * Below 13 there is no such API, so Dart is told plainly ([RESULT_UNSUPPORTED])
 * and shows the manual steps instead of a button that would do nothing.
 */
object TileChannel {
    private const val CHANNEL = "shoto/tile"

    /** The system placed it, or it was already there. */
    private const val RESULT_ADDED = "added"

    /** The dialog was shown and the user said no. */
    private const val RESULT_DECLINED = "declined"

    /** This Android is too old to ask. Dart explains the manual route. */
    private const val RESULT_UNSUPPORTED = "unsupported"

    fun register(activity: FlutterFragmentActivity, engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestAdd" -> requestAdd(activity, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestAdd(
        activity: FlutterFragmentActivity,
        result: MethodChannel.Result,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(RESULT_UNSUPPORTED)
            return
        }

        val manager = activity.getSystemService(StatusBarManager::class.java)
        if (manager == null) {
            result.success(RESULT_UNSUPPORTED)
            return
        }

        // Answered exactly once. The system invokes this callback on its own
        // thread and, on some builds, more than once for a single dialog —
        // and a MethodChannel result that is fulfilled twice throws rather
        // than being ignored, which would crash the app on a *successful*
        // add. Guarding here is cheaper than trusting the platform.
        var answered = false

        try {
            manager.requestAddTileService(
                ComponentName(activity, ShotoTileService::class.java),
                activity.getString(R.string.qs_tile_label),
                Icon.createWithResource(activity, R.drawable.ic_qs_shoto),
                ContextCompat.getMainExecutor(activity),
            ) { code ->
                if (answered) return@requestAddTileService
                answered = true

                // "Already added" is reported as its own code and is a
                // success from the user's side — the tile is in their panel,
                // which is the only thing the button promised.
                val added = code == StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ADDED ||
                    code == StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ALREADY_ADDED
                result.success(if (added) RESULT_ADDED else RESULT_DECLINED)
            }
        } catch (error: Exception) {
            // Skins do modify System UI, and a panel that refuses the request
            // must not take the settings screen with it. The manual steps are
            // still correct, so this lands on the same answer as an old
            // Android rather than on an error.
            if (!answered) {
                answered = true
                result.success(RESULT_UNSUPPORTED)
            }
        }
    }
}
