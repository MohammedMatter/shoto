import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/core/widgets/glass_layer.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/features/screenshots/presentation/bloc/intent_catalog.dart';
import 'package:shoto/features/screenshots/presentation/widgets/custom_intent_editor_sheet.dart';
import 'package:shoto/features/screenshots/presentation/widgets/intent_visuals.dart';

/// What the full picker decided.
///
/// A wrapper around a nullable rather than the nullable itself, so that
/// "dismissed" and "chose nothing in particular" stay distinguishable all the
/// way back to the caller. They are opposite instructions — leave it alone
/// versus clear it — and a bare `IntentRef?` says the same thing for both.
class IntentPickerResult {
  final IntentRef? intent;
  const IntentPickerResult(this.intent);
}

/// Every verb this account can use, plus the way to write another.
///
/// The compact row in front of this shows five; this shows all of them. It is
/// deliberately a plain scrolling list of the same chips rather than a search
/// field or a grouped picker — at this size, looking is faster than typing,
/// and a search field would make the vocabulary feel bigger than it is.
Future<IntentPickerResult?> showIntentFullPickerSheet(
  BuildContext context, {
  required IntentRef? selected,
}) {
  return showAppSheet<IntentPickerResult>(
    context: context,
    isScrollControlled: true,
    // Tall enough to be in the same bracket as the editor it leads to, and
    // they open back to back — a slower entrance here would be the first half
    // of the same gesture running at a different speed.
    enterDuration: AppMotion.normal,
    builder: (BuildContext sheetContext) =>
        _IntentFullPickerContent(selected: selected),
  );
}

class _IntentFullPickerContent extends StatefulWidget {
  final IntentRef? selected;

  const _IntentFullPickerContent({required this.selected});

  @override
  State<_IntentFullPickerContent> createState() =>
      _IntentFullPickerContentState();
}

class _IntentFullPickerContentState extends State<_IntentFullPickerContent> {
  final IntentCatalog _catalog = sl<IntentCatalog>();

  @override
  void initState() {
    super.initState();
    _catalog.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _catalog,
      builder: (BuildContext context, Widget? child) {
        final List<CustomIntent> mine = _catalog.customIntents;
        return SheetSurface(
          sigma: AppBlur.tallSheet,
          child: SafeArea(
            child: ConstrainedBox(
              // Capped so the sheet never becomes a full-screen page. It is a
              // list of short words; taking the whole screen for it would make
              // choosing one feel like navigating somewhere. Raised from 0.75
              // once the vocabulary reached fifteen — below that the chips had
              // to be scrolled to before they could be read, which is the same
              // complaint as a scroll box inside a sheet, one floor up.
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.85,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: context.colors.border,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Text(
                      context.l10n.intentPrompt,
                      style: context.text.headlineMedium,
                    ),
                    SizedBox(height: 18.h),
                    _SectionLabel(context.l10n.intentSectionCommon),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: <Widget>[
                        for (final ScreenshotIntent intent
                            in ScreenshotIntent.values)
                          _PickerChip(
                            icon: intent.icon,
                            label: intent.label(context),
                            isSelected:
                                widget.selected == BuiltInIntent(intent),
                            onTap: () => _choose(BuiltInIntent(intent)),
                          ),
                      ],
                    ),
                    SizedBox(height: 22.h),
                    _SectionLabel(context.l10n.intentSectionYours),
                    SizedBox(height: 10.h),
                    if (mine.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: Text(
                          context.l10n.intentYoursEmpty,
                          style: context.text.bodySmall.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 10.w,
                        runSpacing: 10.h,
                        children: <Widget>[
                          for (final CustomIntent intent in mine)
                            _PickerChip(
                              icon: intent.icon,
                              // The field, not the extension: a custom
                              // intent's label is already the user's own
                              // words and has no translation to look up.
                              label: intent.label,
                              isSelected: widget.selected == intent,
                              onTap: () => _choose(intent),
                              // Editing a verb you wrote belongs on the verb
                              // itself, not on a settings screen somewhere
                              // else — this is the only place it is ever
                              // looked at.
                              onLongPress: () => _editCustom(intent),
                            ),
                        ],
                      ),
                    SizedBox(height: 14.h),
                    _WriteYourOwnButton(onTap: _createCustom),
                    SizedBox(height: 18.h),
                    Divider(height: 1, color: context.colors.border),
                    SizedBox(height: 6.h),
                    // Always offered, even when nothing is set. "Not for
                    // anything" is a real answer to the question and not only
                    // an undo — a screenshot can be worth keeping and owe you
                    // nothing.
                    _ClearRow(
                      onTap: () => _finish(const IntentPickerResult(null)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _choose(IntentRef intent) {
    Haptics.confirm();
    // Tapping what is already set clears it, exactly as it does in the compact
    // row. The two pickers must not disagree about what a second tap means.
    _finish(IntentPickerResult(widget.selected == intent ? null : intent));
  }

  void _finish(IntentPickerResult result) {
    Navigator.of(context).pop(result);
  }

  Future<void> _createCustom() async {
    final CustomIntent? created = await showCustomIntentEditorSheet(context);
    if (created == null || !mounted) return;
    // Straight onto the screenshot. Somebody who just wrote "return it" wrote
    // it *about* the picture in front of them, and making them tap the chip
    // they have only now created is a step that exists for the code's benefit.
    _finish(IntentPickerResult(created));
  }

  Future<void> _editCustom(CustomIntent intent) async {
    await showCustomIntentEditorSheet(context, existing: intent);
    // The sheet writes through the catalog, which notifies; nothing to do here
    // but stay open on a list that has already updated itself.
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: context.text.bodySmall.asMedium.copyWith(
      color: context.colors.textSecondary,
      letterSpacing: 0.6,
    ),
  );
}

class _PickerChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _PickerChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(19.r),
        onTap: onTap,
        onLongPress: onLongPress == null
            ? null
            : () {
                Haptics.confirm();
                onLongPress!();
              },
        child: AnimatedContainer(
          duration: AppMotion.duration(context, AppMotion.press),
          curve: AppMotion.standard,
          // Taller than the compact row's chips. That row is glanced at
          // mid-save with a thumb already moving; this is a sheet somebody
          // opened on purpose to read a list, and a 34px tap target in a grid
          // of twenty is where "cramped" comes from.
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colors.primary
                : context.colors.surfaceVariant,
            borderRadius: BorderRadius.circular(19.r),
            border: Border.all(
              color: isSelected ? Colors.transparent : context.colors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 15.sp,
                color: isSelected
                    ? context.colors.onPrimary
                    : context.colors.textSecondary,
              ),
              SizedBox(width: 7.w),
              Text(
                label,
                style: context.text.bodySmall.asMedium.copyWith(
                  color: isSelected
                      ? context.colors.onPrimary
                      : context.colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashed-looking outline rather than a filled chip, so it reads as a slot to
/// be filled instead of as a sixteenth verb sitting among the fifteen.
class _WriteYourOwnButton extends StatelessWidget {
  final VoidCallback onTap;

  const _WriteYourOwnButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.edit_rounded,
              size: 17.sp,
              color: context.colors.textSecondary,
            ),
            SizedBox(width: 10.w),
            Text(
              context.l10n.intentNewAction,
              style: context.text.bodyMedium.asMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearRow extends StatelessWidget {
  final VoidCallback onTap;

  const _ClearRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.98,
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          Icons.not_interested_rounded,
          color: context.colors.textSecondary,
        ),
        title: Text(
          context.l10n.intentClear,
          style: context.text.bodyLarge.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
