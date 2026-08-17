import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// `show DateFormat`, not a bare import: `package:intl` exports its own
// `TextDirection`, which shadows the one from `dart:ui` that the plate painter
// takes — the whole file stopped compiling on `TextDirection.rtl` the moment
// this line was added.
import 'package:intl/intl.dart' show DateFormat;
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_colors.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_icons.dart';

/// The corner radius of both shapes on the card.
///
/// A plain double rather than `AppRadius.md`, which is `18.r` — a `ScreenUtil`
/// getter, fine in a widget and unavailable inside a [CustomPainter], which
/// has no `BuildContext` to have resolved it against. Named once here so the
/// painter and the pocket beside it cannot drift apart, and smaller than the
/// scale's card step because these two shapes are stacked: at 18 the pocket's
/// corners eat visibly into the plate behind it.
const double _cardRadius = 14;

/// A folder, drawn as a folder.
///
/// **This replaced a screenshot cover, and the reasoning that put the cover
/// there is worth writing down before the reasoning that took it away.**
///
/// The card used to be the newest screenshot filed inside it, on the argument
/// that a folder of receipts and a folder of recipes are told apart by their
/// contents and by nothing else — the same reason a gallery app shows album
/// covers rather than folder glyphs. That is true of a gallery. It turned out
/// not to be true here, for two reasons that only show up on a real phone:
///
/// 1. **Most folders are empty most of the time.** A folder is made *before*
///    anything goes in it, and the emptiest folder — the one just created — is
///    the one being looked for. Every empty folder fell back to the same grey
///    box with the same glyph, so the grid was a row of identical placeholders
///    exactly when it needed to be legible.
/// 2. **A screenshot is a poor thumbnail of itself.** Screenshots are dense,
///    tall, mostly white text on mostly white chrome. Twelve of them at 98dp
///    wide is twelve grey rectangles; the thing that identifies the folder —
///    that it is *the trips one* — is not visible at that size in a way a
///    picture of a boarding pass can carry.
///
/// So the card is an object rather than a window: a card-stock plate in the
/// folder's own colour with a pocket across the front of it, the name written
/// on the pocket, and the folder's glyph watermarked on the plate behind.
/// Shape, colour and glyph are three independent things to recognise it by,
/// and all three survive being 98dp wide.
///
/// ---
///
/// **The colour is allowed to be this loud, and only here.**
///
/// `AppPalette` flattened twenty-two gradients and drained every neutral to
/// exactly R==G==B, on the rule that the interface has no colour and the
/// screenshots do. This does not break that rule, it is the rule's one
/// documented exception — `folder_colors.dart` has said since it was written
/// that these hues "are not the interface speaking, they are the user's own
/// filing marks". The gradient lives on the pocket, which is the piece of this
/// screen the user coloured themselves. Nothing else on the page has one.
///
/// **There is no shadow**, because the app has none: `AppPalette` deleted the
/// only shadow token it ever had and explains at length why a soft dark shape
/// on a near-black canvas reads as a smudge rather than as depth. The
/// separation here is done with value instead — the plate is the tag colour at
/// 78% lightness, the pocket sweeps ten points either side of it, and the two
/// read as stacked because they are two clearly different lightnesses of one
/// hue.
class FolderCard extends StatelessWidget {
  final FolderEntity folder;

  final VoidCallback onTap;

  /// Opens rename/delete. Wired to both the always-visible "⋯" button and a
  /// long-press: the button is what makes the actions discoverable at all
  /// (a long-press has no visual affordance, so nobody finds it), the
  /// long-press stays as a shortcut for people who already know.
  ///
  /// Null on the editor sheet's preview, which draws the same card for a
  /// folder that does not exist yet — a "⋯" there would offer to rename and
  /// delete the thing currently being named.
  final VoidCallback? onMoreTap;

  /// What the pocket prints under the name.
  ///
  /// **Passed in rather than read from [FolderAppearanceController] here**,
  /// and the first attempt did read it here — which is how this comment came
  /// to exist. A leaf widget that reaches into the service locator cannot be
  /// built without the app's wiring around it: adding that one line broke the
  /// editor sheet's preview, both of its golden tests and the detail page's,
  /// none of which have any interest in a global preference. The grid is the
  /// one place that *has* the user's choice, so the grid is the one place that
  /// reads it.
  ///
  /// The defaults are what the card drew before either switch existed, so
  /// every other call site — the editor preview above all, which is a folder
  /// that does not exist yet and has no date worth printing — keeps working
  /// without knowing anything changed.
  final bool showCount;

  final bool showCreated;

  const FolderCard({
    super.key,
    required this.folder,
    required this.onTap,
    this.onMoreTap,
    this.showCount = true,
    this.showCreated = false,
  });

  /// How much of the tile's height the card-stock plate takes.
  ///
  /// The rest is where the pocket hangs below it. The pocket is *not* sized
  /// from this — it takes whatever height its two lines of text need and grows
  /// upward over the plate — which is what keeps the card whole at a large
  /// system text scale instead of striping the bottom of every tile in the
  /// grid.
  static const double _plateFraction = 0.72;

  /// The plate is inset from the leading edge and the pocket from the trailing
  /// one, so neither is square with the other. That offset is most of what
  /// makes the two shapes read as *in front of* rather than as one panel split
  /// in half.
  static const double _plateInset = 0.10;

  /// **0.90, and it is the count that sets it.** At 0.80 the pocket had about
  /// 62dp of usable width on a three-column grid, which ellipsizes
  /// "24 screenshots" — so every folder on the page reported "24 screens…" and
  /// the one number on the card was the thing being cut off. A name is fine to
  /// truncate; it is the user's own word and they recognise the first half of
  /// it. A truncated count is just noise.
  ///
  /// This is the widest the pocket can be and still leave the plate showing
  /// past its trailing edge, which is the other half of what makes the two
  /// shapes read as stacked rather than as one panel.
  static const double _pocketWidth = 0.90;

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
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;
          final double plateHeight = height * _plateFraction;

          return Stack(
            children: <Widget>[
              PositionedDirectional(
                top: 0,
                start: width * _plateInset,
                end: 0,
                height: plateHeight,
                child: _Plate(folder: folder, color: color),
              ),
              // In the notch the tab leaves free, so it sits on the page's own
              // background and is legible whatever colour the folder is. The
              // old card put this under the cover for the same reason: over a
              // coloured surface the glyph needs a scrim, and a scrim in the
              // corner of every tile is a smudge on the whole grid.
              if (onMoreTap != null)
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  height: plateHeight * _Plate.tabFraction,
                  child: PressableScale(
                    scale: 0.85,
                    onTap: onMoreTap,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: 10.w,
                        end: 2.w,
                      ),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        color: context.colors.textSecondary,
                        size: 16.sp,
                      ),
                    ),
                  ),
                ),
              PositionedDirectional(
                bottom: 0,
                start: 0,
                end: width * (1 - _pocketWidth),
                child: _Pocket(
                  folder: folder,
                  color: color,
                  showCount: showCount,
                  showCreated: showCreated,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The card stock: a tab, and a body under it.
///
/// Two rounded rectangles drawn with one [Paint] rather than a single traced
/// path. They overlap by the corner radius, so the seam between them is inside
/// solid colour and never visible — and it means the shape is described by the
/// two rectangles anybody reading this can picture, instead of by eleven path
/// commands nobody can.
class _Plate extends StatelessWidget {
  final FolderEntity folder;
  final Color color;

  const _Plate({required this.folder, required this.color});

  /// How much of the plate's height the tab stands above the body.
  ///
  /// Also, and not by accident, the height of the notch beside it — which is
  /// where the "⋯" button lives. At 24% that notch is about 22dp tall on a
  /// three-column grid, which is enough for a 16sp glyph with room around it.
  static const double tabFraction = 0.24;

  /// How much of the plate's width the tab runs along.
  static const double _tabWidth = 0.52;

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;

    return CustomPaint(
      painter: _PlatePainter(color: folderPlateColor(folder.color), rtl: rtl),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double bodyHeight = constraints.maxHeight * (1 - tabFraction);

          return Padding(
            // The watermark belongs to the body, not to the tab above it.
            padding: EdgeInsets.only(top: constraints.maxHeight * tabFraction),
            child: Align(
              // Above centre, because the pocket covers the bottom third of
              // the body and a centred glyph would be half behind it.
              alignment: const Alignment(0, -0.35),
              // **A locked folder says so before it says anything else.**
              //
              // The rule survives the redesign that removed the cover it was
              // written for: the padlock is the whole reason the flag exists,
              // and a private folder wearing its own cheerful glyph looks
              // exactly like an unlocked one until you try to open it.
              //
              // Sized against the plate rather than against the icon scale
              // used elsewhere, for the reason the old placeholder gave: at a
              // row's 20sp a glyph is adrift in the middle of a tile. It is
              // standing in for the picture the card no longer has.
              //
              // Watermarked rather than drawn: the glyph is *behind* the
              // pocket in the same sense a letterhead is behind the writing.
              // At full strength it competed with the name for the eye and the
              // card had two things shouting on it.
              child: folder.isPrivate
                  ? Icon(
                      Icons.lock_rounded,
                      size: bodyHeight * 0.44,
                      color: onFolderColor(
                        folder.color,
                      ).withValues(alpha: 0.32),
                    )
                  : FolderGlyph(
                      iconKey: folder.iconKey,
                      size: bodyHeight * 0.44,
                      color: onFolderColor(
                        folder.color,
                      ).withValues(alpha: 0.32),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _PlatePainter extends CustomPainter {
  final Color color;

  /// Which side the tab is on. Mirrored in Arabic and Urdu for the same reason
  /// `ClippedCorner` mirrors its cut: the tab is the corner you see first, and
  /// in an RTL layout that is the other one.
  final bool rtl;

  const _PlatePainter({required this.color, required this.rtl});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final double radius = _cardRadius;
    final double tabHeight = size.height * _Plate.tabFraction;
    final double tabWidth = size.width * _Plate._tabWidth;

    final RRect body = RRect.fromRectAndCorners(
      Rect.fromLTRB(0, tabHeight, size.width, size.height),
      topLeft: Radius.circular(rtl ? radius : 0),
      topRight: Radius.circular(rtl ? 0 : radius),
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );

    // Runs `radius` past the top of the body, so the two shapes overlap by
    // exactly the amount needed for the join to disappear.
    final RRect tab = RRect.fromRectAndCorners(
      rtl
          ? Rect.fromLTRB(
              size.width - tabWidth,
              0,
              size.width,
              tabHeight + radius,
            )
          : Rect.fromLTRB(0, 0, tabWidth, tabHeight + radius),
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    );

    canvas
      ..drawRRect(tab, paint)
      ..drawRRect(body, paint);
  }

  @override
  bool shouldRepaint(_PlatePainter old) => old.color != color || old.rtl != rtl;
}

/// The pocket across the front, and the only place a folder's name is written.
class _Pocket extends StatelessWidget {
  final FolderEntity folder;
  final Color color;
  final bool showCount;
  final bool showCreated;

  const _Pocket({
    required this.folder,
    required this.color,
    required this.showCount,
    required this.showCreated,
  });

  /// One style for both optional lines.
  ///
  /// Not a lighter *colour*: on eight different hues there is no single grey
  /// that stays subordinate without going illegible on one of them.
  /// Transparency of the foreground already chosen for this swatch keeps the
  /// relationship right on all eight.
  TextStyle _subtitle(BuildContext context, Color foreground) =>
      context.text.caption.copyWith(
        color: foreground.withValues(alpha: 0.78),
        fontSize: 10.5.sp,
        height: 1.2,
      );

  /// Falls back to the unlocalised format rather than throwing.
  ///
  /// The same guard the subscription card documents: `DateFormat` raises for a
  /// locale whose data has not been loaded, and a folder grid is not a screen
  /// to lose over a date.
  String _created(BuildContext context) {
    final DateTime date = folder.createdAt;
    try {
      return DateFormat.yMMMd(
        Localizations.localeOf(context).toLanguageTag(),
      ).format(date);
    } on Exception {
      return DateFormat.yMMMd().format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color foreground = onFolderColor(folder.color);

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(8.w, 12.h, 6.w, 11.h),
      decoration: BoxDecoration(
        gradient: folderPocketGradient(folder.color),
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            folder.name,
            style: context.text.bodySmall.asSemiBold.copyWith(
              color: foreground,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // **Both lines are optional now, and the name is not.**
          //
          // A folder with neither switched on is a coloured plate and a name,
          // which is a legitimate thing to want — the grid is mostly scanned
          // by colour and glyph — and it is the reason these are two switches
          // rather than one "details" toggle: the count answers "is there
          // anything in here" and the date answers "how long has this been
          // sitting", and almost nobody wants both.
          if (showCount) ...<Widget>[
            SizedBox(height: 2.h),
            Text(
              context.l10n.countScreenshots(folder.screenshotCount),
              style: _subtitle(context, foreground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (showCreated) ...<Widget>[
            SizedBox(height: 2.h),
            Text(
              // Localised through the same `DateFormat.yMMMd` the subscription
              // card uses, and short-form rather than long: this sits in a
              // pocket about a third of a phone wide, where "12 September
              // 2026" cannot fit in any language.
              _created(context),
              style: _subtitle(context, foreground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
