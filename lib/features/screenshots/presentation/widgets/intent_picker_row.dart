import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/screenshots/presentation/bloc/intent_catalog.dart';
import 'package:shoto/features/screenshots/presentation/widgets/intent_full_picker_sheet.dart';
import 'package:shoto/features/screenshots/presentation/widgets/intent_visuals.dart';

/// The one-tap question: what are you going to do with this?
///
/// **Everything about this row is shaped by when it is asked.** It appears at
/// the moment of saving, which is the only moment the answer is obvious and
/// also the moment the user has least patience — walking, mid-conversation,
/// about to put the phone away. So: no typing, no scrolling, no confirmation,
/// and tapping the chosen one again takes it back off.
///
/// It is never required. A screenshot with no intent is the normal case, and a
/// question that blocks saving would be answered at random within a week.
///
/// ## Five chips, out of however many exist
///
/// The vocabulary is now fifteen built-in verbs plus anything the user has
/// written, and none of that reaches this row. It shows the five this person
/// has used most recently — see [IntentCatalog.frontRow] — and everything else
/// is one tap away behind `+`. That keeps the property that matters (the
/// common answer costs one tap, always) without capping the property that
/// does not (how many answers the app is able to express).
///
/// A row that scrolled instead would technically hold all of them and in
/// practice hold five, since nobody scrolls a chip row mid-save — the
/// difference being that the other ten would be invisible rather than one tap
/// away.
class IntentPickerRow extends StatefulWidget {
  final IntentRef? selected;
  final ValueChanged<IntentRef?> onChanged;

  /// Whether to print the question above the chips.
  ///
  /// On for the save sheet, where the row arrives unannounced. Off where the
  /// surrounding screen has already asked.
  final bool showPrompt;

  const IntentPickerRow({
    super.key,
    required this.selected,
    required this.onChanged,
    this.showPrompt = true,
  });

  @override
  State<IntentPickerRow> createState() => _IntentPickerRowState();
}

class _IntentPickerRowState extends State<IntentPickerRow> {
  final IntentCatalog _catalog = sl<IntentCatalog>();

  @override
  void initState() {
    super.initState();
    // Does nothing after the first success anywhere in the app, so every
    // picker can ask without any of them having to know whether it is first.
    _catalog.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _catalog,
      builder: (BuildContext context, Widget? child) {
        final List<IntentRef> frontRow = _catalog.frontRow(
          selected: widget.selected,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (widget.showPrompt) ...<Widget>[
              Text(
                context.l10n.intentPrompt,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 10.h),
            ],
            SizedBox(
              height: 38.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                // Five chips plus `+` still reach past a narrow phone in the
                // longer languages — "Responder", "जवाब दें" — so the row
                // scrolls rather than squeezing the labels to fit. It is not
                // meant to be scrolled; it is meant not to overflow.
                padding: EdgeInsets.zero,
                children: <Widget>[
                  for (final IntentRef intent in frontRow) ...<Widget>[
                    _IntentChip(
                      icon: intent.icon,
                      label: intent.label(context),
                      isSelected: widget.selected == intent,
                      // Tapping the chosen one clears it. Same rule as the
                      // library lens: the control that set a thing is the
                      // first place anyone looks to unset it.
                      onTap: () => widget.onChanged(
                        widget.selected == intent ? null : intent,
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                  _IntentChip(
                    icon: Icons.add_rounded,
                    label: context.l10n.intentMore,
                    isSelected: false,
                    onTap: _openFullPicker,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openFullPicker() async {
    final IntentPickerResult? result = await showIntentFullPickerSheet(
      context,
      selected: widget.selected,
    );
    // A null *result* is the sheet being dismissed and must change nothing; a
    // result carrying a null intent is the user choosing "not for anything",
    // which must clear it. Collapsing the two into one nullable would make
    // swiping the sheet away silently erase an answer.
    if (result == null) return;
    widget.onChanged(result.intent);
  }
}

/// One chip, driven by a glyph and a string rather than by an intent.
///
/// Takes them loose so the `+` chip is the same object as the fifteen verbs:
/// same height, same padding, same press. A separately built "more" button is
/// how a row ends up a pixel off in one language.
class _IntentChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _IntentChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<ThemeController>(),
      builder: (BuildContext context, Widget? child) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(19.r),
          onTap: () {
            // A firmer tap than a filter chip's. This is a decision being
            // recorded, not a view being narrowed, and the difference is worth
            // one step of haptic weight.
            Haptics.confirm();
            onTap();
          },
          child: AnimatedContainer(
            duration: AppMotion.duration(context, AppMotion.press),
            curve: AppMotion.standard,
            padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 8.h),
            decoration: BoxDecoration(
              // The accent, not a per-intent hue — see IntentVisuals.tint.
              color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(19.r),
              border: Border.all(
                color: isSelected ? Colors.transparent : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  icon,
                  size: 15.sp,
                  color: isSelected
                      ? AppColors.onPrimary
                      : AppColors.textSecondary,
                ),
                SizedBox(width: 7.w),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.asMedium.copyWith(
                    color: isSelected
                        ? AppColors.onPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
