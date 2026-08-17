package com.shoto.app

import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import androidx.core.content.ContextCompat
import java.util.concurrent.Executors
import java.util.concurrent.Future
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Receives images shared into Shoto from other apps.
 *
 * This is a *separate* activity from [MainActivity] on purpose. Handling the
 * share intent in the main activity meant every "share to Shoto" tore the
 * user out of whatever app they were in and dropped them into the full app,
 * which they then had to back out of. Its own activity — with its own task,
 * excluded from recents — can show a small save sheet, do the work, and
 * disappear, leaving the user exactly where they were.
 *
 * Flutter is told to start on the `/share` route so the Dart side knows to
 * render the sheet instead of the whole app.
 */
class ShareActivity : FlutterFragmentActivity() {

    companion object {
        private const val CHANNEL = "shoto/share"

        /**
         * The Quick Settings tile asking for the newest screenshot.
         *
         * A private action rather than a reuse of `ACTION_SEND` with no
         * payload: the two arrive with different obligations. A share carries
         * a URI the sender has granted us and we merely copy; this carries
         * nothing, and Shoto goes looking in the user's gallery on its own
         * initiative. Naming that difference is what keeps [readImageUris]
         * honest about which of the two it is serving — and what stops a
         * future edit to the SEND branch quietly changing where the tile gets
         * its picture from.
         *
         * Deliberately **not** in an intent-filter. The tile launches this
         * activity by class, and an explicit intent needs no filter; adding
         * one would publish "give Shoto your newest screenshot" as something
         * any app on the phone could invoke.
         */
        const val ACTION_CAPTURE_LAST = "com.shoto.app.action.CAPTURE_LAST"

        /**
         * A specific MediaStore id to offer, rather than whatever is newest.
         *
         * Set by the capture notification, which names the screenshot it was
         * posted about. Between posting and tapping, the user may well have
         * taken three more — resolving "newest" at tap time would file one
         * they never chose, and the sheet's preview would be the only thing
         * that ever mentioned it.
         *
         * The tile sends no id, because there the tap *is* the moment: newest
         * is exactly what was meant.
         */
        const val EXTRA_MEDIA_ID = "media_id"

        /**
         * Most a single share may carry.
         *
         * Every incoming image is copied into this app's cache before the
         * sheet can show anything, so an unbounded selection would leave the
         * user staring at a blank screen while hundreds of files are written.
         * Anything past this is reported to Dart, which says so rather than
         * dropping them silently.
         */
        private const val MAX_IMAGES = 30
    }

    /**
     * The copy work, started the instant the activity is created.
     *
     * Materialising the shared image into our cache used to begin only when
     * Dart asked for it — which is after the Flutter engine has booted, the
     * service locator is built and Firebase is up. On a cold share that is
     * well over a second of the phone doing nothing with the one piece of
     * data it already had in hand.
     *
     * Running it here overlaps the copy with the engine start instead. By the
     * time `getSharedImages` arrives the answer is usually already sitting
     * there, and when it isn't, [Future.get] simply waits out whatever is
     * left rather than starting from scratch.
     */
    private var incoming: Future<Map<String, Any?>>? = null

    /**
     * Kept for the lifetime of the activity rather than made per-share.
     *
     * It used to be created inline and abandoned, on the reasoning that this
     * activity handles one share and then finishes. [onNewIntent] is the case
     * that reasoning missed — a living instance can be handed a second share
     * — and one executor reused is also what serialises the two copies, so a
     * replacement can never be overtaken by the copy it replaced.
     */
    private val worker = Executors.newSingleThreadExecutor()

    private var channel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        lockToPortrait()
        incoming = worker.submit<Map<String, Any?>> { describeIncomingImages() }
    }

    /**
     * Portrait, applied here rather than in the manifest.
     *
     * Every other activity in this app declares `android:screenOrientation`
     * and is done with it. This one cannot: it is translucent, and Android 8.0
     * refuses a fixed orientation on a translucent activity by throwing out of
     * `Activity.onCreate` — a manifest attribute there would make every share
     * on that version a crash rather than a sheet. 8.1 lifted the restriction;
     * minSdk is 24, so 8.0 is still in range.
     *
     * Doing it in code moves the same request somewhere it can be guarded, and
     * moves it early: the alternative is Dart's
     * `SystemChrome.setPreferredOrientations`, which cannot run until the
     * engine has booted — the better part of a second into a cold share, and
     * every frame of that is a frame the sheet could arrive sideways in.
     *
     * The catch is deliberately narrow and deliberately silent. On 8.0 there
     * is nothing to do about it: the OS has decided a translucent window
     * follows whatever is behind it, and a sheet drawn at the host app's
     * angle is a far smaller problem than a share that does not open.
     */
    private fun lockToPortrait() {
        try {
            requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        } catch (error: IllegalStateException) {
            // Android 8.0 only — see above.
        }
    }

    /**
     * The same guard, for the request that comes from Dart.
     *
     * `main()` locks the orientation for both entry points, and Flutter
     * implements that by calling straight into this method. Without the
     * override the 8.0 throw would come back across the platform channel as a
     * `PlatformException` — which `main` awaits, before `runApp`, where an
     * error is a black screen rather than a rotated one.
     */
    override fun setRequestedOrientation(requestedOrientation: Int) {
        try {
            super.setRequestedOrientation(requestedOrientation)
        } catch (error: IllegalStateException) {
            // Android 8.0 only — see [lockToPortrait].
        }
    }

    /**
     * A second share, handed to the instance already on screen.
     *
     * **This activity is `singleTop`, so Android delivers here rather than
     * building a new one** — and for as long as nothing overrode this, that
     * delivery went nowhere. The sheet kept showing the previous picture and
     * the share the user had just performed did nothing at all, which reads as
     * the app ignoring them.
     *
     * It was survivable while the sheet always finished itself: save or
     * dismiss both call `finishAndRemoveTask`, so an instance was rarely alive
     * to deliver to. Covering changed that. Backing out of Safe Share returns
     * to the offer on purpose — a mis-tap should not cost the whole share —
     * which means an instance is now routinely sitting there, and the second
     * share is the *normal* case rather than the rare one.
     *
     * `setIntent` before re-reading, because [readImageUris] reads `intent`
     * and the base class does not swap it for us.
     */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        incoming = worker.submit<Map<String, Any?>> { describeIncomingImages() }
        // Dart owns what is on screen, so it is told rather than reset from
        // here. It has a page stack to unwind and a stage to return to, and
        // neither is anything this side can see.
        channel?.invokeMethod("reshare", null)
    }

    override fun onDestroy() {
        worker.shutdownNow()
        channel?.setMethodCallHandler(null)
        channel = null
        super.onDestroy()
    }

    override fun getInitialRoute(): String = "/share"

    /**
     * Renders over whatever app the user was in, rather than covering it.
     *
     * Flutter paints an opaque surface by default, so without this the sheet
     * would sit on a black rectangle and read as "Shoto opened" — exactly the
     * interruption this whole activity exists to avoid. The theme must also
     * set android:windowIsTranslucent, or this has no effect.
     */
    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        HapticsChannel.register(this, flutterEngine)

        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        )

        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                // Every incoming image, each with its MediaStore id when it
                // has one. The id is what lets Dart tell "a screenshot Shoto
                // already shows" from "an image from another app" — without
                // it, sharing your own screenshot back into Shoto silently
                // wrote a second copy of it.
                // Already running since onCreate — this usually returns
                // immediately.
                "getSharedImages" -> result.success(
                    incoming?.get() ?: describeIncomingImages(),
                )

                // Called once the sheet is done. finishAndRemoveTask (rather
                // than finish) is what stops an empty Shoto card being left
                // behind in the recents switcher.
                "close" -> {
                    result.success(null)
                    finishAndRemoveTask()
                }

                else -> result.notImplemented()
            }
        }
    }

    /**
     * Describes every shared image for Dart, plus how many were left out.
     *
     * One image that fails to copy is skipped rather than failing the whole
     * share — picking ten screenshots and getting nothing because one of them
     * was unreadable would be a poor trade.
     */
    private fun describeIncomingImages(): Map<String, Any?> {
        val uris: List<Uri> = readImageUris()
        val accepted: List<Uri> = uris.take(MAX_IMAGES)

        val images: List<Map<String, Any?>> = accepted.mapIndexedNotNull { index, uri ->
            copyIntoCache(uri, index)
        }

        return mapOf(
            "images" to images,
            "skipped" to (uris.size - accepted.size),
            // Which door this came through. Dart needs it for exactly one
            // thing, and it is a wording question rather than a behavioural
            // one: an empty result from a share means "that image could not
            // be read, try sharing it again", while an empty result from the
            // tile means the phone holds no screenshot at all — and telling
            // somebody to re-share a picture they never took is the app
            // blaming them for its own empty hands.
            "source" to when {
                intent?.action != ACTION_CAPTURE_LAST -> "share"
                canReadGallery() -> "tile"
                // **A third answer, and it exists because of a real dead
                // end.** Android auto-revokes permissions for apps that go
                // unused for a few months. Once READ_MEDIA_IMAGES is gone the
                // query below returns nothing, and "no screenshot yet — take
                // one and tap again" would be a loop: they take one, tap
                // again, and read the same sentence forever, because the
                // thing that is missing is not a screenshot.
                else -> "tile-no-access"
            },
        )
    }

    /**
     * Whether Shoto may still read the gallery.
     *
     * Checked rather than assumed. Every other path into this app runs inside
     * the full app, which has a screen for refused access and a button to ask
     * again; the tile is the one entry point that reaches the user with no
     * such screen behind it.
     */
    private fun canReadGallery(): Boolean {
        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            android.Manifest.permission.READ_MEDIA_IMAGES
        } else {
            android.Manifest.permission.READ_EXTERNAL_STORAGE
        }
        return ContextCompat.checkSelfPermission(this, permission) ==
            PackageManager.PERMISSION_GRANTED
    }

    /**
     * The most recently captured screenshot on the device, if there is one.
     *
     * **Screenshots only — never "the newest image".** Falling back to the
     * latest picture would make a tile press after a week of holidays offer
     * to file a photograph of somebody's dinner, and the sheet's preview
     * would be the first the user heard of it. An empty answer is a true
     * answer; a plausible wrong one is the kind of mistake that costs trust in
     * every later suggestion.
     *
     * Matched on the folder rather than on a filename pattern: every skin
     * names the file differently (and MIUI has changed its own scheme twice),
     * but they all write into a directory called `Screenshots` — under
     * `Pictures` on stock Android, under `DCIM` on some others, which is why
     * this is a contains-match rather than an equality one.
     *
     * Shoto's own `Pictures/SHOTO` album can never match, so a screenshot
     * that has already been filed is not offered back as a fresh capture.
     */
    @Suppress("DEPRECATION")
    private fun latestScreenshotUri(): Uri? {
        val collection: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        } else {
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        }

        // RELATIVE_PATH does not exist before Q; DATA (the absolute path) is
        // deprecated after it but is the only column old versions have.
        val folderColumn: String = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Images.Media.RELATIVE_PATH
        } else {
            MediaStore.Images.Media.DATA
        }

        return try {
            contentResolver.query(
                collection,
                arrayOf(MediaStore.Images.Media._ID),
                "$folderColumn LIKE ?",
                arrayOf("%Screenshots%"),
                // No LIMIT clause: it is not portable across every provider,
                // and reading the first row of a descending sort costs the
                // same — a cursor is lazy, so the rest is never materialised.
                "${MediaStore.Images.Media.DATE_ADDED} DESC",
            )?.use { cursor ->
                if (!cursor.moveToFirst()) return@use null
                val id = cursor.getLong(0)
                Uri.withAppendedPath(collection, id.toString())
            }
        } catch (error: Exception) {
            // A provider that refuses the query must not take the sheet down
            // with it — an empty hand is already a state this flow renders.
            null
        }
    }

    private fun copyIntoCache(uri: Uri, index: Int): Map<String, Any?>? {
        return try {
            // A content:// URI is only readable while this activity holds the
            // grant, so it is materialised into our own cache regardless —
            // Dart needs a real file to show a preview either way. The index
            // keeps names unique: several images in one share can otherwise
            // land on the same millisecond and overwrite each other.
            val target = File(
                cacheDir,
                "shared_${System.currentTimeMillis()}_$index.png",
            )
            contentResolver.openInputStream(uri)?.use { input ->
                target.outputStream().use { output -> input.copyTo(output) }
            } ?: return null

            mapOf(
                "path" to target.absolutePath,
                "mediaId" to mediaStoreId(uri),
                "fromShoto" to handedOutByShoto(uri),
            )
        } catch (error: Exception) {
            null
        }
    }

    /**
     * Whether this picture is one Shoto itself just handed out.
     *
     * **The covering flow ends by sharing, and Shoto is in the list of things
     * it can be shared to.** Somebody who covers an account number and then
     * picks Shoto — a perfectly sensible way to keep the clean copy — was met
     * with "cover private details, or save it?", offering to protect the very
     * file the previous screen had just produced. The question answers itself,
     * and asking it makes the app look like it has forgotten what it was
     * doing ten seconds ago.
     *
     * Decided on the URI's authority, which is exact rather than a guess. Every
     * share this app performs goes out through `share_plus`, whose provider is
     * declared as `${applicationId}.flutter.share_provider` — so this is the
     * literal question "did this come out of us", answered by identity. Nothing
     * here reads a filename, which would have been the fragile version of the
     * same idea: names are chosen by the code that wrote the file, survive
     * being copied by other apps, and are the first thing to change.
     *
     * Note it is deliberately *not* narrowed to the redacted copy. A picture
     * shared out of Shoto unchanged and immediately shared back is also one
     * whose owner has just been offered covering and declined it.
     */
    private fun handedOutByShoto(uri: Uri): Boolean =
        uri.authority == "$packageName.flutter.share_provider"

    /**
     * The MediaStore row id, when the shared image came from the gallery.
     *
     * photo_manager uses these same ids for its assets on Android, so this is
     * an exact identity match rather than a guess — no hashing, no comparing
     * pixels. Anything shared from an app's private storage has no id, which
     * correctly marks it as genuinely new.
     */
    private fun mediaStoreId(uri: Uri): String? {
        if (uri.authority != "media") return null
        val last = uri.lastPathSegment ?: return null
        return if (last.all { it.isDigit() }) last else null
    }

    /**
     * The shared images, whether one or many.
     *
     * Android models these as two different actions rather than one action
     * with a list of size one: ACTION_SEND carries a single Uri in
     * EXTRA_STREAM, ACTION_SEND_MULTIPLE carries an ArrayList under the same
     * key. Reading the wrong shape for the action returns null, which is why
     * selecting several screenshots in the gallery used to open the sheet
     * with nothing in it.
     */
    @Suppress("DEPRECATION")
    private fun readImageUris(): List<Uri> {
        val incoming = intent ?: return emptyList()
        val tiramisu = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU

        return when (incoming.action) {
            // The tile brought no payload — it is a request, not a delivery.
            // The capture notification brings one id, because it is offering
            // a *particular* screenshot. See [latestScreenshotUri].
            ACTION_CAPTURE_LAST -> {
                val named = incoming.getLongExtra(EXTRA_MEDIA_ID, 0L)
                listOfNotNull(
                    if (named > 0) mediaImageUri(named) else latestScreenshotUri(),
                )
            }

            Intent.ACTION_SEND -> {
                val uri = if (tiramisu) {
                    incoming.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    incoming.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                }
                listOfNotNull(uri)
            }

            Intent.ACTION_SEND_MULTIPLE -> {
                val uris = if (tiramisu) {
                    incoming.getParcelableArrayListExtra(
                        Intent.EXTRA_STREAM,
                        Uri::class.java,
                    )
                } else {
                    incoming.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                }
                uris?.filterNotNull() ?: emptyList()
            }

            else -> emptyList()
        }
    }
}
