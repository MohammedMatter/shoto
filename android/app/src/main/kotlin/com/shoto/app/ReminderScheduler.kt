package com.shoto.app

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Reminders about a screenshot, armed with [AlarmManager].
 *
 * The app already knows what somebody meant to *do* with a picture — the
 * intent they chose when they saved it — and until now it could only show
 * that back to them when they opened the app and looked. That makes a to-do
 * list with no alarm clock: the screenshots that most need one are exactly the
 * ones nobody reopens the app to find.
 *
 * ## Inexact on purpose
 *
 * [AlarmManager.setExactAndAllowWhileIdle] would need `SCHEDULE_EXACT_ALARM`,
 * which Android 12 made a special-access permission and which Play reviews
 * against a short list of genuine uses — alarm clocks and calendars. "Remind
 * me about this screenshot this evening" is not on it, and asking would be
 * asking for a permission this feature does not need: nobody is timing an
 * egg. [AlarmManager.setAndAllowWhileIdle] needs no permission at all and
 * still fires through Doze.
 *
 * **What it costs, measured rather than assumed.** Read back from
 * `dumpsys alarm` on a real phone, the slack Android grants is proportional to
 * how far out the alarm is, not a flat amount:
 *
 * ```
 * origWhen=2026-08-18 11:36  window=+3m10s   (set five minutes ahead)
 * origWhen=2026-08-18 14:07  window=+1h0m0s  (set three hours ahead)
 * ```
 *
 * So "a few minutes" is right for the near ones and badly wrong for the far
 * ones — an evening reminder can land an hour late. That is the honest shape of
 * the trade, and it is the acceptable half: nobody sets "this evening" to the
 * minute, and the near ones, which somebody *did* name a minute for, are the
 * ones Android keeps tightest.
 *
 * **And there is no permission-free way out**, which is worth writing down
 * because the obvious escape looks like one. [AlarmManager.setAlarmClock] is
 * exact and immune to Doze, and it is widely described as needing no
 * permission — that was true before Android 12 and is not true now. Tried on
 * an Android 13 device, it throws:
 *
 * ```
 * java.lang.SecurityException: Caller com.shoto.app needs to hold
 * android.permission.SCHEDULE_EXACT_ALARM or android.permission.USE_EXACT_ALARM
 * to set exact alarms.
 * ```
 *
 * The failure is worse than the inaccuracy it was meant to fix: the exception
 * leaves *no* alarm armed, and because the replacement never happened, whatever
 * was armed before is still there pointing at the old time. A reminder that is
 * merely late beats one that is silently gone.
 *
 * So exactness here is not an implementation choice, it is a permission
 * decision — `USE_EXACT_ALARM` or `SCHEDULE_EXACT_ALARM`, both of which Play
 * reviews — and it belongs to whoever owns that call, not to this file.
 *
 * ## Why Kotlin keeps its own copy of the list
 *
 * The reminder itself lives in `screenshot_meta.remind_at`, which is the
 * source of truth and the only thing the interface reads. But **alarms do not
 * survive a reboot**, and re-arming them means knowing what was pending
 * before the phone restarted — which happens long before Flutter has started
 * and cannot reach a sqflite file in Dart's world.
 *
 * So scheduling also writes a small mirror into this object's own
 * preferences, and [BootReceiver] re-arms from it. The split is the same one
 * `CaptureAlertsChannel` documents: Dart owns what the user asked for, the
 * platform owns what is actually armed, and neither is asked to answer the
 * other's question.
 */
object ReminderScheduler {
    const val CHANNEL_ID = "reminders"

    /** The screenshot this reminder is about, so tapping opens that one. */
    const val EXTRA_ASSET_ID = "com.shoto.app.REMINDER_ASSET_ID"
    const val EXTRA_TITLE = "com.shoto.app.REMINDER_TITLE"
    const val EXTRA_BODY = "com.shoto.app.REMINDER_BODY"
    const val EXTRA_AT = "com.shoto.app.REMINDER_AT"

    private const val PREFS = "shoto_reminders"

    /**
     * Arms one reminder, replacing any earlier one for the same screenshot.
     *
     * The request code is derived from the asset id rather than counted up,
     * which is what makes replacing and cancelling work at all: a
     * [PendingIntent] is identified by request code and intent, so the same
     * screenshot always produces the same handle and `FLAG_UPDATE_CURRENT`
     * overwrites rather than stacking a second alarm on top.
     */
    fun schedule(
        context: Context,
        assetId: String,
        atMillis: Long,
        title: String,
        body: String,
    ) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        alarms.setAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            atMillis,
            pendingIntent(context, assetId, atMillis, title, body),
        )

        remember(context, assetId, atMillis, title, body)
    }

    fun cancel(context: Context, assetId: String) {
        val remembered = read(context)[assetId] ?: return
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        alarms.cancel(
            pendingIntent(
                context,
                assetId,
                remembered.at,
                remembered.title,
                remembered.body,
            ),
        )
        forget(context, assetId)
    }

    /**
     * Re-arms everything still in the future, and drops what is not.
     *
     * Called after a reboot. A reminder whose moment passed while the phone
     * was off is **dropped rather than fired late**: the whole value of "this
     * evening" is that it arrives this evening, and a notification that
     * arrives whenever the phone happened to come back on is noise the user
     * cannot place. The row in the database keeps it visible in the app,
     * which is where a missed reminder belongs.
     */
    fun rearmAll(context: Context) {
        val now = System.currentTimeMillis()
        for ((assetId, pending) in read(context)) {
            if (pending.at <= now) {
                forget(context, assetId)
                continue
            }
            schedule(context, assetId, pending.at, pending.title, pending.body)
        }
    }

    fun notify(context: Context, assetId: String, title: String, body: String) {
        val manager = NotificationManagerCompat.from(context)
        if (!manager.areNotificationsEnabled()) return

        ensureChannel(context)

        val open = Intent(context, MainActivity::class.java).apply {
            putExtra(EXTRA_ASSET_ID, assetId)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        val pending = PendingIntent.getActivity(
            context,
            requestCode(assetId),
            open,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_qs_shoto)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(pending)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()

        try {
            // Keyed by screenshot, so two reminders are two notifications
            // rather than one replacing the other.
            manager.notify(requestCode(assetId), notification)
        } catch (error: SecurityException) {
            // POST_NOTIFICATIONS revoked between the check and here.
        }
        forget(context, assetId)
    }

    private fun pendingIntent(
        context: Context,
        assetId: String,
        atMillis: Long,
        title: String,
        body: String,
    ): PendingIntent {
        val intent = Intent(context, ReminderReceiver::class.java).apply {
            putExtra(EXTRA_ASSET_ID, assetId)
            putExtra(EXTRA_TITLE, title)
            putExtra(EXTRA_BODY, body)
            putExtra(EXTRA_AT, atMillis)
        }

        return PendingIntent.getBroadcast(
            context,
            requestCode(assetId),
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    /**
     * A stable non-negative int per asset id.
     *
     * `hashCode` alone can be negative and `Math.abs(Int.MIN_VALUE)` is still
     * negative, which is the classic way this shape of code produces one
     * unusable request code in every four billion.
     */
    private fun requestCode(assetId: String): Int = assetId.hashCode() and 0x7FFFFFFF

    private data class Pending(val at: Long, val title: String, val body: String)

    private fun read(context: Context): Map<String, Pending> {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return prefs.all.mapNotNull { (key, value) ->
            val encoded = value as? String ?: return@mapNotNull null
            // at|title|body — the body may itself contain the separator, so
            // the split is limited to three and the remainder stays whole.
            val parts = encoded.split('|', limit = 3)
            if (parts.size < 3) return@mapNotNull null
            val at = parts[0].toLongOrNull() ?: return@mapNotNull null
            key to Pending(at, parts[1], parts[2])
        }.toMap()
    }

    private fun remember(
        context: Context,
        assetId: String,
        atMillis: Long,
        title: String,
        body: String,
    ) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(assetId, "$atMillis|${title.replace('|', ' ')}|$body")
            .apply()
    }

    private fun forget(context: Context, assetId: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .remove(assetId)
            .apply()
    }

    /**
     * Quieter than the capture channel, and separately controllable.
     *
     * A reminder is something the user asked for at a moment they chose, so it
     * does not need to interrupt the way an offer about the screenshot just
     * taken does — `IMPORTANCE_DEFAULT` puts it in the shade with a sound
     * rather than floating it over whatever is on screen. Its own channel also
     * means somebody can silence reminders without silencing capture offers,
     * which are the same app saying two unrelated things.
     */
    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return

        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                context.getString(R.string.reminder_channel_name),
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = context.getString(R.string.reminder_channel_description)
            },
        )
    }
}

/** Fires one reminder. */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val assetId = intent.getStringExtra(ReminderScheduler.EXTRA_ASSET_ID) ?: return
        val title = intent.getStringExtra(ReminderScheduler.EXTRA_TITLE).orEmpty()
        val body = intent.getStringExtra(ReminderScheduler.EXTRA_BODY).orEmpty()
        ReminderScheduler.notify(context, assetId, title, body)
    }
}

/** Puts the alarms back after a restart, since Android drops them all. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        ReminderScheduler.rearmAll(context)
    }
}
