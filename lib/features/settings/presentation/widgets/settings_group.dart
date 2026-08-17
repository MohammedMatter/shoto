import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/features/settings/presentation/widgets/settings_tiles.dart';

/// A titled section of Settings: a heading, and its rows on one surface.
///
/// **The grouping is the whole design of this page now**, because the rows
/// themselves have been stripped back to a glyph and a label — see
/// [SettingsGlyph] for the coloured version that was tried and taken out. With
/// nothing marking a row, everything that tells you where you are has to come
/// from the two things above it: the heading, and the space over the heading.
///
/// So both were made to carry it properly:
///
/// * **32dp above a heading, 10 below.** The space above a heading belongs to
///   the heading; the space below belongs to nothing, and every pixel of it
///   weakens the join between a title and the card it titles. The ratio was
///   26/8 and it was too tight to separate anything at a glance — this is the
///   same ratio, further apart, which is the cheapest way to make a long page
///   read as six things instead of seventeen.
/// * **Sentence case, not small caps.** `app_text_styles.dart` is explicit
///   about this: "All-caps everywhere is a tell: it is what a layout reaches
///   for when the hierarchy is not doing the work" — and it is right. `overline`
///   set the headings at 10.5sp with letter-spacing, which is the smallest and
///   hardest-to-read text on a screen whose *only* signposts they are.
///   [AppTypography.sectionLabel] is 12sp, sentence case, and is what Home
///   already uses for exactly this job.
///
/// ## Why the card came back
///
/// It was here, then it was taken out, and now it is back — so the reasoning is
/// worth stating once rather than being re-litigated. The removal was recorded
/// as: six filled, **bordered** slabs stacked down a dark page read as chrome,
/// and grouping is better said with a heading and the space above it.
///
/// Half of that held. The heading and its air *are* doing the grouping, and
/// that half is now doing more of it than ever. What the removal also took away
/// was any edge at all: the rows stopped being on anything, and on the light
/// canvas the page became a sheet of `#F4F4F4` with text on it and one white
/// subscription card floating at the top. It did not read as restraint. It read
/// as unfinished.
///
/// **The border was the chrome, not the surface.** `app_colors.dart` sets the
/// light canvas a full step below white specifically so "a white card is raised
/// by eleven values instead of five and stops needing its border to be visible
/// at all" — a borderless card is the shape that decision was taken *for*, and
/// it had never been tried here. It is also what the Appearance page has been
/// doing all along, one tap from this one, so the two screens finally agree.
class SettingsGroup extends StatelessWidget {
  final String title;

  /// An optional line under the heading, for a group whose purpose is not
  /// obvious from its rows alone.
  final String? caption;

  /// **One child per group, not one per row.**
  ///
  /// A hairline is drawn between every entry in this list, which makes it a
  /// list of *rows* rather than a slot for arbitrary content: a group that
  /// passed a picker, a spacer and a caption separately would get rules
  /// through the middle of its own paragraph. Anything that is not a row goes
  /// in as a single `Column`.
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
      padding: EdgeInsets.only(top: 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            // Indented to the card's own margin, so the heading starts in the
            // same column as the glyphs below it instead of hanging out to the
            // side of them.
            padding: EdgeInsetsDirectional.fromSTEB(16.w, 0, 16.w, 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: context.text.sectionLabel.asMedium),
                if (caption != null) ...<Widget>[
                  SizedBox(height: 3.h),
                  Text(caption!, style: context.text.caption),
                ],
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            // **Not optional.** A pressed row paints a full-bleed wash over
            // itself (see `PressFeedback.highlight`), so without clipping, the
            // first and last rows of every group would square off the corners
            // of the card they are inside for as long as a finger is down.
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < children.length; i++) ...<Widget>[
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
/// a full-width rule cuts the glyphs off from their own labels.
///
/// The inset is [SettingsGlyph.textInset] rather than a number typed here,
/// which is the only way it stays correct: it has already been wrong twice, at
/// 50 and then at 34, each time because a row's padding changed and the rule
/// was left behind pointing at a column that was no longer there.
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: SettingsGlyph.textInset),
      child: Divider(height: 1, thickness: 1, color: context.colors.border),
    );
  }
}
