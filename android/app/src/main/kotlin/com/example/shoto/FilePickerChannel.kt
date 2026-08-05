package com.example.shoto

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Opens the system document picker and hands Dart back a readable file path.
 *
 * There is a package for this, and it cannot be used here: every `file_picker`
 * release new enough to work on current Android depends on `win32 ^5.9`, while
 * `share_plus 13.x` — which the whole sharing pipeline is built on — requires
 * `win32 ^6.0.1`. The only version that resolves alongside it is five years
 * old. Trading a working core feature for a file picker is a bad trade, and
 * the app already talks to Android directly for haptics and for the share
 * sheet, so this is one more small channel rather than a new pattern.
 *
 * The copy into cache is not optional. `ACTION_OPEN_DOCUMENT` returns a
 * `content://` URI whose permission belongs to this Activity instance; Dart's
 * `File` cannot open it, and the grant is gone by the time a later screen
 * tries. Copying while the grant is live is what makes the path usable at all.
 */
object FilePickerChannel {

    private const val CHANNEL = "shoto/files"
    const val REQUEST_PICK = 8021

    private var pending: MethodChannel.Result? = null

    fun register(activity: Activity, engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickBackup" -> startPicker(activity, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun startPicker(activity: Activity, result: MethodChannel.Result) {
        // A second request while one is open would strand the first callback,
        // and a MethodChannel result that is never completed hangs the Dart
        // side forever with no error to show.
        pending?.success(null)
        pending = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            // Backups are zips, but plenty of file providers label them
            // octet-stream or hand back a generic type, and a picker that
            // greys out the user's own backup is worse than one that lets
            // them choose the wrong file — Dart rejects anything that is not
            // a SHOTO archive with a clear message anyway.
            type = "*/*"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("application/zip", "application/octet-stream", "*/*")
            )
        }

        try {
            activity.startActivityForResult(intent, REQUEST_PICK)
        } catch (error: Exception) {
            pending = null
            result.error("no_picker", "No file picker on this device", null)
        }
    }

    /** Returns true when this was our request, handled or cancelled. */
    fun onActivityResult(
        activity: Activity,
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ): Boolean {
        if (requestCode != REQUEST_PICK) return false

        val result = pending ?: return true
        pending = null

        val uri: Uri? = if (resultCode == Activity.RESULT_OK) data?.data else null
        if (uri == null) {
            // Cancelling is an ordinary outcome, not an error. Reporting it as
            // one would put a red message on screen for somebody who simply
            // changed their mind.
            result.success(null)
            return true
        }

        try {
            val target = File(activity.cacheDir, "restore-${System.currentTimeMillis()}.zip")
            activity.contentResolver.openInputStream(uri)?.use { input ->
                target.outputStream().use { output -> input.copyTo(output) }
            } ?: run {
                result.error("unreadable", "Could not open that file", null)
                return true
            }
            result.success(target.absolutePath)
        } catch (error: Exception) {
            result.error("unreadable", error.message, null)
        }
        return true
    }
}
