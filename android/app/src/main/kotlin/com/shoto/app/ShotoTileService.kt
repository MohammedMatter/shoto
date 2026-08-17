package com.shoto.app

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/**
 * The Quick Settings tile: **keep the screenshot I just took.**
 *
 * Everything else in Shoto is downstream of one act the app cannot perform
 * for you — handing it a screenshot. Until now the only way to do that was
 * the Android share sheet: open the shot, tap share, then hunt for Shoto's
 * icon in a grid of twenty apps that reorders itself by usage. Three of those
 * four steps are searching rather than deciding, and every one of them
 * happens *after* the moment the screenshot was taken, which is the only
 * moment the user still remembers why they took it.
 *
 * A tile is the one surface on Android that never moves. It sits beside the
 * torch, two gestures from anywhere, in the same square every single time —
 * so the act of filing stops being a search and becomes muscle memory. That,
 * and not the saved taps, is the point.
 *
 * **It renders no UI of its own.** The tile resolves the newest screenshot
 * and hands it to [ShareActivity] under [ShareActivity.ACTION_CAPTURE_LAST]
 * — the same translucent sheet, the same folder strip, the same "create your
 * first folder" path that a real share gets. Two entry points, one flow: if
 * the sheet gains a stage, the tile gains it too, with nobody having to
 * remember this file exists.
 */
class ShotoTileService : TileService() {

    /**
     * Shown the moment the panel opens.
     *
     * [Tile.STATE_INACTIVE] rather than `STATE_ACTIVE`, and it is not a
     * cosmetic choice: an active tile is how Android says *this thing is
     * currently switched on*. Nothing here stays on — a tap does one piece of
     * work and ends — so a permanently lit tile would be the panel telling a
     * lie in the panel's own vocabulary, right beside a torch where the same
     * highlight means something true.
     */
    override fun onStartListening() {
        super.onStartListening()
        qsTile?.apply {
            state = Tile.STATE_INACTIVE
            updateTile()
        }
    }

    /**
     * **Unlocked first, always.**
     *
     * A tile is reachable from the lock screen, and reading the newest
     * screenshot is reading the user's gallery — so the sheet must never
     * appear over a locked phone. [unlockAndRun] hands the prompt to the
     * system, which is the only thing entitled to ask, and runs nothing if
     * the user backs out. On an already-unlocked device it invokes the block
     * straight away, so the ordinary case costs nothing.
     */
    override fun onClick() {
        super.onClick()
        unlockAndRun { open() }
    }

    private fun open() {
        val intent = Intent(this, ShareActivity::class.java).apply {
            action = ShareActivity.ACTION_CAPTURE_LAST
            // The sheet lives in its own task so it can float over whatever
            // app the panel was pulled down on top of, exactly as a share
            // does. Launching from a service demands NEW_TASK regardless.
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        // Android 14 made `startActivityAndCollapse(Intent)` throw rather than
        // deprecating it quietly — a tile must now hand over a PendingIntent
        // so the system, not the tile, decides what is launched from a
        // trusted surface. Both forms are kept because the older one is the
        // only one that exists below 34.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(
                PendingIntent.getActivity(
                    this,
                    0,
                    intent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                ),
            )
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}
