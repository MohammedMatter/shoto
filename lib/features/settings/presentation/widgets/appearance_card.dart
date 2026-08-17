import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/app_switch.dart';

/// The grouped container the Appearance page is built out of.
///
/// **A deliberate exception to `settings_group.dart`, and the only one.** That
/// file records taking the containers out of Settings: six bordered slabs down
/// a dark page read as chrome, and grouping is better said with a heading and
/// the space above it. That reasoning holds for *rows* — a run of labels and
/// switches needs no box to be read as a list.
///
/// It does not hold here, for two reasons this page runs into and Settings
/// never did. A swatch grid has no edge of its own, so six colours laid bare
/// on the canvas read as six objects floating at the same level as the
/// headings above them. And the controls on this page are *heterogeneous* —
/// a grid, a segmented picker, two switches — where Settings is a column of
/// one shape repeated. A box is what says "these different-looking things are
/// one setting each, and they belong together".
///
/// One shape for every group on the page, so the exception is a decision made
/// once rather than a style drifting in.
///
/// **It is no longer an exception.** Settings has its cards back — see
/// `settings_group.dart` for what was wrong with taking them away and which
/// half of that removal was right — so the two screens now build the same
/// object out of
/// the same three properties, and a user walking from one to the other is not
/// crossing between two ideas about what a group is. The border went with it,
/// on the same argument: `app_colors.dart` spaces the canvas a full step below
/// the surface precisely so a card does not need one, and the outline was the
/// part that read as chrome.
class AppearanceCard extends StatelessWidget {
  /// One entry per row. A hairline is drawn between them, inset to where the
  /// labels start — the same rule and the same inset as [SettingsDivider],
  /// because a rule that stops short of the text it separates draws attention
  /// to a column that is not there.
  final List<Widget> children;

  /// Dropped for a group whose content is not a list of rows — the swatch
  /// grid, which is one block and would otherwise be ruled through the middle.
  final bool divided;

  const AppearanceCard({
    super.key,
    required this.children,
    this.divided = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      // The "more colours" row paints a full-bleed wash when pressed, and it is
      // the last child of its card — without this it would square off the two
      // corners it sits in for as long as a finger is down.
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0 && divided)
              Padding(
                padding: EdgeInsetsDirectional.only(start: 16.w),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: context.colors.border,
                ),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A label and its control, on one line.
///
/// No icon, unlike [SettingsControlRow]. Settings uses a glyph per row because
/// it is a long list of unrelated things and the icons are what let somebody
/// find "Haptics" without reading every line. This page has three groups of
/// two or three rows each, already under a heading that names them — a column
/// of icons there is decoration standing in the one place a label should
/// start.
class AppearanceRow extends StatelessWidget {
  final String label;

  /// An optional second line, for a row whose effect is not obvious from its
  /// name alone.
  final String? description;
  final Widget trailing;

  const AppearanceRow({
    super.key,
    required this.label,
    required this.trailing,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(label, style: context.text.bodyLarge),
                if (description != null) ...<Widget>[
                  SizedBox(height: 2.h),
                  Text(description!, style: context.text.caption),
                ],
              ],
            ),
          ),
          SizedBox(width: 12.w),
          trailing,
        ],
      ),
    );
  }
}

/// The same row with a switch in it, which is most of them.
class AppearanceSwitchRow extends StatelessWidget {
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const AppearanceSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return AppearanceRow(
      label: label,
      description: description,
      // The one control on this page that shows the chosen accent without
      // being about it: `AppSwitch` takes its track from `primary` and its
      // thumb from `onPrimary`, so every switch in the app follows the tint
      // without knowing tints exist.
      trailing: AppSwitch(value: value, onChanged: onChanged),
    );
  }
}
