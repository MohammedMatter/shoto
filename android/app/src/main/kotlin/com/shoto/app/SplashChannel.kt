package com.shoto.app

import android.app.Activity
import android.app.UiModeManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Rect
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.PixelCopy
import android.view.View
import android.view.ViewGroup
import androidx.core.splashscreen.SplashScreen
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.core.splashscreen.SplashScreenViewProvider
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.renderer.FlutterUiDisplayListener
import io.flutter.plugin.common.MethodChannel

/**
 * The cold start, from the window Android paints before this process exists to
 * the first thing Flutter draws, as one continuous picture.
 *
 * ## What was wrong
 *
 * Three pictures in about two seconds. The platform splash showed the mark and
 * exited **the moment the activity could draw** — which is long before Dart has
 * finished starting, because `main()` waits on Firebase, a dozen preference
 * loads and a subscription lookup before it calls `runApp`. What followed was
 * one and a half to three seconds of a flat coloured field with nothing on it,
 * and then a hard cut to whatever screen the router had chosen. On a first
 * launch it was worse: the sign-in screen files the mark's three cards in as it
 * arrives, so the logo was shown finished, then taken away, then assembled
 * again in front of somebody who had already seen it.
 *
 * None of that is an artwork problem, which is why no amount of redrawing the
 * mark ever fixed it.
 *
 * ## What this does
 *
 * 1. **Holds the splash.** `setKeepOnScreenCondition` keeps the real launch
 *    window up until Flutter's first frame exists, so the dead field is gone
 *    rather than shortened — the mark stays on screen for exactly as long as
 *    starting up actually takes.
 *
 * 2. **Measures the handover.** `setOnExitAnimationListener` hands over the
 *    splash's own icon view. Its centre and size are read in real pixels and
 *    sent to Dart, which draws the same mark at the same size in the same
 *    place. Measured rather than computed from the documented 288/192dp
 *    canvas, because what a device actually does with that canvas is up to the
 *    device, and being eight pixels out reads as the mark jumping — a worse
 *    flicker than the one being fixed.
 *
 * 3. **Waits for Dart before it removes anything.** The platform's exit
 *    animation is replaced with nothing at all: Dart says when it has painted
 *    the matching frame, and only then does the splash view go. There is no
 *    cross-fade because there is nothing to cross-fade between.
 *
 * `SplashCurtain` in `lib/core/widgets/splash_curtain.dart` is the other half.
 *
 * ## What happens when a step fails
 *
 * **Every wait has a wall clock on it, because a launch screen that cannot be
 * dismissed is an app that never starts.** That is the one failure this whole
 * mechanism could introduce, and it would be indistinguishable from a hang.
 *
 * - Flutter never draws, so the hold is never released: [KEEP_TIMEOUT_MS].
 * - Dart never answers the handover: [RELEASE_TIMEOUT_MS].
 *
 * Both fall back to what the app did before any of this existed — the splash
 * goes, a flat field waits, Flutter arrives when it arrives. Degraded, never
 * broken.
 */
object SplashChannel {

    private const val CHANNEL = "shoto/splash"

    /**
     * The longest the launch screen may be held waiting for Flutter's first
     * frame.
     *
     * Generous on purpose. A cold start on a cheap phone with a cold Firebase
     * cache is genuinely slow, and cutting the splash off early would put the
     * empty field back, which is the exact thing being fixed. This is not a
     * budget for startup; it is the point at which we stop believing Flutter is
     * coming at all.
     */
    private const val KEEP_TIMEOUT_MS = 8_000L

    /**
     * The longest we wait, after the icon's rectangle has been sent, for Dart
     * to confirm it has painted the matching frame.
     *
     * Sized against what Dart actually does in that window rather than picked
     * for feel: it waits up to 400ms for this side to produce a rectangle, then
     * draws and waits one more frame. Nine hundred leaves real slack over that
     * on a phone busy starting up, and is still short enough that a Dart side
     * in genuine trouble is not left holding a launch screen over the user.
     */
    private const val RELEASE_TIMEOUT_MS = 900L

    private val main = Handler(Looper.getMainLooper())

    private var channel: MethodChannel? = null

    /** Cleared once Flutter's first frame exists, or once [KEEP_TIMEOUT_MS] does it. */
    private var holding = true

    /**
     * The exiting splash, held here between the platform handing it over and
     * Dart confirming it has drawn the same thing.
     */
    private var exiting: SplashScreenViewProvider? = null

    /**
     * The icon's measured geometry, in physical pixels, relative to Flutter's
     * own view.
     *
     * Kept rather than only pushed, because the push and Dart's arrival race:
     * the engine may have no handler attached when the splash exits. Dart asks
     * for this on its first frame and takes whichever answer is ready.
     */
    private var handoff: Map<String, Any>? = null

    /**
     * Set once Dart has confirmed it is drawing the matching frame.
     *
     * **Kept as state rather than acted on once**, because the confirmation and
     * the splash's exit race in both directions. Dart releases as soon as it has
     * given up waiting for a rectangle, which on a path where the platform never
     * produces one is *before* the exit listener has fired — and a release that
     * only knew how to remove a provider it could already see would leave that
     * later splash on screen until the timeout took it.
     */
    private var dartReady = false

    /**
     * Call from `onCreate`, **before** `super.onCreate`.
     *
     * `installSplashScreen` reads the splash attributes off the theme that is
     * current when it runs and then swaps in `postSplashScreenTheme`, so it has
     * to happen while the activity is still wearing LaunchTheme and before
     * `FlutterFragmentActivity.onCreate` calls `setContentView`.
     */
    fun install(activity: Activity) {
        holding = true
        dartReady = false
        exiting = null
        handoff = null

        val splash: SplashScreen = activity.installSplashScreen()
        splash.setKeepOnScreenCondition { holding }

        // The condition is polled from an OnPreDraw listener, so releasing it
        // is not enough on its own — something has to ask for a draw. Flutter's
        // first frame does that itself; the timeout has to do it by hand.
        main.postDelayed({ stopHolding(activity) }, KEEP_TIMEOUT_MS)

        splash.setOnExitAnimationListener { provider ->
            val geometry = measure(activity, provider)

            if (dartReady) {
                // Dart gave up waiting and is already drawing its own guess.
                // Nothing to hand over; take the window back.
                provider.remove()
                return@setOnExitAnimationListener
            }

            exiting = provider
            main.postDelayed({ release() }, RELEASE_TIMEOUT_MS)

            // Asynchronous, because reading the screen is. Dart is waiting on
            // this and has its own deadline, so a sample that never arrives
            // costs a slightly imperfect handover rather than a stalled launch.
            sampleField(activity, provider) { field ->
                handoff = geometry?.plus(
                    if (field == null) emptyMap() else mapOf("field" to field)
                )

                // May land on nothing: Dart asks for the same values on its
                // first frame, and whichever of the two arrives first wins.
                handoff?.let { channel?.invokeMethod("handoff", it) }
            }
        }
    }

    /** Call from `configureFlutterEngine`. */
    fun register(activity: Activity, engine: FlutterEngine) {
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    // Dart's first frame asking where the mark is. Null means
                    // the splash has not exited yet, or that the platform gave
                    // us no icon to measure, and the curtain centres the mark
                    // itself.
                    "handoff" -> result.success(handoff)
                    // Dart has painted the matching frame. Nothing else is
                    // allowed to take the splash away before this.
                    "release" -> {
                        release()
                        result.success(null)
                    }
                    // Shoto's own light/dark setting, told to the system so the
                    // launch window can resolve it. See [pinNightMode].
                    "nightMode" -> {
                        pinNightMode(activity, call.arguments as? String)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        engine.renderer.addIsDisplayingFlutterUiListener(
            object : FlutterUiDisplayListener {
                override fun onFlutterUiDisplayed() {
                    engine.renderer.removeIsDisplayingFlutterUiListener(this)
                    // Delivered off the raster thread.
                    main.post { stopHolding(activity) }
                }

                override fun onFlutterUiNoLongerDisplayed() = Unit
            }
        )
    }

    /**
     * Tells the system which mode Shoto is in, so that the window Android
     * paints before this process exists is painted in the right one.
     *
     * **This is the only fix for the last visible seam in a cold start, and
     * nothing inside the app can substitute for it.** On Android 12 and up the
     * platform builds its splash window from the activity's theme *before the
     * app has a process*, resolving `values-night` against the system's mode.
     * A user who has pinned light inside Shoto on a phone in dark mode
     * therefore gets a near-black launch screen in front of a near-white app —
     * measured on a Xiaomi where the vendor's own dark mode reports night while
     * `ui_night_mode` is 0, with Shoto pinned light. Every in-app remedy is
     * cosmetic by definition: by the time any Dart or Kotlin runs, the wrong
     * window is already on screen.
     *
     * `setApplicationNightMode` is the platform's answer to exactly this. It
     * persists a per-application override that the system itself resolves
     * resources against, which is what the starting window uses. It exists for
     * apps that carry their own dark-mode setting, and Shoto is one.
     *
     * **It takes effect from the next cold start, not this one.** The window it
     * fixes was created before we could speak. That is not a shortcoming of the
     * call, it is the shape of the problem — and it is why `SplashCurtain` still
     * carries a field that can travel from one mode to the other: for the launch
     * where this has not applied yet, and for every device below API 31 where it
     * does not exist.
     *
     * Wrapped, because a vendor is free to have an opinion about it and a launch
     * screen in the wrong colour must never become an app that will not start.
     */
    private fun pinNightMode(context: Context, mode: String?) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return

        val night = when (mode) {
            "light" -> UiModeManager.MODE_NIGHT_NO
            "dark" -> UiModeManager.MODE_NIGHT_YES
            // Anything else means the user has not pinned anything, and the
            // override has to be *cleared* rather than left standing — someone
            // moving from "dark" back to "system" would otherwise keep a dark
            // launch screen on a light phone forever.
            else -> UiModeManager.MODE_NIGHT_AUTO
        }

        try {
            (context.getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager)
                ?.setApplicationNightMode(night)
        } catch (_: Throwable) {
        }
    }

    /**
     * Releases the hold and pokes the view tree, because the condition is only
     * consulted when something draws and nothing else is going to.
     */
    private fun stopHolding(activity: Activity) {
        if (!holding) return
        holding = false
        activity.findViewById<View>(android.R.id.content)?.invalidate()
    }

    /**
     * Takes the splash view away, and remembers that it may go.
     *
     * Safe to call any number of times and in either order against the exit
     * listener — see [dartReady].
     */
    private fun release() {
        dartReady = true
        exiting?.remove()
        exiting = null
    }

    /**
     * The icon's centre and size in physical pixels, **relative to Flutter's
     * own view** rather than to the screen.
     *
     * The two are not the same rectangle. Flutter's logical origin is the top
     * left of [FlutterView], and where that sits inside the window depends on
     * the window's insets and on whether the app is drawing edge to edge — a
     * status bar's worth of difference is about seventy pixels, which on a
     * handover meant to be invisible is not a rounding error, it is the mark
     * jumping.
     *
     * Returns null if either view has not been laid out, which is a real
     * possibility on a path where the splash exits before the fragment is
     * attached. The curtain centres the mark itself in that case: slightly
     * wrong is survivable, wrong by an unknown amount is not.
     */
    private fun measure(
        activity: Activity,
        provider: SplashScreenViewProvider,
    ): Map<String, Any>? {
        val icon: View = provider.iconView
        if (icon.width == 0 || icon.height == 0) return null

        val flutter = findFlutterView(activity.window.decorView) ?: return null

        val iconAt = IntArray(2).also { icon.getLocationOnScreen(it) }
        val flutterAt = IntArray(2).also { flutter.getLocationOnScreen(it) }

        return mapOf(
            "centreX" to (iconAt[0] - flutterAt[0] + icon.width / 2.0),
            "centreY" to (iconAt[1] - flutterAt[1] + icon.height / 2.0),
            // The icon *view*, not the ink inside it. Dart knows what fraction
            // of that box the drawing occupies, because Dart is what drew the
            // file the platform is displaying. See `splash_curtain.dart`.
            "size" to icon.width.toDouble(),
        )
    }

    /**
     * The colour the launch window is **actually showing**, read off the screen
     * rather than worked out from the theme.
     *
     * ## Why a screenshot and not a resource
     *
     * `@color/splash_background` says what we asked for. It is not always what
     * is on the glass. Measured on a Xiaomi with the vendor's own dark mode on:
     * the light field went up as `#F4F4F4` and came back `#212121`, while a
     * probe colour of pure red came back `#FE0000` untouched — the signature of
     * a smart force-dark, which inverts light neutrals and leaves chroma alone.
     * `android:forceDarkAllowed=false` does not stop it on that window, with
     * `isLightTheme` set either way, and `windowSplashScreenBackground` is
     * demonstrably honoured, so there is nothing left to correct from this side.
     *
     * The point of the handover is that Dart's first frame is **the same
     * picture** the user is already looking at. Predicting that picture means
     * modelling every vendor's dark mode forever and being wrong on the next
     * phone. Looking at it needs no model at all: whatever mangling happened,
     * happened before this reads it.
     *
     * ## Where it samples
     *
     * The left edge at mid height. The mark's ink starts about a quarter of the
     * way across, so this is field and nothing else, on every size of screen.
     *
     * Returns null on anything unexpected — too old for the `Window` overload,
     * a view with no size, a copy the compositor refuses. Dart then falls back
     * to the colour the theme *should* have produced, which is right everywhere
     * a vendor has not intervened.
     */
    private fun sampleField(
        activity: Activity,
        provider: SplashScreenViewProvider,
        onSampled: (Int?) -> Unit,
    ) {
        val view: View = provider.view
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
            view.width == 0 ||
            view.height == 0
        ) {
            onSampled(null)
            return
        }

        val at = IntArray(2).also { view.getLocationInWindow(it) }
        val x = at[0] + 4
        val y = at[1] + view.height / 2
        val bitmap = Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888)

        try {
            PixelCopy.request(
                activity.window,
                Rect(x, y, x + 1, y + 1),
                bitmap,
                { status ->
                    val colour = if (status == PixelCopy.SUCCESS) {
                        bitmap.getPixel(0, 0)
                    } else {
                        null
                    }
                    bitmap.recycle()
                    onSampled(colour)
                },
                main,
            )
        } catch (_: Throwable) {
            bitmap.recycle()
            onSampled(null)
        }
    }

    private fun findFlutterView(view: View): View? {
        if (view is FlutterView) return view
        if (view !is ViewGroup) return null
        for (i in 0 until view.childCount) {
            findFlutterView(view.getChildAt(i))?.let { return it }
        }
        return null
    }
}
