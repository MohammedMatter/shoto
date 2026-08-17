import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';

/// The word PRO, drawn one way.
///
/// It is now on four surfaces — the Home wordmark, the profile card, the
/// subscription card and the locked settings rows — and before this each of
/// them built its own pill with its own padding, radius and weight. Four
/// versions of a two-letter mark is how a brand stops reading as one.
class ProBadge extends StatelessWidget {
  /// True when the badge sits **on** the accent rather than being made of it —
  /// the upgrade card's slab. The accent is achromatic and inverts per mode,
  /// so an accent-filled pill on an accent-filled card is invisible; on that
  /// surface the pill has to be a tint of what reads on the accent instead.
  final bool onAccent;

  const ProBadge({super.key, this.onAccent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        // **A wash of the accent, not a slab of it.**
        //
        // It was solid `primary`, which on Home puts a saturated navy block
        // directly beside the user's own name at headline size — the single
        // heaviest object on the page, spent on two letters that state
        // something the user already knows about themselves. Beside a name it
        // read as a button, and the reflex is to try tapping it.
        //
        // A tint keeps it legible as a mark and demotes it to what it is: a
        // label. The letters stay full-strength accent, so the badge is still
        // unmistakably the paid colour — the area is what changed, which is the
        // same correction `folder_card.dart` made when a whole tinted cover
        // came down to a glyph and an edge.
        color: onAccent
            ? context.colors.onMarker.withValues(alpha: 0.22)
            : context.colors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        context.l10n.commonPro,
        style: context.text.overline.asSemiBold.copyWith(
          color: onAccent ? context.colors.onMarker : context.colors.primary,
        ),
      ),
    );
  }
}

/// A [ProBadge] that appears **only for people who already pay**.
///
/// For the two places that celebrate the subscription — the wordmark on Home,
/// the profile card in Settings — where the badge is a statement about the
/// account rather than about the row it sits next to.
class ProBadgeIfSubscribed extends StatelessWidget {
  const ProBadgeIfSubscribed({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<ProStatus>(),
      builder: (context, _) =>
          sl<ProStatus>().isPro ? const ProBadge() : const SizedBox.shrink(),
    );
  }
}

// There is deliberately no `ProLockBadge` here — no widget that hides itself
// once you have paid.
//
// It existed for one commit and was the wrong shape. A settings row like Find
// duplicates needs the badge taken down once the feature is paid
// for (it is a price tag, not a crown, and leaving it up labelled a
// subscriber's own purchases as locked) — but a *row* deciding that for itself
// means every row reaching into the service locator, which is how a plain
// presentational tile became impossible to render in a widget test.
//
// The page owns the decision instead and passes a bool down. See
// `SettingsNavTile.showProBadge`.
