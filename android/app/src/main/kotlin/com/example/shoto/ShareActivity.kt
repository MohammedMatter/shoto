package com.example.shoto

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import java.util.concurrent.Executors
import java.util.concurrent.Future
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Receives images shared into SHOTO from other apps.
 *
 * This is a *separate* activity from [MainActivity] on purpose. Handling the
 * share intent in the main activity meant every "share to SHOTO" tore the
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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // A single-use executor: this activity handles one share and then
        // finishes, so there is nothing to pool.
        incoming = Executors.newSingleThreadExecutor().submit<Map<String, Any?>> {
            describeIncomingImages()
        }
    }

    override fun getInitialRoute(): String = "/share"

    /**
     * Renders over whatever app the user was in, rather than covering it.
     *
     * Flutter paints an opaque surface by default, so without this the sheet
     * would sit on a black rectangle and read as "SHOTO opened" — exactly the
     * interruption this whole activity exists to avoid. The theme must also
     * set android:windowIsTranslucent, or this has no effect.
     */
    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        HapticsChannel.register(this, flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                // Every incoming image, each with its MediaStore id when it
                // has one. The id is what lets Dart tell "a screenshot SHOTO
                // already shows" from "an image from another app" — without
                // it, sharing your own screenshot back into SHOTO silently
                // wrote a second copy of it.
                // Already running since onCreate — this usually returns
                // immediately.
                "getSharedImages" -> result.success(
                    incoming?.get() ?: describeIncomingImages(),
                )

                // Called once the sheet is done. finishAndRemoveTask (rather
                // than finish) is what stops an empty SHOTO card being left
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
        )
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

            mapOf("path" to target.absolutePath, "mediaId" to mediaStoreId(uri))
        } catch (error: Exception) {
            null
        }
    }

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
