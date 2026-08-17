package com.shoto.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Dart's side of [ReminderScheduler], plus the one thing only the activity can
 * answer: which screenshot the user arrived here by tapping.
 *
 * `schedule` and `cancel` are deliberately thin. Everything that decides
 * *when* — the presets, what "this evening" means, refusing a time that has
 * already passed — is in Dart, where it can be tested without a device and
 * where it is written once for both platforms if there is ever a second one.
 * What lives here is only what needs [android.app.AlarmManager].
 */
object RemindersChannel {
    private const val CHANNEL = "shoto/reminders"
    private const val NOTIFICATION_REQUEST = 4714

    /**
     * The asset id carried by the intent that started or resumed the activity,
     * handed to Dart once and then cleared.
     *
     * Cleared because an activity intent outlives the launch that carried it:
     * without this, backgrounding the app and returning to it would open the
     * same screenshot again, long after the reminder was dealt with.
     */
    private var pendingAssetId: String? = null

    fun register(activity: FlutterFragmentActivity, engine: FlutterEngine) {
        captureLaunchIntent(activity.intent)

        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        val assetId = call.argument<String>("assetId")
                        val at = call.argument<Number>("at")?.toLong()
                        if (assetId == null || at == null) {
                            result.error("bad_args", "assetId and at are required", null)
                            return@setMethodCallHandler
                        }
                        requestNotificationsIfNeeded(activity)
                        ReminderScheduler.schedule(
                            activity,
                            assetId,
                            at,
                            call.argument<String>("title").orEmpty(),
                            call.argument<String>("body").orEmpty(),
                        )
                        result.success(
                            NotificationManagerCompat.from(activity)
                                .areNotificationsEnabled(),
                        )
                    }

                    "cancel" -> {
                        val assetId = call.argument<String>("assetId")
                        if (assetId == null) {
                            result.error("bad_args", "assetId is required", null)
                            return@setMethodCallHandler
                        }
                        ReminderScheduler.cancel(activity, assetId)
                        result.success(null)
                    }

                    // Whether a reminder would actually be seen. Asked by the
                    // sheet before it offers times, because a reminder that
                    // cannot be delivered is worth saying so about rather than
                    // scheduling in silence.
                    "notificationsEnabled" ->
                        result.success(
                            NotificationManagerCompat.from(activity)
                                .areNotificationsEnabled(),
                        )

                    // Consumed exactly once — see [pendingAssetId].
                    "consumeLaunchAssetId" -> {
                        result.success(pendingAssetId)
                        pendingAssetId = null
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /** Called from `onNewIntent` too, since the activity is `singleTop`. */
    fun captureLaunchIntent(intent: Intent?) {
        val assetId = intent?.getStringExtra(ReminderScheduler.EXTRA_ASSET_ID) ?: return
        pendingAssetId = assetId
        // Or the same extra is read again on the next resume.
        intent.removeExtra(ReminderScheduler.EXTRA_ASSET_ID)
    }

    /**
     * Asks for `POST_NOTIFICATIONS` at the moment somebody sets their first
     * reminder, which is the only moment the request explains itself.
     *
     * Below Android 13 the permission does not exist and notifications are on
     * unless the user turned them off, so there is nothing to ask.
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
