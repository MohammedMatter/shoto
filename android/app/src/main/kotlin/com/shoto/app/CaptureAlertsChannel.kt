package com.shoto.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Turns the capture watcher on and off, and reports whether it is really
 * running.
 *
 * The **preference** lives in Dart (`AppPreferences.captureAlerts`) because
 * that is where every other setting lives and where the switch is drawn. What
 * lives here is everything Dart cannot see: whether Android still has the job
 * armed, when it last fired, and whether notifications are permitted at all.
 *
 * Keeping those apart matters. A switch reads back what the *user* asked for;
 * it must never be repurposed to mean "and it is working", because those two
 * facts come apart constantly on this feature — a force-stop, a battery
 * optimiser or a reboot each leave the preference on and the job gone. Settings
 * shows both, from the two places that know.
 */
object CaptureAlertsChannel {
    private const val CHANNEL = "shoto/captures"
    private const val NOTIFICATION_REQUEST = 4713

    fun register(activity: FlutterFragmentActivity, engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enable" -> {
                        requestNotificationsIfNeeded(activity)
                        CaptureWatcher.schedule(activity)
                        result.success(CaptureWatcher.status(activity))
                    }

                    "disable" -> {
                        CaptureWatcher.cancel(activity)
                        result.success(CaptureWatcher.status(activity))
                    }

                    // Called every time the settings screen is looked at, so
                    // a job Android has quietly dropped is visible the next
                    // time somebody wonders why nothing is appearing.
                    "status" -> result.success(CaptureWatcher.status(activity))

                    // **The one thing the warning line could not do.**
                    //
                    // "Notifications are off for Shoto — turn them on in your
                    // phone's settings" is a correct sentence and a dead end:
                    // it names a screen the app cannot open and the user has
                    // to go and find. Android provides the exact destination,
                    // so the warning becomes a button instead of an
                    // instruction.
                    "openNotificationSettings" -> {
                        openNotificationSettings(activity)
                        result.success(null)
                    }

                    // Re-arms after a reboot or a force-stop, which are the
                    // two things that cancel a content-trigger job outright.
                    // Called on launch, and only does anything when the user
                    // has this switched on.
                    "rearm" -> {
                        if (call.arguments == true) CaptureWatcher.schedule(activity)
                        result.success(CaptureWatcher.status(activity))
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Opens Shoto's own page in the system notification settings.
     *
     * Falls back to the app's general details page on anything that does not
     * carry the per-app notification screen — landing one level up is a great
     * deal better than a button that does nothing.
     */
    private fun openNotificationSettings(activity: FlutterFragmentActivity) {
        val direct = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)
        val fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.fromParts("package", activity.packageName, null))

        try {
            activity.startActivity(direct)
        } catch (error: Exception) {
            try {
                activity.startActivity(fallback)
            } catch (ignored: Exception) {
                // Both refused. Nothing useful is left to try, and a crash
                // here would be a settings screen taking the app down.
            }
        }
    }

    /**
     * Asks for POST_NOTIFICATIONS, and does not wait for the answer.
     *
     * Deliberately fire-and-forget. Threading the permission callback back
     * through the channel would buy a slightly faster switch and cost a
     * result that must be fulfilled exactly once across an activity that can
     * be recreated mid-dialog — and it is not needed, because `status`
     * reports `notificationsAllowed` and the settings row reads it. Whatever
     * the user answers, the truth is on screen the next time they look.
     */
    private fun requestNotificationsIfNeeded(activity: FlutterFragmentActivity) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        val granted = ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED
        if (granted) return

        ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            NOTIFICATION_REQUEST,
        )
    }
}
