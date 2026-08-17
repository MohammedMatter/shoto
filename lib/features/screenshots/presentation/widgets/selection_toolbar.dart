import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/app_snack_bar.dart';
import 'package:shoto/core/widgets/confirm_dialog.dart';
import 'package:shoto/core/widgets/glass_layer.dart';
import 'package:shoto/features/folders/presentation/widgets/move_to_folder_sheet.dart';
import 'package:shoto/features/safe_share/presentation/pages/safe_share_page.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_intent.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/widgets/intent_full_picker_sheet.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshot_limit_gate.dart';
import 'package:shoto/features/stitch/presentation/pages/open_stitch_page.dart';

/// The bar that appears while screenshots are picked — what is selected, and
/// what can be done with it.
///
/// **It floats at the bottom, and it gets out of the way.**
///
/// It used to be a strip at the very top of the page, above the grid, and it
/// was wrong twice over. It sat at the far end of the phone from the thumb
/// that had just long-pressed a thumbnail, so every action was a reach across
/// the whole screen. And because it was laid out *above* the scroll view, it
/// was permanent: five controls and a count nailed across the top of a screen
/// whose entire job at that moment is letting you scroll and keep picking.
///
/// Now it is a floating card over the grid, held one gap above the nav bar —
/// the same glass, the same shape language, so the two read as a stack rather
/// than as two unrelated bars. Because it overlays rather than occupies, the
/// grid keeps its full height; the space it would have cost is given back as
/// bottom padding instead (see [onHeightChanged]), which is what stops the
/// last row from living permanently underneath it.
///
/// And it hides itself. Scrolling down — going to look for more to pick — is
/// the one moment nobody needs the actions, so it slides away and gives the
/// grid the whole screen. Scrolling back up brings it straight back. The
/// thresholds are deliberately asymmetric (see `ScreenshotsBody`): it takes a
/// deliberate push to dismiss it and barely a nudge to get it back, because
/// the cost of the two mistakes is not the same — a bar that will not leave
/// is an annoyance, a bar that will not come back is a dead end, and this bar
/// is also the only way *out* of selection mode.
class SelectionToolbar extends StatefulWidget {
  /// Whether the library is in selection mode at all. Drives the same
  /// animation as [revealed]; the bar does not care which of the two sent it
  /// away.
  final bool selecting;

  /// Whether the scroll position currently wants the bar on screen.
  ///
  /// A listenable rather than a plain bool so that scrolling repaints this
  /// widget alone. Rebuilding the page — and with it a grid of decoded
  /// thumbnails — on every flick of the finger is the version of this that
  /// drops frames.
  final ValueListenable<bool> revealed;

  final int count;

  /// The job another screen sent the user here to do, if any.
  final LibraryIntent intent;

  /// Whether that job still needs more picked.
  final bool intentUnsatisfied;

  /// Reports how tall the bar is, including the gap it holds above the nav.
  ///
  /// The height cannot be predicted: the count line wraps to two under a
  /// guided prompt, the action row gains and loses buttons with the size of
  /// the selection, and all of it moves with the system text scale. So it is
  /// measured and handed up, and the grid pads its tail by exactly that much.
  final ValueChanged<double> onHeightChanged;

  const SelectionToolbar({
    super.key,
    required this.selecting,
    required this.revealed,
    required this.count,
    required this.onHeightChanged,
    this.intent = LibraryIntent.none,
    this.intentUnsatisfied = false,
  });

  @override
  State<SelectionToolbar> createState() => _SelectionToolbarState();
}

class _SelectionToolbarState extends State<SelectionToolbar>
    with SingleTickerProviderStateMixin {
  /// Arriving is slower than leaving, on purpose.
  ///
  /// The bar coming back is the thing the user is looking at — it should land
  /// rather than snap into place. The bar going away has already served its
  /// purpose the moment it starts moving, and every millisecond after that is
  /// grid the user asked for and has not been given yet.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 180),
  );

  /// [AppMotion.drawer] in, because this is a surface travelling in from off
  /// the edge of the screen and that curve lands flat — no bounce at the end
  /// of the trip. Out on the flipped ease-out, so the first frames after the
  /// finger moves are the fast ones; see [AppMotion.standardReverse] for why
  /// handing the same curve to both directions gets this backwards.
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.drawer,
    reverseCurve: AppMotion.standardReverse,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    // A third of its own height, not all of it. The bar only has to clear the
    // eye, and the fade is doing most of the work — a full-height slide would
    // still be visibly travelling through the nav bar's margin when it is
    // already invisible.
    begin: const Offset(0, 0.34),
    end: Offset.zero,
  ).animate(_curved);

  /// From 0.96, never from zero: something that grows out of nothing reads as
  /// being created rather than as arriving.
  late final Animation<double> _scale = Tween<double>(
    begin: 0.96,
    end: 1,
  ).animate(_curved);

  final GlobalKey _measureKey = GlobalKey();
  double _reportedHeight = 0;
  bool _reportScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.revealed.addListener(_sync);
    if (widget.selecting && widget.revealed.value) _controller.value = 1;
  }

  @override
  void didUpdateWidget(SelectionToolbar old) {
    super.didUpdateWidget(old);
    if (old.revealed != widget.revealed) {
      old.revealed.removeListener(_sync);
      widget.revealed.addListener(_sync);
    }
    _sync();
  }

  @override
  void dispose() {
    widget.revealed.removeListener(_sync);
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// One controller, two reasons to be hidden. Driving it from a single place
  /// is what lets the two interrupt each other cleanly: leaving selection
  /// while the bar is already half-gone continues from where it is rather
  /// than restarting the trip.
  void _sync() {
    if (widget.selecting && widget.revealed.value) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  /// Asks for a measurement after this frame has been laid out.
  ///
  /// **Driven from the transition rather than from `build`.** The obvious
  /// version — schedule it once per `build` — never fires on the run that
  /// matters: when a selection begins, this widget rebuilds while the
  /// controller is still dismissed, so the card is not in the tree yet and
  /// there is nothing to measure. The card mounts a frame later, from inside
  /// the animation, and `build` does not run again for it. A single selection
  /// would then never report a height, and the grid would keep its last row
  /// underneath the bar.
  ///
  /// The flag collapses the burst of requests the entrance produces — one per
  /// animated frame — down to one per frame, and [_report] itself does
  /// nothing when the answer has not moved.
  void _scheduleReport() {
    if (_reportScheduled) return;
    _reportScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reportScheduled = false;
      if (mounted) _report();
    });
  }

  /// Measured after layout, because that is the only point at which the
  /// answer exists.
  void _report() {
    final RenderBox? box =
        _measureKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final double height = box.size.height;
    if ((height - _reportedHeight).abs() < 0.5) return;
    _reportedHeight = height;
    widget.onHeightChanged(height);
  }

  @override
  Widget build(BuildContext context) {
    final bool reduced = AppMotion.reduced(context);

    return AnimatedBuilder(
      animation: _controller,
      // Built here rather than inside the builder so that scrolling the bar
      // in and out does not rebuild its contents — the transitions animate a
      // subtree that stays put.
      child: _card(context),
      builder: (BuildContext context, Widget? child) {
        // **Nothing in the tree at all when it is away.** The card is frosted,
        // and a `BackdropFilter` re-blurs its region on every frame in which
        // the pixels behind it move — which, over a scrolling grid, is every
        // frame. A hidden-but-mounted bar would go on charging for a blur
        // nobody can see. See [AppBlur].
        if (_controller.isDismissed) return const SizedBox.shrink();

        _scheduleReport();

        final Widget faded = FadeTransition(opacity: _curved, child: child);

        return IgnorePointer(
          // A bar that is mostly gone should not still be catching taps meant
          // for the thumbnail underneath it.
          ignoring: _controller.value < 0.5,
          child: reduced
              // Movement is what reduced motion asks to be spared; the fade
              // stays, because without it the bar would simply blink.
              ? faded
              : SlideTransition(
                  position: _slide,
                  child: ScaleTransition(
                    scale: _scale,
                    alignment: Alignment.bottomCenter,
                    child: faded,
                  ),
                ),
        );
      },
    );
  }

  /// The card itself: glass, a lit edge, and two rows.
  Widget _card(BuildContext context) {
    // The nav bar holds itself a fixed distance above the home indicator and
    // reports its own height to this page as bottom padding (the shell's
    // Scaffold runs `extendBody`). So one gap above that number is one gap
    // above the nav on every device, and on the screens that have no nav —
    // a folder, an intent page — it lands just above the home indicator
    // instead, which is the same intent.
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final BorderRadius shape = BorderRadius.all(
      Radius.circular(AppRadius.lg),
    );

    return Padding(
      key: _measureKey,
      // The same 20 the nav bar insets itself by, so the two edges line up
      // in the stack instead of missing each other by four pixels — which is
      // the distance at which an alignment reads as an accident.
      padding: EdgeInsetsDirectional.fromSTEB(
        20.w,
        0,
        20.w,
        bottomInset + 10.h,
      ),
      child: GlassLayer(
        borderRadius: shape,
        // The same sigma the nav bar takes — the smallest in the app — for
        // the same reason: this one is also over a scrolling grid. It is
        // affordable here only because selection is occasional and the bar
        // leaves the tree entirely the moment it is hidden.
        sigma: AppBlur.bar,
        child: GlassRim(
          borderRadius: shape,
          falloff: 40,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: shape,
              // Built from the nav bar's fill and then closed up a little.
              // Both surfaces have to be the same material or the stack of
              // them looks like an accident, but this one carries a count and
              // five labels over other people's screenshots, so it needs more
              // of the canvas and less of what is behind it than a row of
              // icons does.
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: context.colors.isDark
                    ? [
                        const Color(0xFF1B1C1D).withValues(alpha: 0.66),
                        const Color(0xFF131415).withValues(alpha: 0.78),
                      ]
                    : [
                        const Color(0xFFFFFFFF).withValues(alpha: 0.78),
                        const Color(0xFFF4F4F4).withValues(alpha: 0.88),
                      ],
              ),
            ),
            child: _SelectionToolbarContent(
              count: widget.count,
              intent: widget.intent,
              intentUnsatisfied: widget.intentUnsatisfied,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionToolbarContent extends StatelessWidget {
  final int count;
  final LibraryIntent intent;
  final bool intentUnsatisfied;

  const _SelectionToolbarContent({
    required this.count,
    required this.intent,
    required this.intentUnsatisfied,
  });

  @override
  Widget build(BuildContext context) {
    // The count is the right title for selection the user started themselves
    // — they know why they are here. When Home sent them, "2 selected" answers
    // a question nobody asked; what they need is what to pick, and they need
    // it until they have picked enough.
    //
    // Selection the user starts from the header arrives at the same problem
    // from its own direction: "0 selected" is a true sentence that tells
    // somebody who has just entered the mode nothing about what to do next.
    // It only lasts until the first tap.
    final String? prompt = !intentUnsatisfied
        ? (count == 0 ? context.l10n.librarySelectPrompt : null)
        : switch (intent) {
            LibraryIntent.none => null,
            LibraryIntent.merge => context.l10n.libraryPickForMerge,
            LibraryIntent.protect => context.l10n.libraryPickForProtect,
          };

    // Built as a list first so the row below can size itself from how many
    // there actually are, rather than being written as one long `Row` whose
    // width nobody can work out by reading it.
    final List<Widget> actions = <Widget>[
      // Safe share works on one screenshot, so unlike merging this action
      // appears at exactly one and disappears again at two. It is the same rule
      // stated from the other side: an action that cannot run should not be on
      // screen looking like it can.
      if (count == 1 && intent != LibraryIntent.merge)
        _ToolbarAction(
          icon: Icons.shield_outlined,
          iconColor: context.colors.secondary,
          label: context.l10n.libraryActionProtect,
          onTap: () async {
            final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
            final ScreenshotsState state = bloc.state;
            if (state is! ScreenshotsLoadedState) return;

            final String id = state.selectedIds.first;
            final ScreenshotEntity? shot = state.screenshots
                .where((ScreenshotEntity s) => s.id == id)
                .firstOrNull;
            if (shot == null) return;

            bloc.add(ClearSelectionEvent());
            await Navigator.of(context).push(
              FadeSlidePageRoute(
                builder: (_) => SafeSharePage(screenshot: shot),
              ),
            );
          },
        ),
      // Merging needs at least two captures to have anything to join, so the
      // action only appears once that's true rather than sitting there greyed
      // out.
      if (count >= 2 && intent != LibraryIntent.protect)
        _ToolbarAction(
          icon: Icons.view_agenda_outlined,
          iconColor: context.colors.primary,
          label: context.l10n.libraryActionMerge,
          onTap: () async {
            final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
            final ScreenshotsState state = bloc.state;
            if (state is! ScreenshotsLoadedState) return;

            final List<String> ids = state.selectedIds.toList();
            final bool merged = await openStitchPage(context, ids);
            if (merged) bloc.add(ClearSelectionEvent());
          },
        ),
      // Move and Delete belong to selection the user started themselves, where
      // "I have some screenshots picked, now what" is the whole point. Somebody
      // who tapped Safe share on Home has already said what they want; offering
      // to file or delete their screenshots instead is a different job wearing
      // the same toolbar — and one of the two is destructive, which is not a
      // thing to put under the thumb of a person who came here to do something
      // else.
      // `count > 0` is new and is not a tidiness rule. Every action below acts
      // on the selected set, and the bloc refuses all three on an empty one —
      // so before the header's Select button existed, this branch could only
      // ever be reached with something picked. It can be reached with nothing
      // picked now, and three buttons that look ready and do nothing is how a
      // person concludes the app is broken rather than that they missed a
      // step. The bar is a count and a way out until there is something to act
      // on.
      if (!intent.isGuided && count > 0) ...[
        // **The only way an existing library ever gets answered.**
        //
        // Intents were reachable one screenshot at a time, from a sheet behind
        // a small icon — which is fine for the ones taken from now on and
        // useless for the two thousand already there. Nobody opens two thousand
        // sheets. Here, forty at a time, "what are all of these for" is a
        // question with an answer.
        //
        // Not gated by the free-tier cap, unlike Move: an intent brings nothing
        // under management. It files no screenshot into anything and stars
        // nothing — it records a sentence about pictures the user already has.
        _ToolbarAction(
          icon: Icons.checklist_rtl_rounded,
          iconColor: context.colors.secondary,
          label: context.l10n.intentSelectionAction,
          onTap: () async {
            final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
            final IntentPickerResult? result = await showIntentFullPickerSheet(
              context,
              selected: null,
            );
            if (result == null) return;
            bloc.add(SetIntentForSelectionEvent(result.intent));
            if (!context.mounted) return;
            showAppSnackBar(context, context.l10n.intentSelectionApplied(count));
          },
        ),
        _ToolbarAction(
          icon: Icons.drive_file_move_rounded,
          iconColor: context.colors.secondary,
          label: context.l10n.libraryActionMove,
          onTap: () async {
            final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
            final ScreenshotsState state = bloc.state;
            int newItems = count;
            if (state is ScreenshotsLoadedState) {
              newItems = state.screenshots
                  .where(
                    (s) =>
                        state.selectedIds.contains(s.id) &&
                        !s.isFavorite &&
                        s.folderId == null,
                  )
                  .length;
            }
            final bool allowed = await ensureUnderScreenshotLimit(
              context,
              additionalNewItems: newItems,
            );
            if (!allowed || !context.mounted) return;
            showMoveToFolderSheet(
              context,
              onSelected: (folderId) =>
                  bloc.add(MoveSelectedToFolderEvent(folderId)),
            );
          },
        ),
        _ToolbarAction(
          icon: Icons.delete_outline_rounded,
          iconColor: context.colors.error,
          label: context.l10n.libraryActionDelete,
          onTap: () async {
            final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
            final bool confirmed = await confirmDeletion(
              context,
              title: context.l10n.libraryDeleteTitle,
              message: context.l10n.libraryDeleteMessage(count),
            );
            if (confirmed) bloc.add(DeleteSelectedEvent());
          },
        ),
      ],
    ];

    // **Two rows, because five controls and a sentence never fitted in one.**
    //
    // This was a single `Row`: a close button, the count, "Select all", and up
    // to four icon-and-label actions. On a 360dp phone the actions alone claim
    // most of the width, and the count sat in the `Expanded` that was left over
    // — so the one piece of information the bar exists to report got whatever
    // nobody else wanted. In practice that was about forty pixels: "10
    // selected" wrapped onto two lines and then ellipsized, and the bar read
    // "10 sel…" with a blue link jammed against a teal icon.
    //
    // Splitting it puts each half on a width it can actually have. The top row
    // is *what is happening* — how many, and how to stop or take everything.
    // The row underneath is *what you can do about it*, in equal columns, so
    // four actions and two actions are both centred and evenly spaced rather
    // than crowding to one end.
    //
    // The two are divided by a hairline rather than by the second row having a
    // box of its own. Inside a card that is already a surface, a nested surface
    // is one border too many — the card carries the shape, the line only says
    // where the reading stops and the doing starts.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16.w, 12.h, 16.w, 12.h),
          child: Row(
            children: [
              PressableScale(
                scale: 0.9,
                onTap: () =>
                    context.read<ScreenshotsBloc>().add(ClearSelectionEvent()),
                child: Icon(
                  Icons.close_rounded,
                  size: 22.sp,
                  color: context.colors.textPrimary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  prompt ?? context.l10n.librarySelectedCount(count),
                  style: prompt == null
                      ? context.text.titleLarge.copyWith(
                          color: context.colors.textPrimary,
                        )
                      : context.text.bodyMedium.asMedium.copyWith(
                          color: context.colors.textPrimary,
                        ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // **Select all belongs to selection the user started
              // themselves.**
              //
              // Neither guided job wants it: protecting takes one screenshot,
              // and merging takes the two or three shots of a single scroll —
              // "select all" is a wrong answer to both, offered in the most
              // prominent slot on the bar.
              if (!intent.isGuided) ...[
                SizedBox(width: 10.w),
                PressableScale(
                  scale: 0.94,
                  onTap: () =>
                      context.read<ScreenshotsBloc>().add(SelectAllEvent()),
                  child: Text(
                    context.l10n.librarySelectAll,
                    style: context.text.bodySmall.asMedium.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actions.isNotEmpty) ...[
          Divider(
            height: 1,
            thickness: 1,
            color: context.colors.border.withValues(alpha: 0.6),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
            child: Row(
              children: <Widget>[
                for (final Widget action in actions) Expanded(child: action),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ToolbarAction({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Was an InkWell. Its ripple has to be clipped to the rounded rect to
    // look right, reads as a grey smear on the dark theme, and — the part
    // that matters — only starts once the finger lifts. These four buttons
    // are the destructive end of the app; they should answer on the way down.
    return PressableScale(
      scale: 0.9,
      onTap: onTap,
      child: Padding(
        // **No horizontal padding of its own.** Each of these sits in an
        // `Expanded` inside the action row, so the column it is given *is* its
        // share of the width — padding here would narrow the label inside an
        // already-equal slot and make "Delete" ellipsize while "Move" had room
        // to spare.
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20.sp),
            SizedBox(height: 3.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.text.caption.asMedium.copyWith(color: iconColor),
            ),
          ],
        ),
      ),
    );
  }
}
