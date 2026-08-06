import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/widgets/intent_picker_row.dart';

/// The question, the answer, and the tick that finishes it — for one
/// screenshot.
///
/// Shared by the quick-actions sheet and the full-screen viewer rather than
/// written twice. The two used to differ in the worst possible way: the sheet
/// could set an intent and the viewer, which is where you actually *look* at a
/// screenshot and decide what it is for, could not. Anything that changes here
/// — what a second tap means, whether changing the verb clears the tick —
/// has to change in both, and one widget is the only way that stays true.
///
/// Stateful only so the chips repaint the instant they are tapped: it is built
/// from the [ScreenshotEntity] handed in, which is a snapshot and does not
/// change under it while the surface is open.
class IntentSection extends StatefulWidget {
  final ScreenshotEntity item;
  final ScreenshotsBloc bloc;

  /// Whether to print "What will you do with it?" above the chips.
  ///
  /// Off where the surrounding surface has already made the question obvious.
  final bool showPrompt;

  const IntentSection({
    super.key,
    required this.item,
    required this.bloc,
    this.showPrompt = true,
  });

  @override
  State<IntentSection> createState() => _IntentSectionState();
}

class _IntentSectionState extends State<IntentSection> {
  late IntentRef? _intent = widget.item.intent?.ref;
  late bool _isDone = widget.item.intent?.isDone ?? false;

  /// Re-syncs when the surface is reused for a different screenshot.
  ///
  /// The viewer is a `PageView`: swiping to the next screenshot keeps this
  /// `State` alive and only swaps the widget under it, so without this the
  /// second screenshot would show the first one's answer.
  @override
  void didUpdateWidget(IntentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id == widget.item.id) return;
    setState(() {
      _intent = widget.item.intent?.ref;
      _isDone = widget.item.intent?.isDone ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IntentPickerRow(
          selected: _intent,
          showPrompt: widget.showPrompt,
          onChanged: (IntentRef? next) {
            setState(() {
              _intent = next;
              // Changing the intent drops the tick with it, matching what the
              // repository does — the surface must not show a finished state
              // for a task that has just been replaced.
              _isDone = false;
            });
            widget.bloc.add(SetIntentEvent(widget.item.id, next));
          },
        ),

        // The tick appears only once there is something to tick. Offering it
        // beforehand would be a control that does nothing, and neither surface
        // has room to spend on those.
        AnimatedSize(
          duration: AppMotion.duration(context, AppMotion.instant),
          curve: AppMotion.standard,
          alignment: Alignment.topCenter,
          child: _intent == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: EdgeInsets.only(top: 14.h),
                  child: _CompletionButton(
                    isDone: _isDone,
                    onTap: () {
                      Haptics.confirm();
                      setState(() => _isDone = !_isDone);
                      widget.bloc.add(
                        SetIntentDoneEvent(widget.item.id, _isDone),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

/// The one control in SHOTO that makes a number go down.
///
/// **It used to be a line of text with a small circle beside it**, which is
/// what a checkbox in a settings list looks like — and this is not that. Every
/// other figure in the app only accumulates: screenshots, folders, things not
/// filed. This is the single place a person finishes something, and it was
/// dressed as the least consequential row on the sheet.
///
/// So it is a full-width surface, and the two states are genuinely different
/// objects rather than one object with a different tint:
///
/// * **Waiting** — outlined, quiet, an empty ring. It is an invitation, and an
///   invitation that shouts is pressure.
/// * **Done** — filled with the palette's completion colour, ring closed into
///   a tick. Filling is what makes it read as *arriving at* a state instead of
///   as toggling a switch, and it is the same green the badge on the picture
///   turns, so the two are visibly the same event seen from two places.
///
/// Both halves cross-fade rather than cut, because pressing this is the moment
/// the feature exists for and a hard swap would spend it in one frame.
class _CompletionButton extends StatelessWidget {
  final bool isDone;
  final VoidCallback onTap;

  const _CompletionButton({required this.isDone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color content = isDone
        ? context.colors.onPrimary
        : context.colors.textPrimary;

    return PressableScale(
      scale: 0.97,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.duration(context, AppMotion.normal),
        curve: AppMotion.standard,
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isDone ? context.colors.success : Colors.transparent,
          borderRadius: BorderRadius.circular(14.r),
          // Always 1.5 and only the colour animates, so lighting it up cannot
          // nudge the sheet's layout — same rule as the private-folder row.
          border: Border.all(
            color: isDone ? Colors.transparent : context.colors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.normal),
              switchInCurve: AppMotion.standard,
              switchOutCurve: AppMotion.standard,
              transitionBuilder: (Widget child, Animation<double> animation) =>
                  FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.7,
                        end: 1,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
              child: Icon(
                isDone
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                key: ValueKey<bool>(isDone),
                size: 19.sp,
                color: content,
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              isDone ? context.l10n.intentUndo : context.l10n.intentMarkDone,
              style: context.text.bodyMedium.asMedium.copyWith(color: content),
            ),
          ],
        ),
      ),
    );
  }
}
