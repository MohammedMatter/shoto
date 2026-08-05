import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/asset_thumbnail_image.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';

/// A folder, shown as **what is inside it**.
///
/// This card used to be a bordered surface holding a 44px tinted square with
/// `Icons.folder_rounded` in it. Every folder on the page was therefore the
/// same picture, and the only thing telling twelve of them apart was a line of
/// text and a hue on a chip small enough to miss. Recognising your own folder
/// — which is the entire task of this screen — was left to reading.
///
/// So the icon is gone and the newest screenshot filed into the folder is the
/// card. That is not decoration: a folder of receipts and a folder of recipes
/// are instantly distinguishable by their contents and by nothing else, and it
/// is the same reason every gallery app on the phone shows album covers rather
/// than folder glyphs.
///
/// ---
///
/// **The card has no container**, and that is deliberate.
///
/// A surface, a border and a radius around each tile is what made this page
/// read as a template — the same finding Home reached when it replaced three
/// stat cards with one line of text. Here the cover already *is* a solid
/// rectangle with an edge; wrapping it in a second one is an outline around an
/// outline. The name and count sit on the page itself, so a screen of twelve
/// folders is twelve pictures instead of twelve boxes.
///
/// ---
///
/// **The colour bar is the one saturated thing here**, and it earns its place
/// on the terms `folder_colors.dart` sets out: these hues are the user's own
/// filing marks, not the interface speaking. It sits on the bottom edge of the
/// cover — the coloured edge of a filed card — rather than as a chip beside
/// the name, because a photo cover would otherwise leave the colour with
/// nowhere to be seen.
class FolderCard extends StatelessWidget {
  final FolderEntity folder;

  /// The newest screenshot filed in this folder, or null when the folder is
  /// empty or the library has not loaded yet.
  ///
  /// Passed in rather than looked up here: the page derives every cover from
  /// the one library the shell already has in memory, in a single pass, so a
  /// grid of twelve folders does not run twelve queries.
  final AssetEntity? cover;

  final VoidCallback onTap;

  /// Opens rename/delete. Wired to both the always-visible "⋯" button and a
  /// long-press: the button is what makes the actions discoverable at all
  /// (a long-press has no visual affordance, so nobody finds it), the
  /// long-press stays as a shortcut for people who already know.
  final VoidCallback onMoreTap;

  const FolderCard({
    super.key,
    required this.folder,
    required this.onTap,
    required this.onMoreTap,
    this.cover,
  });

  /// The bottom edge of the cover, in the folder's own colour.
  static double get _spine => 4.h;

  @override
  Widget build(BuildContext context) {
    final Color color = Color(folder.color);

    // Deliberately not animated on build. This card lives in a scrolling
    // grid, where tiles are recycled constantly — an entrance animation
    // there replays every time a tile scrolls back into view, which both
    // looks broken and spins up an animation controller per tile per frame.
    // The one entrance this page does have is applied by the page, once, to
    // the first few tiles only. See EntranceStagger.
    return PressableScale(
      onTap: onTap,
      onLongPress: onMoreTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expanded rather than a fixed AspectRatio: the caption below takes
          // exactly the height its text needs and the cover absorbs whatever
          // is left. At a large system text scale that means a slightly
          // shorter picture, which is invisible — where a fixed-ratio cover
          // would push the caption past the bottom of the tile and stripe it.
          Expanded(
            child: _Cover(folder: folder, cover: cover, color: color),
          ),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  folder.name,
                  style: AppTextStyles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Below the cover rather than floating on top of it. Overlaid on
              // a photograph this glyph needs a scrim behind it to stay
              // legible against every possible screenshot, and a scrim in the
              // corner of every tile is a smudge on twelve pictures. Down
              // here it sits on the page's own background and is simply
              // always readable.
              PressableScale(
                scale: 0.85,
                onTap: onMoreTap,
                child: Padding(
                  // Asymmetric: the glyph is pulled tight to the tile's
                  // trailing edge while the tap target keeps its full size.
                  padding: EdgeInsetsDirectional.only(
                    start: 8.w,
                    end: 2.w,
                    top: 2.h,
                    bottom: 6.h,
                  ),
                  child: Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.textSecondary,
                    size: 17.sp,
                  ),
                ),
              ),
            ],
          ),
          Text(
            context.l10n.countScreenshots(folder.screenshotCount),
            style: AppTextStyles.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  final FolderEntity folder;
  final AssetEntity? cover;
  final Color color;

  const _Cover({
    required this.folder,
    required this.cover,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // **A private folder never shows its contents.**
    //
    // The whole point of the flag is that opening this folder costs a
    // fingerprint, and a cover thumbnail on the grid hands over the one thing
    // the lock exists to withhold — to anybody who picks up the phone, without
    // touching it. So the check is here, in the widget that would draw the
    // picture, rather than at the call site where a later refactor could
    // forget it.
    final bool showContents = !folder.isPrivate && cover != null;

    // **A hairline, for the same reason the recents strip on Home has one.**
    //
    // The canvas is `#1A1A1A`, and the two things this cover can be are both
    // capable of matching it: a screenshot of a dark app, or the placeholder
    // below, which is the folder's own colour at 14% — very dark for every hue
    // in `folder_colors.dart`. Either way the tile loses its edge and reads as
    // a hole in the page rather than as an object on it, which is precisely
    // what happened to the dark cards in Home's recents strip on a device.
    //
    // Drawn *over* the content rather than under it, so it survives whatever
    // the cover turns out to be.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        // Inset by the border so the image does not paint over the line that
        // is there to contain it.
        borderRadius: BorderRadius.circular(AppRadius.md - 1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showContents)
              AssetThumbnailImage(asset: cover!)
            else
              _Placeholder(folder: folder, color: color),
            // The coloured edge of a filed card. Inside the clip and on the
            // bottom edge, so it costs no vertical space and follows the
            // cover's own corners.
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: FolderCard._spine,
                width: double.infinity,
                child: ColoredBox(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What stands in for a picture when there is no picture to show: an empty
/// folder, or a locked one.
///
/// **Neutral, with the colour carried by the glyph and the spine.**
///
/// This was a wash of the folder's own colour at 14%. The reasoning was that
/// an empty folder is still one the user made and named and tagged, and a
/// grey box would make the newest, emptiest folder — the one just created,
/// which is exactly the one being looked for — the least recognisable thing
/// on the screen. That reasoning is right, and nothing here gives it up: the
/// glyph and the spine are both still the folder's colour, at full strength,
/// which is what identifies it.
///
/// What changed is the *area*. SHOTO's stated rule is that the interface has
/// no colour and the screenshots do — the whole palette is built on it, and
/// it is the argument that makes a screen full of other apps' screenshots
/// readable at all. A grid of empty folders was the one place that rule broke
/// outright: four half-tile fields of tinted colour, none of them a
/// screenshot, on the second-most-visited tab. Recognition costs a glyph and
/// a 4px edge; it never needed the whole cover.
class _Placeholder extends StatelessWidget {
  final FolderEntity folder;
  final Color color;

  const _Placeholder({required this.folder, required this.color});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Icon(
          folder.isPrivate ? Icons.lock_rounded : Icons.folder_rounded,
          color: color,
          // Sized against the cover rather than against the icon scale
          // elsewhere in the app. At the 28sp a glyph takes in a row it was
          // adrift in the middle of a half-width tile — the placeholder is
          // standing in for a photograph, so it has to carry the same weight
          // the photograph would.
          size: 36.sp,
        ),
      ),
    );
  }
}
