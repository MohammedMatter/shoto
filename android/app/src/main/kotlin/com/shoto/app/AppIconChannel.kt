package com.shoto.app

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Swaps the launcher icon by enabling one component and disabling the rest.
 *
 * Android has no API for "change my icon". What it has is
 * [PackageManager.setComponentEnabledSetting], and the trick every app that
 * offers alternate icons uses: declare one `<activity-alias>` per icon, each
 * with its own `android:icon` and a LAUNCHER intent filter, and keep exactly
 * one of them enabled. The launcher reads the enabled ones and draws an entry
 * for each.
 *
 * ## The ordering is the whole of the safety here
 *
 * "Exactly one" is the invariant, and the two ways to break it are not equally
 * bad. Two enabled components put two Shoto icons on the home screen, which is
 * ugly and fixable from this same screen. **Zero enabled components remove the
 * app from the launcher entirely** — there is no icon left to tap, and short of
 * finding it in the app list or reinstalling, the user has lost it.
 *
 * So this enables the incoming component *before* disabling anything, and
 * disables the others one at a time afterwards. If the process dies at any
 * point in between — and changing a component's state is itself a reason
 * Android may kill it — the worst reachable state is two icons. Zero is not
 * reachable.
 *
 * The reverse order is the obvious way to write this and is the bug: disable
 * the old one first and every interruption between the two calls leaves the
 * app with no launcher entry at all.
 *
 * ## DONT_KILL_APP is a request, not a promise
 *
 * It is passed because being killed mid-swap is worth avoiding, but Android
 * still frequently restarts the process after a launcher component changes —
 * which is why the Dart side warns the user before calling this rather than
 * treating the swap as instant and silent.
 */
object AppIconChannel {

    private const val CHANNEL = "shoto/app_icon"

    /**
     * Every component this app can be launched by, default first.
     *
     * Kept here rather than derived from the incoming argument so a bad value
     * from Dart can never disable something this does not own — the list is
     * the authority on what may be switched off.
     *
     * `MainActivity` is the default and is deliberately a real activity rather
     * than a seventh alias: one component has to be enabled on a fresh install
     * before any of this code has run, and the manifest's own default is the
     * only thing that can guarantee it.
     */
    private val components = listOf(
        "com.shoto.app.MainActivity",
        "com.shoto.app.IconTeal",
        "com.shoto.app.IconIndigo",
        "com.shoto.app.IconPlum",
        "com.shoto.app.IconEmber",
        "com.shoto.app.IconMoss",
    )

    fun register(context: Context, engine: FlutterEngine) {
        val appContext = context.applicationContext

        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setIcon" -> {
                        val target = call.argument<String>("component")
                        if (target == null || target !in components) {
                            result.error(
                                "unknown_icon",
                                "Not a launcher component of this app: $target",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        result.success(apply(appContext, target))
                    }

                    "currentIcon" -> result.success(current(appContext))

                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Enables [target], then disables everything else. Returns the component
     * actually in force afterwards.
     */
    private fun apply(context: Context, target: String): String {
        val packageManager = context.packageManager

        packageManager.setComponentEnabledSetting(
            ComponentName(context, target),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )

        for (component in components) {
            if (component == target) continue
            packageManager.setComponentEnabledSetting(
                ComponentName(context, component),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }

        return target
    }

    /**
     * Which component the launcher is currently showing.
     *
     * Read from the package manager rather than from the stored preference,
     * because the two can disagree: a swap that was interrupted leaves the
     * preference ahead of reality, and this is the side that is actually on the
     * home screen.
     *
     * `COMPONENT_ENABLED_STATE_DEFAULT` means "whatever the manifest says",
     * which is enabled for `MainActivity` and disabled for every alias — so it
     * is only treated as enabled for the default component.
     */
    private fun current(context: Context): String {
        val packageManager = context.packageManager

        for (component in components) {
            val state = packageManager.getComponentEnabledSetting(
                ComponentName(context, component),
            )
            val enabled = state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED ||
                (state == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT &&
                    component == components.first())
            if (enabled) return component
        }

        return components.first()
    }
}
