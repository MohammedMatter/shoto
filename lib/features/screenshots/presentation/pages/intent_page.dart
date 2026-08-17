import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/photo_viewer_route.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/core/widgets/animated_id_grid.dart';
import 'package:shoto/core/widgets/empty_state.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/pages/screenshot_detail_page.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/widgets/intent_full_picker_sheet.dart';
import 'package:shoto/features/screenshots/presentation/widgets/intent_visuals.dart';
import 'package:shoto/features/screenshots/presentation/widgets/library_unavailable.dart';

/// Everything still waiting under one intent, and one gesture to finish it.
///
/// **This is the screen the whole feature exists for.** Every other number in
/// Shoto only goes up — screenshots, folders, unsorted. This is the one place
/// where the user does something and the number falls, and the design is
/// arranged entirely around making that moment land: one column so each item
/// is a decision rather than a thumbnail in a wall, the tick as the largest
/// control on the row, and the item leaving the list under its own animation
/// so the change is something you watch rather than something you notice.
class IntentPage extends StatelessWidget {
  final IntentRef intent;

  const IntentPage({super.key, required this.intent});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenshotsBloc, ScreenshotsState>(
      builder: (context, state) {
        // **An unread library is not an empty one.** This used to fall back to
        // an empty list for every state that was not loaded, and an empty
        // waiting list here draws a green tick and "you're all done" — so a
        // refused photo permission congratulated the user for clearing a list
        // the app had never been allowed to see.
        final Widget? blocked = LibraryUnavailable.maybeOf(state);

        final ScreenshotsLoadedState? loaded = state is ScreenshotsLoadedState
            ? state
            : null;
        final List<ScreenshotEntity> waiting =
            loaded?.waitingFor(intent) ?? const <ScreenshotEntity>[];
        final int done = loaded?.doneFor(intent) ?? 0;

        return Scaffold(
          backgroundColor: context.colors.background,
          appBar: AppBar(
            backgroundColor: context.colors.background,
            elevation: 0,
            iconTheme: IconThemeData(color: context.colors.textPrimary),
            title: Text(
              intent.waitingTitle(context),
              style: context.text.titleLarge,
            ),
          ),
          body: SafeArea(
            // The tick is reserved for a list that was read and found clear.
            child: blocked ??
                (waiting.isEmpty
                ? EmptyState(
                    icon: Icons.check_circle_rounded,
                    title: context.l10n.intentEmptyOne(
                      intent.label(context).toLowerCase(),
                    ),
                    message: context.l10n.intentEmptyBody,
                  )
                : AnimatedIdGrid<ScreenshotEntity>(
                    items: waiting,
                    idOf: (ScreenshotEntity item) => item.id,
                    padding: EdgeInsetsDirectional.fromSTEB(
                      20.w,
                      4.h,
                      20.w,
                      24.h,
                    ),
                    // **Inside the scroll, not stacked above it.**
                    //
                    // The progress block used to sit in a `Column` over the
                    // list, which charged the top sixth of the phone for it on
                    // every frame no matter how far down you had scrolled. It
                    // is a header: it belongs to the top of the content, and it
                    // should leave when the top of the content does. This is
                    // the case `leadingSlivers` exists for, and its own doc
                    // argues it better than this comment can.
                    leadingSlivers: <Widget>[
                      SliverToBoxAdapter(
                        child: _Progress(
                          waiting: waiting.length,
                          done: done,
                          intent: intent,
                        ),
                      ),
                    ],
                    // **A bottom edge for a list that is short.**
                    //
                    // One card on a tall phone was one card and then two
                    // thirds of black, which reads as content that failed to
                    // load rather than as a list that has ended.
                    trailingSlivers: <Widget>[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                            20.w,
                            8.h,
                            20.w,
                            120.h,
                          ),
                          child: Text(
                            context.l10n.intentListEnd(waiting.length),
                            textAlign: TextAlign.center,
                            style: context.text.caption.copyWith(
                              color: context.colors.textDisabled,
                            ),
                          ),
                        ),
                      ),
                    ],
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      // **One column, deliberately.** A grid turns this into
                      // another gallery to browse; a list turns each row into
                      // one thing to decide about, which is what the screen is
                      // for.
                      crossAxisCount: 1,
                      mainAxisSpacing: 16.h,
                      // **Big enough for the picture to be the point.** Two
                      // earlier versions put a 96pt thumbnail on the leading
                      // edge with the text and buttons beside it — the shape of
                      // a settings row, applied to a screen whose entire
                      // content is pictures. It could be tidied but never made
                      // good: a strip that small cannot be recognised, so every
                      // row leaned on a date to identify a thing the eye should
                      // have known instantly.
                      mainAxisExtent: 252.h,
                    ),
                          itemBuilder: (context, item, index, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SizeTransition(
                                sizeFactor: animation,
                                child: _WaitingRow(
                                  screenshot: item,
                                  onChange: () => _changeIntent(context, item),
                                  onOpen: () => _open(context, waiting, index),
                                  onDone: () {
                                    // Fires before the row leaves, so the
                                    // feedback and the movement are one event
                                    // rather than a buzz followed by a
                                    // disappearance.
                                    Haptics.confirm();
                                    context.read<ScreenshotsBloc>().add(
                                      SetIntentDoneEvent(item.id, true),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                  )),
          ),
        );
      },
    );
  }
}

/// How far down the list has come — as one segment per screenshot.
///
/// **A continuous track was the wrong instrument for this measurement.** The
/// numbers here are small: three things to reply to, five to compare. A 4pt
/// hairline stretched across the screen to express "one of two" is a bar that
/// can only ever be empty, half, or full, and it spent the full width of the
/// page saying so. It was also the single most generic component in the app —
/// the shape every progress bar everywhere has.
///
/// Segments say the true thing instead: **this list has five items in it, and
/// two of them are behind you.** The count is legible without reading the
/// number, each tick fills exactly one segment, and the reward for finishing
/// something is a discrete block landing rather than a sliver of width.
///
/// Past [_maxSegments] it becomes a track again, because forty segments on a
/// phone are forty two-pixel slivers — a texture, not a count. The threshold
/// is where a segment stops being wide enough to read as an object.
class _Progress extends StatelessWidget {
  final int waiting;
  final int done;
  final IntentRef intent;

  const _Progress({
    required this.waiting,
    required this.done,
    required this.intent,
  });

  static const int _maxSegments = 12;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final int total = waiting + done;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20.w, 6.h, 20.w, 18.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              // The verb's own glyph, in the one tint the feature allows
              // itself. `IntentVisuals` is deliberate that colour here marks
              // *waiting versus done* and never which verb this is — so the
              // icon carries the identity and the palette carries the state.
              Icon(intent.icon, size: 16.sp, color: colors.secondary),
              SizedBox(width: 8.w),
              Text(
                context.l10n.intentProgress(done, total),
                style: context.text.bodySmall.copyWith(
                  // Sage only once there is something to be pleased about.
                  // Sage at zero would colour a line whose content is "you
                  // have not started".
                  color: done > 0 ? colors.success : colors.textSecondary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          SizedBox(
            height: 6.h,
            child: total <= _maxSegments
                ? _segments(context, total)
                : _track(context, total),
          ),
        ],
      ),
    );
  }

  Widget _segments(BuildContext context, int total) {
    final AppPalette colors = context.colors;

    return Row(
      children: <Widget>[
        for (int i = 0; i < total; i++) ...<Widget>[
          if (i > 0) SizedBox(width: 5.w),
          Expanded(
            // Animated because a segment only ever changes as the direct
            // result of the user tapping Done — the one progress change in
            // Shoto they just caused, and so the one worth watching land.
            child: AnimatedContainer(
              duration: AppMotion.reduced(context)
                  ? Duration.zero
                  : AppMotion.normal,
              curve: AppMotion.standard,
              decoration: BoxDecoration(
                color: i < done ? colors.success : colors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// The old continuous bar, kept for lists too long to segment.
  Widget _track(BuildContext context, int total) {
    final AppPalette colors = context.colors;
    final double fraction = total == 0 ? 0 : (done / total).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: ColoredBox(color: colors.surfaceVariant)),
          AnimatedFractionallySizedBox(
            duration: AppMotion.reduced(context)
                ? Duration.zero
                : AppMotion.sheet,
            curve: AppMotion.standard,
            widthFactor: fraction,
            alignment: AlignmentDirectional.centerStart,
            child: ColoredBox(color: colors.success),
          ),
        ],
      ),
    );
  }
}

class _WaitingRow extends StatelessWidget {
  final ScreenshotEntity screenshot;
  final VoidCallback onDone;

  /// Re-answers the question for this one.
  ///
  /// The row used to offer exactly one verdict — finished — which is only half
  /// of what a waiting list is for. The other half is realising a thing was
  /// filed wrong, or that you are never going to do it: both are ways of
  /// getting a number down honestly, and without them the only way off this
  /// screen was to claim you had done something you had not.
  final VoidCallback onChange;

  /// Opens the picture full-screen.
  ///
  /// **Added the moment the picture became the card.** While the thumbnail was
  /// a 96pt chip it was plausible that tapping it meant "act on this item";
  /// once it fills the card, tapping it can only mean one thing to anybody
  /// holding a phone — show me the picture. Leaving that tap wired to a verb
  /// picker made the largest, most obviously tappable thing on the screen do
  /// the one thing nobody would predict.
  final VoidCallback onOpen;

  const _WaitingRow({
    required this.screenshot,
    required this.onDone,
    required this.onChange,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    // **No whole-card tap any more.** The card used to be one big button that
    // opened the verb picker, which is how the picker ended up owning a
    // gesture the picture had a much better claim to. Each region now says
    // what it does: the photograph opens the photograph, and the two controls
    // in the bar are controls.
    return _body(context);
  }

  Widget _body(BuildContext context) {
    final AppPalette colors = context.colors;
    final DateTime taken = screenshot.asset.createDateTime;
    final bool stale = DateTime.now().difference(taken).inDays >= 30;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20.r),
      ),
      // **No border.** A hairline stroke around a dark card on a near-black
      // page reads as a seam rather than an edge — it was the only thing
      // separating card from background, and it did it badly. The surface is
      // a step lighter than the page and the picture supplies the contrast,
      // which is what actually makes the card sit *on* something.
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          // **The screenshot, at the size a screenshot deserves.**
          //
          // Full width, cropped from the top. A phone capture is 9:19.5 and
          // its identity lives in the first third — status bar, app header,
          // sender, title, opening line. Cropping to a wide band from the top
          // keeps exactly that and throws away the part that is usually a
          // scroll of body text.
          //
          // `Expanded` rather than a fixed height so the picture takes
          // whatever the card has left after the bar below. The grid sets the
          // card's height in one place; nothing here has to agree with it.
          Expanded(
            child: PressableScale(
              scale: 0.99,
              onTap: onOpen,
              child: SizedBox(
              width: double.infinity,
              child: Image(
                image: AssetEntityImageProvider(
                  screenshot.asset,
                  isOriginal: false,
                  // Landscape, matching the box it lands in. A square source
                  // would be a second crop on top of the one below.
                  thumbnailSize: const ThumbnailSize(600, 380),
                ),
                fit: BoxFit.cover,
                // **Just below the very top, to clear the status bar.**
                //
                // `topCenter` was honest and wrong: the first 4% of a phone
                // screenshot is the clock, the signal bars and the battery —
                // the one strip guaranteed to be identical in every capture,
                // and therefore the one strip that identifies none of them. It
                // was taking a fifth of the visible crop.
                //
                // The number is arithmetic, not taste. `cover` on a 9:19.5
                // source in a ~1.63:1 box shows 28% of the source's height, so
                // the alignment range from -1 to +1 spans the other 72%.
                // Skipping a status bar of ~4.2% is 0.117 of that range:
                // -1 + 0.117 ≈ -0.88.
                //
                // A heuristic, and safe as one: it is a fixed 4% shift, so a
                // picture with no status bar loses 4% off the top rather than
                // anything that matters.
                alignment: const Alignment(0, -0.88),
                gaplessPlayback: true,
              ),
              ),
            ),
          ),

          // **One bar, three jobs, in reading order.**
          //
          // How long it has been waiting, the way out, and the way to finish.
          // These used to be spread across the row with the escape hatch
          // hidden inside the row's own tap — so the screen showed a single
          // visible verdict, and the honest second answer ("filed wrong", "I
          // am never doing this") could only be found by accident.
          SizedBox(
            height: 56.h,
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(16.w, 0, 10.w, 0),
              child: Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      _When.of(context, taken),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall.copyWith(
                        // Past a month it says so in the palette as well as in
                        // the words — the only tint on the card that is not
                        // the photograph, spent on the one fact that should
                        // change what you do next.
                        color: stale ? colors.warning : colors.textPrimary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // A control, not a caption. It looked like one before —
                  // grey text sitting in a row of data — while the thing that
                  // actually performed it was the whole card.
                  PressableScale(
                    scale: 0.94,
                    onTap: onChange,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 8.h,
                      ),
                      child: Text(
                        context.l10n.intentChange,
                        style: context.text.button.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  PressableScale(
                    scale: 0.94,
                    onTap: onDone,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        // Sage, the palette's completion colour — the one hue
                        // in the app that already means *finished*.
                        color: colors.success.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.check_rounded,
                            color: colors.success,
                            size: 16.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            context.l10n.commonDone,
                            style: context.text.button.copyWith(
                              color: colors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the picture full-screen, on the same viewer the rest of the app uses.
///
/// The whole waiting list is handed over rather than the single item, so the
/// viewer's swipe moves between the things still waiting under this verb —
/// which is the set the person is working through. Handing it one screenshot
/// would make this the one place in Shoto where the viewer cannot be swiped.
void _open(BuildContext context, List<ScreenshotEntity> waiting, int index) {
  final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
  Navigator.of(context).push(
    PhotoViewerRoute(
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: ScreenshotDetailPage(screenshots: waiting, initialIndex: index),
      ),
    ),
  );
}

/// Opens the full picker for one row and writes whatever comes back.
///
/// Clearing it is a real outcome here and not an escape hatch: "I am not going
/// to do this" is the honest answer often enough that a list which cannot
/// accept it stops being trusted.
Future<void> _changeIntent(BuildContext context, ScreenshotEntity item) async {
  final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
  final IntentPickerResult? result = await showIntentFullPickerSheet(
    context,
    selected: item.intent?.ref,
  );
  if (result == null) return;
  bloc.add(SetIntentEvent(item.id, result.intent));
}

/// How long a thing has been waiting, in words.
///
/// A date would be accurate and useless — the question this row answers is
/// "have I been sitting on this", and "3 weeks ago" says that where
/// "14/07/2026" makes the reader do arithmetic.
abstract class _When {
  static String of(BuildContext context, DateTime then) {
    final Duration age = DateTime.now().difference(then);
    if (age.inDays >= 30) {
      return context.l10n.dateMonthsAgo((age.inDays / 30).floor());
    }
    if (age.inDays >= 7) {
      return context.l10n.dateWeeksAgo((age.inDays / 7).floor());
    }
    if (age.inDays >= 1) return context.l10n.dateDaysAgo(age.inDays);
    return context.l10n.dateToday;
  }
}
