package com.shoto.app

import android.content.Context
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Drives the device vibrator directly, because Flutter's own haptics don't
 * reach the user on a lot of Android hardware.
 *
 * `HapticFeedback.lightImpact()` and friends call `View.performHapticFeedback`
 * with a [android.view.HapticFeedbackConstants] value. Those constants are
 * *suggestions*: each OEM decides what — if anything — they map to, and on
 * several popular skins the ones an app is allowed to use produce no motion at
 * all. The result is code that runs perfectly and a user who feels nothing,
 * which is exactly what was reported here on a device whose system haptics
 * were on and at maximum strength.
 *
 * Going through [Vibrator] instead means the effect we ask for is the effect
 * that plays. It costs the VIBRATE permission and this file; nothing else.
 *
 * Registered by both activities — the share sheet is a separate activity with
 * its own engine, and a button that buzzes in the app but not in the sheet is
 * worse than one that never buzzes at all.
 */
object HapticsChannel {

    private const val CHANNEL = "shoto/haptics"

    fun register(context: Context, engine: FlutterEngine) {
        val appContext = context.applicationContext

        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                val vibrator = vibrator(appContext)

                // Reported rather than thrown: a tablet with no vibrator is a
                // normal device, not an error, and Dart falls back to
                // Flutter's own haptics when this comes back false.
                if (vibrator == null || !vibrator.hasVibrator()) {
                    result.success(false)
                    return@setMethodCallHandler
                }

                val effect = effectFor(call.method, vibrator)
                if (effect == null) {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                play(vibrator, effect)
                result.success(true)
            }
    }

    /**
     * The strengths the app speaks in, mirroring `Haptics` on the Dart side.
     * Kept deliberately small — an interface that vibrates in six
     * distinguishable ways is one nobody can read.
     *
     * `tick` is the one entry that is not trying to be told apart from the
     * others; it is the texture of a wheel turning, and it is the only effect
     * that fires dozens of times inside one gesture.
     */
    private fun effectFor(method: String, vibrator: Vibrator): VibrationEffect? =
        when (method) {
            // One detent of a picker wheel. Below `tap` on purpose: a fling
            // down the minute wheel plays this thirty times in a second, and
            // at tap strength that is a buzz rather than a texture.
            "tick" -> preferred(vibrator, VibrationEffect.EFFECT_TICK, 0.28f)

            // A tap landed. The lightest one of the four that mean something,
            // and by far the most frequent — anything heavier here becomes
            // noise within a minute of use.
            "tap" -> preferred(vibrator, VibrationEffect.EFFECT_TICK, 0.55f)

            // Something committed — saved, filed, deleted.
            "confirm" -> preferred(vibrator, VibrationEffect.EFFECT_CLICK, 0.8f)

            // Something refused. The only one meant to be noticed without
            // looking at the screen.
            "reject" -> preferred(vibrator, VibrationEffect.EFFECT_HEAVY_CLICK, 1f)

            // A long press registered, before whatever it opens appears.
            "longPress" -> preferred(vibrator, VibrationEffect.EFFECT_CLICK, 0.85f)

            else -> null
        }

    /**
     * Prefers the OEM's own tuned effect, falls back to an explicit pulse.
     *
     * Predefined effects are what the manufacturer designed for this exact
     * motor, so they feel crisp rather than buzzy — but a device only has to
     * *accept* them, not implement them, so [Vibrator.areEffectsSupported] is
     * asked before one is trusted. Plenty of phones answer "none": the device
     * this was first reported on lists `mSupportedEffects=[]`.
     */
    private fun preferred(
        vibrator: Vibrator,
        predefined: Int,
        strength: Float,
    ): VibrationEffect {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val support = vibrator.areEffectsSupported(predefined).firstOrNull()
            if (support == Vibrator.VIBRATION_EFFECT_SUPPORT_YES) {
                return VibrationEffect.createPredefined(predefined)
            }
        }

        // Two different motors need two different answers, and treating them
        // the same is why this felt like nothing on real hardware.
        //
        // A linear actuator starts and stops almost instantly, so it can be
        // driven quietly and briefly — strength carries the difference between
        // a tap and a rejection.
        //
        // A rotating-mass motor has to physically spin up. It cannot be driven
        // gently at all (no amplitude control), and a pulse as short as an LRA
        // tick ends before the mass has moved enough to feel. There, duration
        // is the only dial available, so every pulse is longer.
        if (vibrator.hasAmplitudeControl()) {
            val ms = (10 + strength * 22).toLong()
            val amplitude = (strength * 255).toInt().coerceIn(1, 255)
            return VibrationEffect.createOneShot(ms, amplitude)
        }

        val ms = (24 + strength * 46).toLong()
        return VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE)
    }

    /**
     * Declared as touch feedback on purpose.
     *
     * That tells the system these are responses to something the user just
     * did, so they stay silent under Do Not Disturb and honour the "touch
     * vibration" setting. Tagging them as anything louder would make the app
     * buzz through situations the user deliberately silenced.
     */
    private fun play(vibrator: Vibrator, effect: VibrationEffect) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            vibrator.vibrate(
                effect,
                VibrationAttributes.createForUsage(VibrationAttributes.USAGE_TOUCH),
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(effect)
        }
    }

    /**
     * `VibratorManager` is the supported route from Android 12; the older
     * system service still exists but is deprecated and, on multi-actuator
     * devices, drives only the default motor.
     */
    private fun vibrator(context: Context): Vibrator? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = context.getSystemService(VibratorManager::class.java)
            return manager?.defaultVibrator
        }
        @Suppress("DEPRECATION")
        return context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
    }
}
