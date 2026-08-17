import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/localization/l10n.dart';
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

  /// **The way into this screenshot's own actions**, and the reason there is
  /// no "⋯" disc on the picture any more.
  ///
  /// There was one, bottom-right, 17dp across. `PressableScale` hit-tests the
  /// box it draws and nothing more, so 17dp was the entire target — against a
  /// 48dp Material minimum, a 44pt Apple one and the 24dp floor in WCAG 2.5.8.
  /// It failed the weakest of the three, and a miss did not merely do nothing:
  /// it landed on the tile underneath and opened the full-screen viewer, so
  /// the cost of a slightly-off tap was a page transition and a trip back.
  ///
  /// Size was not the only argument. The heart and the intent badge each say
  /// something *about* the screenshot they sit on; a "⋯" says only that a menu
  /// exists, and it said it on every tile at once — two dozen identical doors
  /// painted across the one screen whose whole job is showing the pictures.
  /// Chrome that carries no information cannot justify standing on the
  /// content. Every verb behind it was already reachable twice over: through
  /// the viewer one tap away, and through selection mode.
  ///
  /// So the gesture carries it, which is what a photo grid does everywhere —
  /// and the affordance the gesture lacks moved to the header, where a Select
  /// button is a 42dp target on the app's own surface rather than a 17dp one
  /// on somebody's photograph.
  final VoidCallback onLongPress;

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
    this.intent,
    this.heroTag,
  });

  /// What this tile is, for somebody who cannot see it.
  ///
  /// **A date, because a screenshot has nothing else to be called.** Every
  /// other identifying fact about it is inside the picture, and the app knows
  /// none of it here — the recognised text belongs to the viewer, one screen
  /// down. Without this a library was a grid of identical unnamed buttons, and
  /// swiping through it announced the same nothing forty times.
  ///
  /// The date is formatted by [MaterialLocalizations] rather than by the app's
  /// own strings, so it follows the reader's locale conventions without
  /// needing a date format written seven times.
  ///
  /// **Full, not medium**, which is verbose on screen and correct out loud:
  /// `formatMediumDate` returns "Sat, Mar 14" with no year, and a library
  /// holds screenshots from several. Two tiles a year apart would have been
  /// announced identically, which is the one thing this label exists to stop.
  String _describe(BuildContext context) {
    final String date = MaterialLocalizations.of(
      context,
    ).formatFullDate(asset.createDateTime);

    return isFavorite
        ? context.l10n.a11yScreenshotFavorite(date)
        : context.l10n.a11yScreenshot(date);
  }

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
      semanticLabel: _describe(context),
      // Only while choosing. Outside selection mode a tile is not a member of
      // a set, and reporting "not selected" on every picture in a library
      // invents a state for a screen reader to track.
      selected: selectionMode ? isSelected : null,
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
            // Only the picture flies. The favourite heart and the selection
            // ring belong to *this* grid and have no counterpart on the other
            // side, so carrying them along would mean animating widgets into
            // nothing.
            _withHero(AssetThumbnailImage(asset: asset)),
            // Everything below is built **unconditionally** and hidden with
            // opacity rather than with `if`, which is the whole reason
            // entering selection mode now reads as a change of mode instead
            // of as the grid being replaced.
            //
            // An implicit animation only animates when its own properties
            // change; a widget that was not in the tree a frame ago starts at
            // its target and shows nothing. So the badge and the ring stay in
            // the tree at zero opacity and animate their way in and out. One
            // extra fully transparent widget per tile is a cheap price — it
            // paints nothing and lays out once.
            // **No scrim, and nothing on this tile is a tap target.**
            //
            // There was a 55%-black gradient across the bottom 36px of every
            // tile, drawn so that one bare white glyph would stay legible. It
            // paid for that glyph by permanently darkening the bottom third of
            // every picture in the grid — including the thousands of tiles
            // that have no mark on them at all — on the one screen whose whole
            // job is showing the pictures. The glyph was the "⋯" button, and
            // it is gone too; see [onLongPress].
            //
            // What is left are marks, in the strict sense: every one of them
            // is `IgnorePointer`, every one of them reports something about
            // the screenshot underneath, and the whole tile is one target. A
            // photograph is a bad surface for a control and a fine surface for
            // a label.
            //
            // **Bottom-left**, which is where the intent badge has always been
            // and where it belongs — it was moved to the top-left for one
            // build, on the theory that sharing the selection tick's corner
            // would declutter the bottom edge. Two things were wrong with
            // that. The bottom edge stopped being crowded the moment the scrim
            // came off and the marks shrank, so there was nothing left to
            // declutter; and the top-left of a screenshot is almost never
            // empty — it is where the clock, the back arrow and the title of
            // whatever was captured all live, so a mark there lands on content
            // every time.
            //
            // Each mark has a corner to itself, which is what lets a glance
            // down a column tell them apart without reading them.
            if (intent case final IntentState state)
              Positioned(
                left: 5.w,
                bottom: 5.h,
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
                top: 5.h,
                right: 5.w,
                // The same disc as every other mark. It was a bare red heart
                // with a blur shadow under it — a second way of solving the
                // legibility problem, which is how a grid ends up with three
                // visual languages on one tile.
                child: _TileMark(
                  icon: Icons.favorite_rounded,
                  iconColor: context.colors.error,
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

/// **The one mark this grid draws**, in the one size and the one shape it
/// draws them.
///
/// A tile had four different overlay treatments on it at once: a translucent
/// black disc for a waiting intent, a fully saturated green disc for a
/// finished one, a bare white glyph for the quick-actions button and a bare
/// red heart with a drop shadow for a favourite. Four marks, four answers to
/// the same question — *how does a small symbol stay legible on an arbitrary
/// photograph* — and the grid read as cluttered because it genuinely was.
///
/// Three are left, the "⋯" having turned out to be answering the wrong
/// question entirely — see [ScreenshotThumbnail.onLongPress]. The two that
/// remain both go through here: the favourite draws one of these directly, and
/// [_IntentBadge] borrows its measurements so the pair cannot drift apart.
///
/// One answer, used everywhere: a small dark disc that supplies its own
/// contrast. That is what let the bottom scrim go, because the scrim existed
/// solely to prop up the one mark that had no shape.
///
/// **Size is the whole discipline here.** These sit on top of the only thing
/// this screen exists to show, so the disc is 20px on a tile that is 110px
/// across at the densest grid — findable, and never the subject. The finished
/// mark was close to a third of a tile at one point; the file's own history
/// records shrinking it twice, and it was still the loudest object on the
/// screen because it was solving legibility with area instead of with
/// contrast.
class _TileMark extends StatelessWidget {
  final IconData icon;

  final Color iconColor;

  const _TileMark({required this.icon, this.iconColor = Colors.white});

  /// The disc's fill: a dark scrim, deliberately **not** a themed surface.
  /// This sits on somebody's photograph rather than on the app's own
  /// material, and a themed chip floating on a screenshot of a chat reads as
  /// part of that screenshot.
  ///
  /// [_IntentBadge] is the one mark that departs from it, and only to swap in
  /// the completion hue — it animates that change, so it builds its own
  /// container rather than taking a colour through here.
  static Color get fill => Colors.black.withValues(alpha: 0.5);

  /// One value, so every mark on the tile is the same object at a glance.
  ///
  /// 17 rather than 20, measured on the device rather than guessed: at 20 the
  /// disc came out around 18% of a tile's width, which is close to what the
  /// old green puck occupied and still read as a sticker applied to the
  /// photograph. 17 lands near 15% — small enough to be chrome, large enough
  /// that an 10sp glyph inside it is still unambiguous at arm's length.
  static const double diameter = 17;
  static const double glyph = 10;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter.w,
      height: diameter.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: Icon(icon, size: glyph.sp, color: iconColor),
    );
  }
}

/// The intent mark on a tile: the verb's glyph while it is owed, and a tick
/// once it is not.
///
/// **A glyph and not a label.** A tile is 110px across; "To compare" written
/// there would be unreadable at that size in every language and unreadable at
/// any size in the longer ones. The glyph says *there is something you meant
/// to do here*, which is the whole job — what exactly, and whether to do it
/// now, is a question for the sheet one long-press away.
///
/// ## Finishing is the payoff, so it has to be visible on the picture
///
/// The first version marked done by going *quiet* — the same glyph at half
/// opacity — on the theory that a finished task is not news. That was wrong
/// about which moment this feature is for. Every other number in Shoto only
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

    // Built by hand rather than as a [_TileMark] because the fill animates,
    // but off that widget's own measurements — the two marks on a tile have to
    // be the same object at a glance, and two copies of "17" is how that stops
    // being true.
    //
    // **Done keeps its hue and loses its shout.** The doc above is right that
    // finishing has to be visible on the picture, and it still is: green is
    // the only colour anywhere in this grid, so a completed tile is findable
    // from across the screen. What changed is that it is now the same 20px
    // disc as everything else instead of a saturated puck twice that size —
    // the mark was carrying its emphasis in *area*, which is the one currency
    // a photo grid cannot afford to spend.
    return AnimatedContainer(
      duration: AppMotion.duration(context, AppMotion.normal),
      curve: AppMotion.standard,
      width: _TileMark.diameter.w,
      height: _TileMark.diameter.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDone ? context.colors.success : _TileMark.fill,
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
          size: _TileMark.glyph.sp,
          color: Colors.white,
        ),
      ),
    );
  }
}
