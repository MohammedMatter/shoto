import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';

/// One column of a drum picker: a list of short labels, one of which is under
/// the line.
///
/// **Why the app has this at all, rather than Material's dial.** Setting a
/// reminder went through `showTimePicker`, and a clock face is the wrong
/// instrument for the job twice over. It asks for an *angle* when the user has
/// a *number* in mind, so a five-minute correction is a small arc dragged with
/// a fingertip that covers the value it is setting; and it is two gestures
/// deep before the minutes even appear, because the hour has to be committed
/// first. A drum asks for the number directly, shows its neighbours, and
/// cannot be off by an hour because the hour never leaves the screen.
///
/// Three details do most of the work of making it feel like an object rather
/// than a list:
///
/// * **It ticks.** [Haptics.tick] on every detent, which is the whole reason
///   that effect exists — a dial with notches you cannot feel is a scrollbar.
/// * **Neighbours are visible and dimmed**, so the column reads as a surface
///   curving away rather than as text fading out.
/// * **A neighbour can be tapped**, and this is the part people find by
///   accident and then keep using: the value two rows up is one tap away
///   instead of a drag that has to be released in exactly the right place.
///
/// Values that cannot be chosen are drawn in [AppPalette.textDisabled] and
/// left in place rather than removed — see [enabled]. A wheel whose contents
/// change length under the finger loses the one thing a wheel is for, which is
/// that the same number is always in the same place.
class WheelPicker extends StatefulWidget {
  /// Owned by the caller, because the caller is the only one that can put the
  /// wheel somewhere specific — see the reminder sheet, which snaps every
  /// column back to the earliest allowed time when a finger lets go past it.
  final FixedExtentScrollController controller;

  final int count;

  /// What is currently under the line. Held by the caller rather than read off
  /// [controller] so a rebuild has a value even before the wheel has laid out
  /// — `selectedItem` throws when no position is attached yet.
  final int selected;

  final String Function(int index) label;

  /// Whether [index] may be chosen. Null means every index may be.
  final bool Function(int index)? enabled;

  /// A detent passed under the finger. Fires continuously through a fling, not
  /// only when the wheel settles, so anything showing the composed value stays
  /// in step with what the user is looking at.
  final ValueChanged<int> onChanged;

  /// The wheel came to rest. Where a caller corrects an impossible choice —
  /// during the gesture would mean moving the drum while it is being held.
  final ValueChanged<int>? onSettled;

  /// What a screen reader calls this column: "Hour", "Minute".
  ///
  /// The wheel is presented to assistive technology as an **adjustable value**
  /// rather than as the list it is built from. A drum is a gesture, and
  /// swiping through sixty unlabelled text nodes to find one is not a way to
  /// set a time; `onIncrease`/`onDecrease` gives TalkBack and VoiceOver the
  /// up/down adjustment they already have a vocabulary for.
  final String semanticLabel;

  const WheelPicker({
    super.key,
    required this.controller,
    required this.count,
    required this.selected,
    required this.label,
    required this.onChanged,
    required this.semanticLabel,
    this.enabled,
    this.onSettled,
  });

  /// The height of one row, and so the height of the selection band the caller
  /// draws behind the columns. Shared rather than passed, because a band that
  /// does not match the row it frames is visible immediately.
  static double get itemExtent => 40.h;

  /// Five rows: the choice, two above, two below.
  ///
  /// Odd on purpose — an even count has no middle, so nothing can sit on the
  /// line. Five is also where the curve reads: at three the drum looks flat,
  /// and past seven the outermost rows are so foreshortened they are noise.
  static double get height => itemExtent * 5;

  /// How wide one column is drawn.
  ///
  /// **Fixed, rather than each column taking an equal share of the row**, and
  /// the difference was obvious the moment this ran on a phone: sharing the
  /// width centres the hours in the left half and the minutes in the right, so
  /// `17` and `40` end up a third of the screen apart with a colon stranded
  /// between them. That is two numbers, not a time. Fixed columns let the
  /// group sit together in the middle and read as one figure, and 96 is still
  /// a third of a phone's width — no harder to get a thumb on than before.
  static double get columnWidth => 96.w;

  @override
  State<WheelPicker> createState() => _WheelPickerState();
}

class _WheelPickerState extends State<WheelPicker> {
  /// Suppresses the tick while the wheel is being moved by code.
  ///
  /// A correction that travels fifteen rows would otherwise play fifteen
  /// detents, which says "you did that" about something the user did not do —
  /// and it says it loudest exactly when the app is overruling them.
  bool _driven = false;

  /// **The wheel follows [WheelPicker.selected], wherever it comes from.**
  ///
  /// This is what lets the caller correct an impossible choice by doing
  /// nothing more than setting state: the reminder sheet moves its hour and
  /// minute to the earliest allowed time, and both columns animate there
  /// themselves. The alternative — handing the controller to the caller and
  /// letting it drive `animateToItem` — would work and would tick all the way,
  /// because the suppression flag lives in here with the callback it silences.
  @override
  void didUpdateWidget(WheelPicker old) {
    super.didUpdateWidget(old);
    if (widget.selected == old.selected) return;

    // **After the frame, not inside it.** This runs while the parent is
    // building, and starting a scroll activity from there reaches back into
    // the `Scrollable` below to take pointers away from it — a `setState` on a
    // descendant mid-build, which is the one thing the framework will not
    // have. One frame of delay before an animation that lasts twenty is not
    // something anybody can see.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Already reported: the change came from the finger, and the wheel is
      // where it belongs.
      _moveTo(widget.selected, notify: false);
    });
  }

  /// Moves the drum under its own power.
  ///
  /// [notify] is false when the caller already knows — a value pushed in
  /// through [WheelPicker.selected] does not need handing back, and doing so
  /// would set state during a build.
  Future<void> _moveTo(int index, {bool notify = true}) async {
    if (!widget.controller.hasClients) return;
    if (index == widget.controller.selectedItem) return;

    _driven = true;
    if (notify) widget.onChanged(index);

    final Duration travel = AppMotion.duration(context, AppMotion.normal);
    // **`animateToItem` asserts on a zero duration.** Which is exactly what
    // [AppMotion.duration] hands back when the user has asked the system to
    // remove animation — so the accessible path was the one that would have
    // crashed. Reduced motion means arriving without travelling, not not
    // arriving.
    if (travel == Duration.zero) {
      widget.controller.jumpToItem(index);
      _driven = false;
      return;
    }

    await widget.controller.animateToItem(
      index,
      duration: travel,
      curve: AppMotion.standard,
    );
    if (mounted) _driven = false;
  }

  bool _enabled(int index) => widget.enabled?.call(index) ?? true;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      value: widget.label(widget.selected),
      increasedValue: widget.selected + 1 < widget.count
          ? widget.label(widget.selected + 1)
          : null,
      decreasedValue: widget.selected > 0
          ? widget.label(widget.selected - 1)
          : null,
      onIncrease: widget.selected + 1 < widget.count
          ? () => _moveTo(widget.selected + 1)
          : null,
      onDecrease: widget.selected > 0
          ? () => _moveTo(widget.selected - 1)
          : null,
      child: ExcludeSemantics(
        child: NotificationListener<ScrollEndNotification>(
          onNotification: (ScrollEndNotification _) {
            widget.onSettled?.call(widget.controller.selectedItem);
            // Never absorbed: the sheet above may be listening for the same
            // notification to know the user has stopped interacting.
            return false;
          },
          child: SizedBox(
            height: WheelPicker.height,
            child: ListWheelScrollView.useDelegate(
              controller: widget.controller,
              itemExtent: WheelPicker.itemExtent,
              physics: const FixedExtentScrollPhysics(),
              // A drum rather than a cylinder seen edge-on. Material's default
              // ratio of 2 is nearly flat; at 1.5 the rows visibly curve away
              // and the column reads as something with a far side.
              diameterRatio: 1.5,
              perspective: 0.004,
              // Rows tighten as they leave the middle, the way marks on a
              // physical dial do. Above about 1.1 they start to overlap.
              squeeze: 1.05,
              // The fade is the wheel's, not the text style's: styling
              // neighbours in `textSecondary` and leaving them at full opacity
              // makes two rows compete with the one under the line.
              overAndUnderCenterOpacity: 0.6,
              onSelectedItemChanged: (int index) {
                // **A wheel moving under its own power reports nothing.**
                //
                // Every detent it crosses on the way to a value the caller
                // *chose* would otherwise arrive as news — and a caller cannot
                // tell that apart from a finger. The reminder sheet found this
                // the hard way: it corrects an expired choice, says so, and
                // then the correction's own animation ticked through eleven
                // detents, each one read as "the user touched something", and
                // the sentence explaining the correction was wiped before
                // anybody could read it.
                //
                // Nothing is lost by staying quiet. [_moveTo] hands the caller
                // the destination up front when it is news, and says nothing
                // when the value came from the caller to begin with.
                if (_driven) return;
                Haptics.tick();
                widget.onChanged(index);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: widget.count,
                builder: (BuildContext context, int index) =>
                    _Row(
                      label: widget.label(index),
                      selected: index == widget.selected,
                      enabled: _enabled(index),
                      onTap: () => _moveTo(index),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One value on the drum.
///
/// Set in the mono family for the same reason every other figure in this app
/// is: these are digits read one at a time, and with proportional numerals the
/// column visibly shifts sideways as it turns — a "1" is narrower than a "8",
/// so the wheel wobbles while it spins. Tabular figures make it a straight
/// line.
class _Row extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _Row({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // **A value that cannot be chosen has to lose to one that merely is not
    // chosen**, and on the phone it did not: the wheel already fades
    // everything off the line to 60%, which narrowed the gap between
    // `textDisabled` and `textSecondary` to almost nothing. Two rows above the
    // line read the same whether they were a past hour or a perfectly good
    // one. Taking the alpha down again restores the difference the fade ate.
    final Color color = !enabled
        ? context.colors.textDisabled.withValues(alpha: 0.45)
        : selected
        ? context.colors.textPrimary
        : context.colors.textSecondary;

    return GestureDetector(
      // Opaque so the whole row is a target, not just the two characters on
      // it. The wheel's own drag still wins the arena the moment the finger
      // moves, so this costs the gesture nothing.
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Haptics.tap();
        onTap();
      },
      child: Center(
        child: Text(
          label,
          style: context.text.mono.copyWith(
            fontSize: 20.sp,
            // The chosen row is the only one that carries weight. Size stays
            // constant across the column — growing the middle row is the
            // magnifier effect, and it makes every neighbour look like a
            // different control.
            fontWeight: selected
                ? AppTypography.semiBold
                : AppTypography.regular,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// The line the chosen value sits on.
///
/// Drawn once behind all the columns rather than per column, which is what
/// makes three separate wheels read as one instrument. Sized from
/// [WheelPicker.itemExtent] so it can never drift out of register with the
/// rows it frames.
///
/// A filled band rather than the two hairlines iOS uses: this sheet is glass
/// over whatever the user was looking at, and a hairline over a photograph is
/// a hairline nobody can find.
class WheelSelectionBand extends StatelessWidget {
  const WheelSelectionBand({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          height: WheelPicker.itemExtent,
          decoration: BoxDecoration(
            color: context.colors.surfaceElevated.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
    );
  }
}
