package com.shoto.app

import android.content.Context
import android.content.Intent
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// local_auth's Android implementation needs a FragmentActivity host to show
// the BiometricPrompt dialog for private-folder unlock.
class MainActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // After, not before: `FlutterActivity.onCreate` is where the window is
        // switched from LaunchTheme to NormalTheme, and NormalTheme sets the
        // very background this is here to correct. Running first would have the
        // framework overwrite it a moment later.
        super.onCreate(savedInstanceState)
        applyChosenWindowBackground()
    }

    /**
     * Paints the launch window in the theme the user chose *inside Shoto*,
     * rather than the one their phone is set to.
     *
     * Android resolves `values-night` from the system's dark mode setting, and
     * it does so before this process exists — so a user who has pinned Shoto
     * dark on a light phone (or the reverse) gets a launch window in the wrong
     * colour, then a hard cut to the app's real background. It was a paid
     * option until now, which is the only reason it was rare enough to live
     * with.
     *
     * The preference is read straight out of `shared_preferences`' own file.
     * That is a coupling worth naming: `ThemeController` writes
     * `theme_mode`, the plugin stores it under the `flutter.` prefix in
     * `FlutterSharedPreferences`, and this reads it back by hand because the
     * only moment it is needed — before the engine has started — is the one
     * moment no method channel exists yet. If that key or that plugin ever
     * changes, this goes quietly back to following the system, which is the
     * behaviour it replaced and not a crash.
     *
     * **`system` deliberately does nothing.** With no override, the resource
     * qualifier is already the right answer, and writing the colour by hand
     * would only add a way to be wrong.
     *
     * This cannot fix the *starting* window — the frame Android paints from
     * `LaunchTheme` before any of this app's code runs. Only the system can
     * choose that, and the API that would tell it
     * (`UiModeManager.setApplicationNightMode`) has no documented way back to
     * "just follow the phone", which is a worse bug than the one being fixed.
     */
    private fun applyChosenWindowBackground() {
        val chosen = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getString("flutter.theme_mode", null)

        val colour = when (chosen) {
            "light" -> ContextCompat.getColor(this, R.color.splash_background_light)
            "dark" -> ContextCompat.getColor(this, R.color.splash_background_dark)
            else -> return
        }

        window.setBackgroundDrawable(ColorDrawable(colour))
        // The bars too, or the corrected window arrives inside a frame of the
        // system's idea of the theme. Flutter sets these again from
        // `SystemChrome` on its first frame; this is only for the wait before
        // that.
        window.statusBarColor = colour
        window.navigationBarColor = colour
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
