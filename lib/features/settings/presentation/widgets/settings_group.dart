import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';

/// A titled section of Settings whose rows share one card.
///
/// The page used to be a flat run of individually-bordered tiles with equal
/// gaps between all of them. Nothing was wrong with any single tile, but
/// together they read as a list of unrelated buttons: with every row drawing
/// its own outline, "Haptic feedback" looked exactly as separate from "Ask
/// before deleting" as it did from "Sign out".
///
/// One card per group and hairlines between its rows says what the headings
/// were already claiming — these belong together, that one does not. It is
/// also simply what a settings screen looks like on both platforms, and
/// looking like the thing you are is most of feeling finished.
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
            padding: EdgeInsetsDirectional.only(start: 4.w, bottom: 8.h),
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
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: context.colors.border),
            ),
            // Rows are square-cornered; the card clips them, so the first and
            // last pick up its radius without either needing to know where in
            // the group it sits.
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0) const SettingsDivider(),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The hairline between two rows, inset so it starts where the text does —
/// a full-width rule cuts the icons off from their own labels.
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 50.w),
      child: Divider(height: 1, thickness: 1, color: context.colors.border),
    );
  }
}
