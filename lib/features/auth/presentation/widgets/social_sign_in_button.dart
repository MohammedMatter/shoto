import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';

/// Which identity provider a button belongs to — and therefore which mark it
/// draws.
///
/// An enum rather than an `icon` passed in from the page, because a sign-in
/// button is not a styled button: what a provider's mark is, and how large it
/// has to be to sit level with the other one, is not a decision a layout should
/// be able to take.
enum SignInBrand { google, apple }

/// One provider's sign-in button.
///
/// **The two used to be identical** — same surface, same border, same
/// everything but the glyph — under a note explaining that providers are not a
/// hierarchy and that Apple's guidelines forbid demoting theirs. Both halves of
/// that are still true and neither of them asked for the buttons to be *the
/// same drawing twice*. Two grey cards stacked on the last screen of a redesign
/// is what a layout looks like when nobody decided anything.
///
/// ## The one decision: [filled]
///
/// A button here is either a **card** — a surface with a hairline, like every
/// other card in the app — or a **slab**, a solid block of
/// [AppPalette.textPrimary]: black on light, white on dark. The slab is the
/// strongest shape these tokens can draw, and one considered piece of contrast
/// does more for how finished a page looks than any amount of tinting.
///
/// **The slab goes to the last provider offered**, which resolves the two
/// constraints that pull in opposite directions here:
///
/// * On iOS both are shown, and Apple's guidelines say theirs may not be less
///   prominent than any other option. It is last, so it is the slab — which is
///   also exactly the button Apple publishes: black on light, white on dark.
/// * On Android, Apple is not offered at all, and the screen would otherwise be
///   a single outlined card sitting alone above the legal line, with nothing on
///   the page committing to anything. Google is last there, so Google takes it —
///   still one of Google's own sanctioned button themes, and the only shape on
///   that screen that looks like the thing you are meant to press.
///
/// It stays a parameter rather than being derived from [brand] because the
/// answer genuinely depends on what *else* is on the screen, which this widget
/// cannot see.
///
/// **The label is centred between two equal gutters rather than sitting beside
/// the glyph.** A centred `Row` of icon-then-label re-centres itself every time
/// the string changes length, so the German button's contents sit somewhere
/// else from the English one's and a column of two never lines up. Pinning the
/// glyph to a fixed leading slot and mirroring that slot on the trailing side
/// puts the label in the same place in every language, and puts the two glyphs
/// on one vertical line.
class SocialSignInButton extends StatelessWidget {
  final SignInBrand brand;
  final String label;

  /// Slab rather than card. See the note above — this is the last provider on
  /// the screen, not a taste setting.
  final bool filled;

  final bool isLoading;
  final VoidCallback? onPressed;

  const SocialSignInButton({
    super.key,
    required this.brand,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.isLoading = false,
  });

  /// The width reserved at each end. The glyph sits in the centre of the
  /// leading one; the trailing one holds nothing and exists only so the label
  /// is centred in the button rather than in what is left of it.
  static double get _gutter => 52.w;

  @override
  Widget build(BuildContext context) {
    // [AppPalette.onPrimary] is the exact inverse of [AppPalette.textPrimary]
    // in both modes — paper on ink, ink on paper — so the slab needs no
    // foreground token of its own.
    final Color foreground = filled
        ? context.colors.onPrimary
        : context.colors.textPrimary;

    // This is the very first thing anyone touches in Shoto, and it was once the
    // one control with no press response at all — an ink ripple on a plain
    // surface card, starting only after the finger came off. First impressions
    // of "does this app feel solid" are decided here.
    return PressableScale(
      scale: 0.985,
      onTap: isLoading ? null : onPressed,
      child: SizedBox(
        width: double.infinity,
        height: 54.h,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: filled ? context.colors.textPrimary : context.colors.surface,
            borderRadius: BorderRadius.circular(16.r),
            // A slab needs no edge: the fill is already the furthest value from
            // the canvas there is, and a border on it would be a line drawn
            // around black.
            border: filled
                ? null
                : Border.all(color: context.colors.border, width: 1),
          ),
          // Label to spinner is a state change on a control the user is waiting
          // on, so it gets a bridge rather than a cut. Swapping them instantly
          // makes the button look like it was replaced by a different button.
          child: AnimatedSwitcher(
            duration: AppMotion.duration(context, AppMotion.press),
            switchInCurve: AppMotion.standard,
            switchOutCurve: AppMotion.standard,
            transitionBuilder: (Widget child, Animation<double> animation) =>
                FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.85,
                      end: 1,
                    ).animate(animation),
                    child: child,
                  ),
                ),
            child: isLoading
                ? _Spinner(key: const ValueKey<bool>(true), color: foreground)
                : _Content(
                    key: const ValueKey<bool>(false),
                    label: label,
                    foreground: foreground,
                    glyph: _glyph(foreground),
                  ),
          ),
        ),
      ),
    );
  }

  /// The provider's own mark, at the size each needs to look like the same
  /// weight of thing.
  Widget _glyph(Color color) {
    switch (brand) {
      case SignInBrand.google:
        return FaIcon(FontAwesomeIcons.google, size: 18.sp, color: color);

      case SignInBrand.apple:
        // Two points larger than the Google mark, and that is optics rather
        // than inconsistency: Apple's silhouette has a bite and a leaf cut out
        // of it, so at equal nominal size it carries visibly less ink than a
        // solid glyph sitting under it.
        return Icon(Icons.apple, size: 20.sp, color: color);
    }
  }
}

class _Content extends StatelessWidget {
  final String label;
  final Color foreground;
  final Widget glyph;

  const _Content({
    super.key,
    required this.label,
    required this.foreground,
    required this.glyph,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: SocialSignInButton._gutter,
          child: Center(child: glyph),
        ),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            // A button narrower than its own label is a crash stripe, not a
            // truncation — the same lesson `PrimaryButton` records after
            // German set "Save to gallery" 38px wider than the control.
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.text.button.copyWith(color: foreground),
          ),
        ),
        SizedBox(width: SocialSignInButton._gutter),
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  final Color color;

  const _Spinner({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 21.w,
        height: 21.w,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: color),
      ),
    );
  }
}
