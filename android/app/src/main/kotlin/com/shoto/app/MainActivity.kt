package com.shoto.app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// local_auth's Android implementation needs a FragmentActivity host to show
// the BiometricPrompt dialog for private-folder unlock.
class MainActivity : FlutterFragmentActivity() {

    // **No window-background correction here any more.** This class used to
    // read `theme_mode` straight out of `FlutterSharedPreferences` in `onCreate`
    // and repaint the activity window in the mode the user had pinned inside
    // Shoto, because Android resolves `values-night` from the *system* setting
    // before this process exists — so a user holding Shoto dark on a light phone
    // got a light launch window and a hard cut to the app's real background.
    //
    // The launch field still follows the system's mode rather than Shoto's, and
    // that mismatch is simply no longer worth code. It used to end in a hard cut
    // from a light launch window to a dark app; `SplashCurtain` dissolves the
    // field instead of handing over to it, so what a pinned mode costs now is a
    // launch screen in the other mode for a second, not a flash. Guessing the
    // user's preference out of `FlutterSharedPreferences` from Kotlin was a lot
    // of machinery to avoid one frame that no longer exists.
    // See `values/colors.xml` and SplashChannel.

    /**
     * **Before `super.onCreate`, and that ordering is the whole contract.**
     *
     * `installSplashScreen` reads the launch screen off whatever theme the
     * activity is currently wearing and then swaps in `postSplashScreenTheme`.
     * `FlutterFragmentActivity.onCreate` calls `setContentView` almost
     * immediately, and the library has to be in place before that. See
     * SplashChannel.
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        SplashChannel.install(this)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // First, because it is the only one holding a window open: the
        // launch screen stays up until this attaches a listener and Dart
        // answers on the other side.
        SplashChannel.register(this, flutterEngine)
        HapticsChannel.register(this, flutterEngine)
        FilePickerChannel.register(this, flutterEngine)
        // Only here, not in ShareActivity: the sheet is what the tile opens,
        // so offering to install the tile from inside it would be the feature
        // advertising itself to somebody already using it.
        TileChannel.register(this, flutterEngine)
        CaptureAlertsChannel.register(this, flutterEngine)
        // Also only here. The share sheet has no settings, and the one thing
        // this does — disable the component the sheet may itself have been
        // launched from — is not something to expose to it.
        AppIconChannel.register(this, flutterEngine)
        RemindersChannel.register(this, flutterEngine)
    }

    /**
     * The activity is `singleTop`, so tapping a reminder while Shoto is
     * already running delivers the intent here rather than through `onCreate`.
     * Without this, the notification would simply bring the app forward on
     * whatever screen it was left on and never open the screenshot it was
     * about.
     */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        RemindersChannel.captureLaunchIntent(intent)
    }

    // Only the picker's own request code is consumed; everything else still
    // reaches super, or photo_manager's permission flows would break.
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (FilePickerChannel.onActivityResult(this, requestCode, resultCode, data)) {
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
