import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';

/// A titled section of Settings: a heading, and its rows on the page itself.
///
/// **Three shapes, in order, and the middle one is why this is here.**
///
/// It began as a flat run of individually-bordered tiles with equal gaps
/// between all of them, which read as a list of unrelated buttons: with every
/// row drawing its own outline, "Haptic feedback" looked exactly as separate
/// from "Ask before deleting" as it did from "Sign out". The fix was to give
/// each group one card and put hairlines between its rows — grouping said with
/// a container, which is what a settings screen looked like on both platforms
/// at the time.
///
/// **That container is now the problem it was hired to solve.** Six filled,
/// bordered slabs stacked down a dark page make Settings the most boxed screen
/// in an app that has spent this year removing boxes everywhere else — the
/// folder grid, the sheets, and Home's tool list, which had four icon plates
/// and three dividers taken out of it for exactly this reason. A page of
/// containers reads as *chrome*, and chrome is the thing that dates fastest.
///
/// So the grouping is now done by the two things that were always doing the
/// real work anyway: **a heading, and the space above it.** 26dp of air over a
/// small caps label separates two groups more clearly than a border ever did,
/// because it is the same signal a book uses. The hairlines stay *inside* a
/// group, where they say "these rows are one list" — which is a different
/// claim from "this list is an object", and the only one worth making.
///
/// Nothing was lost in the trade. The rows are still aligned, still grouped,
/// still tappable; what went is six rectangles, six borders and the sense that
/// the settings are stored in filing cabinets.
class SettingsGroup extends StatelessWidget {
  final String title;

  /// An optional line under the heading, for a group whose purpose is not
  /// obvious from its rows alone.
  final String? caption;
  final List<Widget> children;

  const SettingsGroup({
    super.key,
    required this.title,
    required this.children,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // The space *above* a heading belongs to the heading; the space below it
      // belongs to nothing, and every pixel of it weakens the join between a
      // title and the card it titles. 26 above and 10 below was already the
      // right shape — 8 below tightens it to the same ratio the rest of the
      // app uses, which is what stops each heading floating alone in the
      // middle of a gap.
      padding: EdgeInsets.only(top: 26.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: context.text.overline),
                if (caption != null) ...[
                  SizedBox(height: 4.h),
                  Text(caption!, style: context.text.caption),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) const SettingsDivider(),
                children[i],
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// The hairline between two rows, inset so it starts where the text does —
/// a full-width rule cuts the icons off from their own labels.
///
/// **34, down from 50.** The rows used to carry 15dp of their own horizontal
/// padding because they lived inside a card that needed an inner margin; with
/// the card gone they sit on the page gutter instead, so the text starts 16dp
/// earlier and the rule has to follow it. A hairline that stops short of where
/// the labels begin is worse than no hairline: it draws attention to a column
/// that is not there.
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 34.w),
      child: Divider(height: 1, thickness: 1, color: context.colors.border),
    );
  }
}
