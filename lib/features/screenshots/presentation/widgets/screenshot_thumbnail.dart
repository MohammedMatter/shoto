import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/core/widgets/asset_thumbnail_image.dart';
import 'package:shoto/core/widgets/photo_hero.dart';
import 'package:shoto/features/screenshots/presentation/widgets/intent_visuals.dart';

/// One screenshot in the grid.
///
/// The image goes through an [ImageProvider] rather than a `FutureBuilder`
/// around `thumbnailDataWithSize`, and that distinction is the whole reason
/// the grid used to flicker.
///
/// A future created inside `build()` is a *new* future on every rebuild — so
/// switching tabs, toggling a favourite, entering selection mode or changing
/// the grid density each kicked off a fresh fetch across the platform
/// channel, and the tile rendered an empty box until it came back. The image
/// visibly vanished and popped back for reasons that had nothing to do with
/// the image. Scrolling was the same bug wearing a different hat: every tile
/// recycled back into view paid for a full re-fetch and re-decode, because
/// `Image.memory` never touches Flutter's image cache.
///
/// An `ImageProvider` is keyed by asset and size, so the second request for
/// the same thumbnail is a cache hit — no channel call, no decode, no gap.
class ScreenshotThumbnail extends StatelessWidget {
  final AssetEntity asset;
  final bool isFavorite;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onMoreTap;

  /// What the user said they would do with this one, if anything.
  ///
  /// **This is the only place an intent is visible without opening
  /// something**, and that is the point of it. Before this badge existed the
  /// answer lived behind a quick-actions sheet behind a 18sp icon, which made
  /// a feature about what you owe yourself invisible in the one screen where
  /// you look at everything you have saved.
  ///
  /// Null for the great majority of screenshots, which show nothing.
  final IntentState? intent;

  /// Pairs this tile with the same screenshot in the full-screen viewer, so
  /// opening one grows out of the tile that was tapped instead of appearing
  /// from nowhere over it.
  ///
  /// Must be unique **within a route**, which is why it is passed in rather
  /// than derived from the asset here: Home and Library are two grids living
  /// in the same shell route at the same time, and both can show the same
  /// screenshot. Callers namespace it.
  ///
  /// Null disables the pairing — correct for any grid that is not the source
  /// of a push.
  final Object? heroTag;

  const ScreenshotThumbnail({
    super.key,
    required this.asset,
    required this.isFavorite,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    this.onMoreTap,
    this.intent,
    this.heroTag,
  });

  Widget _withHero(Widget child) => heroTag == null
      ? child
      // The radius is declared rather than only drawn, so the flight can open
      // the corner out into the full-screen viewer instead of squaring it off
      // on its first frame. See PhotoHero.
      : PhotoHero(tag: heroTag!, radius: AppRadius.md, child: child);

  @override
  Widget build(BuildContext context) {
    // No entrance animation here on purpose. Thumbnails live in a recycling
    // grid: an animation attached to build replays every time a tile scrolls
    // back into view, which reads as flicker and allocates an animation
    // controller per tile per frame. Entrances belong to screens, not to
    // list items.
    return PressableScale(
      scale: 0.97,
      onTap: onTap,
      onLongPress: onLongPress,
      // Deliberately *not* clipped.
      //
      // The clipped corner was tried here first and taken back out: on a
      // photograph a missing corner reads as a rendering fault rather than as
      // a filing mark. The gesture only survives on surfaces the app drew
      // itself, where nothing is obviously being cut away.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Only the picture flies. The favourite heart, the selection
            // ring and the quick-actions button belong to *this* grid and
            // have no counterpart on the other side, so carrying them along
            // would mean animating widgets into nothing.
            _withHero(AssetThumbnailImage(asset: asset)),
            // Everything below is built **unconditionally** and hidden with
            // opacity rather than with `if`, which is the whole reason
            // entering selection mode now reads as a change of mode instead
            // of as the grid being replaced.
            //
            // An implicit animation only animates when its own properties
            // change; a widget that was not in the tree a frame ago starts at
            // its target and shows nothing. So the badge, the ring and the
            // quick-actions button stay in the tree at zero opacity and
            // animate their way in and out. Two extra fully transparent
            // widgets per tile is a cheap price — they paint nothing and lay
            // out once.
            if (onMoreTap != null) ...[
              // Soft scrim so the quick-actions icon stays legible over
              // bright screenshots too. Fades with the icon it exists for.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 36.h,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: selectionMode ? 0 : 1,
                    duration: AppMotion.duration(context, AppMotion.instant),
                    curve: AppMotion.standard,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0),
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 2.w,
                bottom: 0,
                child: IgnorePointer(
                  ignoring: selectionMode,
                  child: AnimatedOpacity(
                    opacity: selectionMode ? 0 : 1,
                    duration: AppMotion.duration(context, AppMotion.instant),
                    curve: AppMotion.standard,
                    child: PressableScale(
                      scale: 0.85,
                      onTap: onMoreTap,
                      child: Padding(
                        padding: EdgeInsets.all(6.w),
                        child: Icon(
                          Icons.more_horiz_rounded,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            // Bottom-left, the one corner nothing else claims: the tick is
            // top-left, the heart top-right, the quick-actions button
            // bottom-right. It also sits inside the scrim already drawn for
            // that button, so it costs no extra darkening of the picture.
            if (intent case final IntentState state)
              Positioned(
                left: 6.w,
                bottom: 6.h,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: selectionMode ? 0 : 1,
                    duration: AppMotion.duration(context, AppMotion.instant),
                    curve: AppMotion.standard,
                    child: _IntentBadge(state: state),
                  ),
                ),
              ),
            if (isFavorite)
              Positioned(
                top: 6.h,
                right: 6.w,
                child: Icon(
                  Icons.favorite_rounded,
                  color: context.colors.error,
                  size: 16.sp,
                  shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
            Positioned(
              top: 6.h,
              left: 6.w,
              child: IgnorePointer(
                child: AnimatedScale(
                  // From 0.6, not from 0. A checkbox that grows out of a
                  // single point looks like it is being drawn; one that grows
                  // from something already the right shape looks like it
                  // arrived.
                  scale: selectionMode ? 1 : 0.6,
                  duration: AppMotion.duration(context, AppMotion.press),
                  curve: AppMotion.standard,
                  child: AnimatedOpacity(
                    opacity: selectionMode ? 1 : 0,
                    duration: AppMotion.duration(context, AppMotion.press),
                    curve: AppMotion.standard,
                    child: AnimatedContainer(
                      duration: AppMotion.duration(context, AppMotion.press),
                      curve: AppMotion.standard,
                      width: 22.w,
                      height: 22.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Colour is the actual signal here, so it survives
                        // reduced motion — only the movement is dropped.
                        color: isSelected
                            ? context.colors.primary
                            : Colors.black.withValues(alpha: 0.4),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: AnimatedScale(
                        scale: isSelected ? 1 : 0.4,
                        duration: AppMotion.duration(context, AppMotion.press),
                        curve: AppMotion.standard,
                        child: AnimatedOpacity(
                          opacity: isSelected ? 1 : 0,
                          duration: AppMotion.duration(
                            context,
                            AppMotion.press,
                          ),
                          curve: AppMotion.standard,
                          // Same trap as the Folders add button, and worse
                          // here because this one carries state: the filled
                          // circle is `AppPalette.primary`, which is bone in
                          // dark mode, so a white tick on it was invisible and
                          // a selected thumbnail looked unselected. The white
                          // *border* above stays white on purpose — it sits on
                          // the photo, not on the accent.
                          child: Icon(
                            Icons.check,
                            color: context.colors.onPrimary,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: isSelected ? 1 : 0,
                  duration: AppMotion.duration(context, AppMotion.press),
                  curve: AppMotion.standard,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.colors.primary,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The intent mark on a tile: the verb's glyph while it is owed, and a tick
/// once it is not.
///
/// **A glyph and not a label.** A tile is 110px across and shares its lower
/// edge with the quick-actions button; "To compare" written there would be
/// unreadable at that size in every language and unreadable at any size in
/// the longer ones. The glyph says *there is something you meant to do here*,
/// which is the whole job — what exactly, and whether to do it now, is a
/// question for the sheet one tap away.
///
/// ## Finishing is the payoff, so it has to be visible on the picture
///
/// The first version marked done by going *quiet* — the same glyph at half
/// opacity — on the theory that a finished task is not news. That was wrong
/// about which moment this feature is for. Every other number in SHOTO only
/// goes up; this is the one thing a person can complete, and a reward you
/// have to squint at is not a reward. Worse, dimmed-glyph and lit-glyph are
/// the same shape, so a grid told you nothing at a glance — the exact place a
/// glance is all you get.
///
/// So the badge **becomes a tick**, on the palette's completion colour. Same
/// object, same corner, same size: it is the mark transforming rather than one
/// mark leaving and another arriving, which is what makes it read as *this got
/// done* instead of as the tile having changed its mind. That is also the one
/// place a hue is spent here, and `IntentVisuals.tint` reserves it precisely
/// for this — waiting versus done is the only genuine state in the feature.
class _IntentBadge extends StatelessWidget {
  final IntentState state;

  const _IntentBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final bool isDone = state.isDone;

    return AnimatedContainer(
      duration: AppMotion.duration(context, AppMotion.normal),
      curve: AppMotion.standard,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        // Waiting is black rather than a surface colour: it sits on a
        // photograph, not on the app's own material, and a themed chip
        // floating on somebody's screenshot of a chat reads as part of the
        // screenshot. Done is allowed to be the app's colour, because by then
        // saying so *is* the point.
        color: isDone
            ? context.colors.success
            : Colors.black.withValues(alpha: 0.55),
        shape: BoxShape.circle,
      ),
      child: AnimatedSwitcher(
        duration: AppMotion.duration(context, AppMotion.normal),
        switchInCurve: AppMotion.standard,
        switchOutCurve: AppMotion.standard,
        transitionBuilder: (Widget child, Animation<double> animation) =>
            FadeTransition(
              opacity: animation,
              // The tick arrives a touch larger than it settles, which is the
              // whole celebration this gets. Anything more on a grid tile
              // would be a party thrown by a filing cabinet.
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
                child: child,
              ),
            ),
        child: Icon(
          isDone ? Icons.check_rounded : state.ref.icon,
          // Keyed on the state, not the glyph: switching verbs on a waiting
          // screenshot should not animate — nothing was completed — but
          // crossing into done must.
          key: ValueKey<bool>(isDone),
          size: 13.sp,
          color: Colors.white,
        ),
      ),
    );
  }
}
