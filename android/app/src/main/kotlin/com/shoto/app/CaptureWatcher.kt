package com.shoto.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import java.util.concurrent.Executors

/**
 * Offers to keep a screenshot at the moment it is taken.
 *
 * **This is the app's whole funnel, arriving instead of being fetched.**
 * Everything Shoto does is downstream of being handed a picture, and both
 * existing routes — the share sheet and the Quick Settings tile — need the
 * user to remember Shoto exists while they still remember why they took the
 * shot. Those are two different acts of memory, and the second one expires in
 * about a minute.
 *
 * **Why a job and not a service.** The obvious build is a foreground service
 * watching a directory, and it costs a permanent notification in the shade
 * plus, on Android 14, a service type that has to be justified to Play.
 * [JobInfo.Builder.addTriggerContentUri] is the API Android provides for
 * exactly this question — *wake me when the gallery changes* — and it needs no
 * long-lived process, no extra permission and no standing notification.
 *
 * **What it deliberately cannot do.** The notification opens the save sheet;
 * it does not carry folder buttons that file the screenshot outright. Filing
 * in Shoto goes through a repository that scopes every row to the signed-in
 * account and records ownership in `library_assets` — a Kotlin shortcut
 * writing to the database from here would bypass all of it, which is precisely
 * the class of bug that once let a second account see the first one's library.
 * The offer comes from Android; the saving stays in Dart.
 *
 * **It can fail silently, and that is designed for rather than hidden.** A
 * content-trigger job does not survive a reboot (Android forbids combining
 * triggers with `setPersisted`), is cancelled outright by a force-stop, and is
 * throttled for apps the user rarely opens — which is a cruel irony, since
 * those are the users this exists for. So every run stamps [KEY_LAST_RUN], and
 * Settings shows it. A feature that stops working is survivable; one that
 * stops working while claiming to be on is not.
 */
class CaptureWatcher : JobService() {

    companion object {
        private const val JOB_ID = 4711
        private const val PREFS = "shoto_watcher"

        /** Newest screenshot already offered, as a MediaStore id. */
        private const val KEY_LAST_ID = "last_id"

        /** When the job last actually ran, for the status line in Settings. */
        private const val KEY_LAST_RUN = "last_run"

        /**
         * **The `_v2` is load-bearing, not tidiness.**
         *
         * A notification channel's importance can be *lowered* by the app but
         * never raised — once Android has created one, the level belongs to
         * the user, and `createNotificationChannel` on an existing id silently
         * ignores a higher importance. This channel shipped at `IMPORTANCE_LOW`
         * (shade only, no banner), so simply editing the constant would have
         * changed nothing on any phone that had already run the old build,
         * and the change would have looked like a bug in the code rather than
         * a rule in the platform.
         *
         * A new id is the only way to raise it. [ensureChannel] deletes the
         * old one so it does not sit in the user's notification settings as a
         * dead switch.
         */
        const val CHANNEL_ID = "captures_v2"

        /** The shade-only channel this replaced. Deleted on first run. */
        private const val LEGACY_CHANNEL_ID = "captures"
        private const val NOTIFICATION_ID = 4712

        /**
         * Arms the watcher, and marks everything already on the phone as seen.
         *
         * Without that watermark, switching this on would offer to file
         * whatever screenshot happened to be newest — a picture from last
         * March, arriving as if it had just been taken.
         */
        fun schedule(context: Context) {
            val scheduler = context.getSystemService(JobScheduler::class.java) ?: return

            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            if (!prefs.contains(KEY_LAST_ID)) {
                prefs.edit()
                    .putLong(KEY_LAST_ID, newestScreenshotId(context) ?: 0L)
                    .apply()
            }

            val job = JobInfo.Builder(
                JOB_ID,
                ComponentName(context, CaptureWatcher::class.java),
            )
                .addTriggerContentUri(
                    JobInfo.TriggerContentUri(
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                        JobInfo.TriggerContentUri.FLAG_NOTIFY_FOR_DESCENDANTS,
                    ),
                )
                // A short settling window rather than none. Saving one
                // screenshot writes several MediaStore rows as the file is
                // created and then indexed, and firing on the first would
                // read the row before it has a usable path. The max keeps the
                // offer inside the window where the user still remembers why
                // they pressed the buttons.
                .setTriggerContentUpdateDelay(1_000)
                .setTriggerContentMaxDelay(4_000)
                .build()

            scheduler.schedule(job)
        }

        fun cancel(context: Context) {
            context.getSystemService(JobScheduler::class.java)?.cancel(JOB_ID)
            NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
        }

        /**
         * What Settings needs to tell the truth: is it armed, when did it last
         * run, and is Android even allowed to show the result.
         */
        fun status(context: Context): Map<String, Any?> {
            val scheduler = context.getSystemService(JobScheduler::class.java)
            val armed = scheduler?.allPendingJobs?.any { it.id == JOB_ID } == true
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val lastRun = prefs.getLong(KEY_LAST_RUN, 0L)

            return mapOf(
                "armed" to armed,
                // Zero rather than null for "never", so Dart has one type to
                // read and no branch that exists only for a missing key.
                "lastRun" to lastRun,
                "notificationsAllowed" to
                    NotificationManagerCompat.from(context).areNotificationsEnabled(),
            )
        }

        /**
         * The newest screenshot's MediaStore id.
         *
         * Screenshots only, matched on the folder rather than the filename —
         * every skin names the file differently but they all write into a
         * directory called `Screenshots`. Shoto's own `Pictures/SHOTO` album
         * can never match, so filing a screenshot does not immediately offer
         * it back.
         */
        @Suppress("DEPRECATION")
        fun newestScreenshotId(context: Context): Long? {
            if (!canRead(context)) return null

            val folderColumn = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Images.Media.RELATIVE_PATH
            } else {
                MediaStore.Images.Media.DATA
            }

            return try {
                context.contentResolver.query(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                    arrayOf(MediaStore.Images.Media._ID),
                    "$folderColumn LIKE ?",
                    arrayOf("%Screenshots%"),
                    "${MediaStore.Images.Media._ID} DESC",
                )?.use { cursor ->
                    if (cursor.moveToFirst()) cursor.getLong(0) else null
                }
            } catch (error: Exception) {
                null
            }
        }

        fun canRead(context: Context): Boolean {
            val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                android.Manifest.permission.READ_MEDIA_IMAGES
            } else {
                android.Manifest.permission.READ_EXTERNAL_STORAGE
            }
            return ContextCompat.checkSelfPermission(context, permission) ==
                PackageManager.PERMISSION_GRANTED
        }
    }

    private val worker = Executors.newSingleThreadExecutor()

    override fun onStartJob(params: JobParameters?): Boolean {
        worker.execute {
            try {
                offerNewestCapture()
            } finally {
                // **Re-armed before finishing, always.** A content-trigger job
                // is one-shot: it fires once and is gone. Rescheduling inside
                // the `finally` means a failure to read the gallery costs one
                // missed offer rather than turning the feature off for good —
                // which, with no error anywhere on screen, would be
                // indistinguishable from Android having throttled it.
                schedule(applicationContext)
                jobFinished(params, false)
            }
        }
        // True: the work is still running on the executor above.
        return true
    }

    override fun onStopJob(params: JobParameters?): Boolean = false

    override fun onDestroy() {
        worker.shutdownNow()
        super.onDestroy()
    }

    private fun offerNewestCapture() {
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        prefs.edit().putLong(KEY_LAST_RUN, System.currentTimeMillis()).apply()

        val newest = newestScreenshotId(applicationContext) ?: return
        val lastSeen = prefs.getLong(KEY_LAST_ID, 0L)
        // Ids only ever climb, so this is both "is there a new one" and "is
        // this one we have already offered" in a single comparison — and it
        // survives a screenshot being deleted, which a count would not.
        if (newest <= lastSeen) return

        prefs.edit().putLong(KEY_LAST_ID, newest).apply()

        // Asking to keep a screenshot of Shoto itself is the app failing to
        // recognise its own reflection.
        if (isInForeground()) return

        notify(newest)
    }

    /**
     * Whether the user is looking at Shoto right now.
     *
     * Somebody taking a screenshot *of* Shoto is not asking to file it, and an
     * offer arriving over the app that produced the picture reads as the app
     * having lost track of itself.
     */
    private fun isInForeground(): Boolean {
        val manager = getSystemService(Context.ACTIVITY_SERVICE)
            as? android.app.ActivityManager ?: return false
        return manager.runningAppProcesses?.any {
            it.processName == packageName &&
                it.importance == android.app.ActivityManager
                    .RunningAppProcessInfo.IMPORTANCE_FOREGROUND
        } == true
    }

    private fun notify(mediaId: Long) {
        val manager = NotificationManagerCompat.from(this)
        if (!manager.areNotificationsEnabled()) return

        ensureChannel()

        val open = Intent(this, ShareActivity::class.java).apply {
            action = ShareActivity.ACTION_CAPTURE_LAST
            // The *specific* screenshot, not whatever is newest when the
            // notification is finally tapped. Somebody who takes three more
            // shots before coming back would otherwise file the wrong one,
            // and the sheet's preview is the only thing that would have told
            // them.
            putExtra(ShareActivity.EXTRA_MEDIA_ID, mediaId)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        val pending = PendingIntent.getActivity(
            this,
            mediaId.toInt(),
            open,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        // NotificationCompat rather than the platform builder: `minSdk` here
        // is 24 and notification channels only exist from 26, so the platform
        // `Builder(context, channelId)` does not exist on the two oldest
        // versions this app supports. The compat builder takes the channel id
        // on every version and ignores it where there are none — and
        // `setPriority` is what produces the same floating banner there that
        // `IMPORTANCE_HIGH` produces above.
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_qs_shoto)
            .setContentTitle(getString(R.string.capture_notice_title))
            .setContentText(getString(R.string.capture_notice_body))
            .setContentIntent(pending)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            // **No `setSilent(true)` here, and it was tried.** It reads like
            // the obvious way to get "visible but quiet", and it is the one
            // thing that prevents the banner: it puts the notification in
            // Android's *silent* group, and silent notifications are filed
            // straight into the shade's quiet section without ever floating.
            // Measured on the device — importance was 4 and no banner
            // appeared.
            //
            // The quiet half is done properly one level down instead, on the
            // channel, which has no sound and no vibration. Same result for
            // the user, without contradicting the level that makes it show.
            // Gone the moment it is acted on. An offer that outlives the
            // decision becomes a second copy of the same question.
            .setAutoCancel(true)
            .build()

        try {
            manager.notify(NOTIFICATION_ID, notification)
        } catch (error: SecurityException) {
            // POST_NOTIFICATIONS revoked between the check above and here.
            // Nothing to do and nothing worth crashing a background job over.
        }
    }

    /**
     * **Seen, but not heard.**
     *
     * `IMPORTANCE_HIGH` is what makes the offer float over whatever is on
     * screen instead of waiting in the shade — which is the point, since the
     * whole feature exists to reach somebody in the second after they pressed
     * the buttons, and a silent line in a shade they will not open for an hour
     * reaches nobody.
     *
     * Sound and vibration are then switched off deliberately. It is the level
     * *below* high that Android ties to noise; a high-importance channel with
     * `setSound(null, null)` gives the banner without the chime, which is the
     * only version of this that survives arriving after **every** screenshot.
     * An app that pings a hundred times a week gets muted, and a muted app is
     * a deleted one.
     *
     * And the level is the user's from here: Android's own notification
     * settings let anyone drop this channel back to silent-in-the-shade
     * without us shipping anything.
     */
    private fun ensureChannel() {
        // Channels arrived in 26; below that the priority on the notification
        // itself is what decides whether it floats.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return

        // Gone rather than left behind. A channel nobody posts to still shows
        // up in the app's notification settings as a switch that does nothing.
        manager.deleteNotificationChannel(LEGACY_CHANNEL_ID)

        if (manager.getNotificationChannel(CHANNEL_ID) != null) return

        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                getString(R.string.capture_channel_name),
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = getString(R.string.capture_channel_description)
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
                enableLights(false)
            },
        )
    }
}

/** Convenience for the id → content URI shape MediaStore uses. */
internal fun mediaImageUri(id: Long): Uri =
    Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id.toString())
