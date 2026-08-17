import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/services/quick_tile.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/app_snack_bar.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/core/widgets/shoto_brand_mark.dart';

/// Explains the Quick Settings tile, then offers to add it.
///
/// **The row used to fire the system dialog on the first tap**, and that was
/// the wrong order. Android's dialog says one line — "Add Shoto to Quick
/// Settings?" — and it is the only chance the feature gets: the platform caps
/// how many times an app may ask and stops honouring the call after a few
/// refusals. So the tap that spends that chance has to land on somebody who
/// already knows what they are being offered, and "Quick Settings tile" plus a
/// hint line is not enough to know it.
///
/// It is also the hardest thing in the app to describe in words. Every part of
/// it is somewhere else — a panel that belongs to the phone, reached by a
/// gesture, holding a grid the user has never edited. A sentence about it is a
/// set of instructions; a picture of it is recognition, which is the same trade
/// the onboarding makes when it draws the share sheet instead of describing it.
Future<void> showQuickTileSheet(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _QuickTileSheet(),
  );
}

class _QuickTileSheet extends StatelessWidget {
  const _QuickTileSheet();

  Future<void> _add(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final QuickTileOutcome outcome = await QuickTile.requestAdd();
    if (!context.mounted) return;

    // Closed before the message either way: the sheet has asked its question
    // and been answered, and a panel still sitting there under a snack bar
    // saying "Added to Quick Settings" is offering something already done.
    navigator.pop();

    switch (outcome) {
      case QuickTileOutcome.added:
        showAppSnackBar(context, context.l10n.settingsQuickTileAdded);
      case QuickTileOutcome.declined:
        break;
      case QuickTileOutcome.unsupported:
        // Not an error message. The tile exists on this phone and can still be
        // dragged in by hand; all that failed is the shortcut to doing it.
        showAppSnackBar(context, context.l10n.settingsQuickTileManual);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetSurface(
      child: SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
          children: <Widget>[
            const _Grabber(),
            SizedBox(height: 20.h),
            const _PanelDrawing(),
            SizedBox(height: 22.h),
            Text(
              context.l10n.settingsQuickTileSheetTitle,
              style: context.text.headlineLarge,
            ),
            SizedBox(height: 8.h),
            Text(
              context.l10n.settingsQuickTileSheetBody,
              style: context.text.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            SizedBox(height: 20.h),

            // Three steps, in the order they happen. Numbered by position
            // rather than by a digit: the icons say what each one *is*, and a
            // list of three is short enough that nobody needs counting.
            // A double chevron rather than `swipe_down_alt`, which is a hand
            // glyph and at 18sp collapses into an unreadable blob — checked on
            // the render, where it read as a symbol rather than as a gesture.
            _Step(
              icon: Icons.keyboard_double_arrow_down_rounded,
              text: context.l10n.settingsQuickTileStepPull,
            ),
            _Step(
              icon: Icons.bolt_outlined,
              text: context.l10n.settingsQuickTileStepTap,
            ),
            _Step(
              icon: Icons.push_pin_outlined,
              text: context.l10n.settingsQuickTileStepStays,
            ),

            SizedBox(height: 22.h),
            PrimaryButton(
              label: context.l10n.settingsQuickTileAdd,
              onPressed: () => _add(context),
            ),
            SizedBox(height: 10.h),
            // The one thing the drawing cannot show: nothing is uploaded and
            // nothing is opened. This tile reaches for a screenshot the phone
            // already has.
            Text(
              context.l10n.settingsQuickTileNote,
              textAlign: TextAlign.center,
              style: context.text.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: context.colors.border,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}

/// **The phone's Quick Settings panel, drawn — with Shoto's tile in it.**
///
/// The whole point of this sheet. What a person has to do with this feature is
/// *recognise a tile in a grid they have never looked at closely*, and there is
/// no sentence that does that job. Anybody who has pulled a shade down knows
/// this shape on sight, so the drawing costs no reading at all and the only new
/// information on it — which tile is Shoto's — is the one thing carrying a mark
/// and a name.
///
/// ## Everything that is not Shoto is structure
///
/// The other tiles are outlines: no fill, no glyphs, no captions. This is a
/// lesson the onboarding's share sheet learned the expensive way — it drew its
/// neighbours as filled grey discs with a bar underneath, which is the
/// universal drawing of a *skeleton loader*, and it made the most finished
/// screen in the app read as one still waiting for its data. Filled placeholder
/// shapes pull the eye to the parts that mean nothing.
///
/// Inventing glyphs for them would be worse: the neighbours are whatever that
/// person has in their panel, and a drawn wifi-and-torch pair is somebody
/// else's phone.
///
/// ## The strip along the top
///
/// Four pixels of status bar, and it is what makes the panel read as *pulled
/// down from the top of the screen* rather than as a floating card of buttons.
/// The gesture is half of what has to be learned here and it is the half a
/// picture can carry for free.
class _PanelDrawing extends StatelessWidget {
  const _PanelDrawing();

  /// One tile. Sized so a four-column grid sits comfortably inside the sheet's
  /// margins at the design width, and shrinks with it on a narrow phone.
  static double get _tile => 62.w;

  /// Where Shoto sits in the grid.
  ///
  /// Second on the top row, not first. A tile in the corner reads as *pinned
  /// there by the drawing*; one in the middle of a row reads as one of several,
  /// which is what it will actually be — and it leaves neighbours on both sides
  /// to be recognised against.
  static const int _shotoIndex = 1;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 16.h),
      decoration: BoxDecoration(
        // The panel belongs to the phone, not to Shoto — so it is drawn one
        // step off the sheet it sits on rather than in the app's own surface
        // colour, and reads as a different plane.
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // The status bar it comes down from.
          Row(
            children: <Widget>[
              _Bar(width: 26.w),
              const Spacer(),
              _Bar(width: 14.w),
              SizedBox(width: 5.w),
              _Bar(width: 10.w),
            ],
          ),
          SizedBox(height: 14.h),
          for (int row = 0; row < 2; row++) ...<Widget>[
            if (row > 0) SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                for (int column = 0; column < 4; column++)
                  SizedBox(
                    width: _tile,
                    height: _tile * 0.62,
                    child: row == 0 && column == _shotoIndex
                        ? const _ShotoTile()
                        : const _EmptyTile(),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One of the tiles that is not Shoto's: an outline, and nothing in it.
class _EmptyTile extends StatelessWidget {
  const _EmptyTile();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: context.colors.border),
        ),
      ),
    );
  }
}

/// Shoto's tile, lit — the one thing on the panel to look for.
///
/// Carries the mark and the name, on the accent's own faint fill with the
/// accent as its edge. A Quick Settings tile that is *on* is filled and tinted
/// on every Android skin there is, so this is both the app's language and the
/// platform's saying the same thing.
class _ShotoTile extends StatelessWidget {
  const _ShotoTile();

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: colors.isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colors.primary, width: 1.4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ShotoBrandMark(size: 17.w),
          SizedBox(width: 6.w),
          Text(
            // A literal, like every other place the product names itself — it
            // is a proper noun and it is spelled the same in all seven
            // languages.
            'Shoto',
            style: context.text.caption.copyWith(
              color: colors.textPrimary,
              fontSize: 9.sp,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// A blank run of the status bar: a clock on one side, indicators on the other.
class _Bar extends StatelessWidget {
  final double width;

  const _Bar({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 4.h,
      decoration: BoxDecoration(
        color: context.colors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// One line of the explanation: a glyph, and a sentence.
class _Step extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Step({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Boxed rather than loose, so three lines of different lengths still
          // share one left edge for their text — a row of bare glyphs at
          // different optical widths does not.
          SizedBox(
            width: 26.w,
            child: Icon(icon, size: 18.sp, color: context.colors.primary),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: context.text.bodyMedium.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
