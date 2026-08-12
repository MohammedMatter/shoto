import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:shoto/core/localization/l10n.dart';
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
                : Column(
                    children: <Widget>[
                      // **The falling number, drawn.**
                      //
                      // The finished count used to be a caption under the app
                      // bar title — three words in the smallest type on the
                      // screen, stating the one thing this page exists to
                      // produce. Every other number in Shoto only goes up;
                      // this is the only place a number comes *down*, and a
                      // page built around that moment should show the progress
                      // rather than mention it.
                      //
                      // Only once something has been finished. Before that the
                      // bar would be an empty track reading zero, which frames
                      // the screen as a backlog you are behind on instead of a
                      // list you are about to clear.
                      if (done > 0)
                        _Progress(waiting: waiting.length, done: done),
                      Expanded(
                        child: AnimatedIdGrid<ScreenshotEntity>(
                          items: waiting,
                          idOf: (ScreenshotEntity item) => item.id,
                          padding: EdgeInsetsDirectional.fromSTEB(
                            20.w,
                            4.h,
                            20.w,
                            120.h,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                // **One column, deliberately.** A grid turns
                                // this into another gallery to browse; a list
                                // turns each row into one thing to decide
                                // about, which is what the screen is for.
                                crossAxisCount: 1,
                                mainAxisSpacing: 12.h,
                                mainAxisExtent: 96.h,
                              ),
                          itemBuilder: (context, item, index, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SizeTransition(
                                sizeFactor: animation,
                                child: _WaitingRow(
                                  screenshot: item,
                                  intentLabel: intent.label(context),
                                  onChange: () => _changeIntent(context, item),
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
                        ),
                      ),
                    ],
                  )),
          ),
        );
      },
    );
  }
}

/// How far down the list has come, as a line and a bar.
///
/// **The bar measures the whole job, not what is left.** `done / (done +
/// waiting)` climbs toward full as items are ticked off, so the movement is in
/// the direction of the accomplishment. A bar of what remains would drain
/// instead, and turn finishing something into watching a meter empty.
///
/// Sage rather than the accent, because this is the completion hue everywhere
/// else in the app and this is the one screen entirely about completing.
class _Progress extends StatelessWidget {
  final int waiting;
  final int done;

  const _Progress({required this.waiting, required this.done});

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final int total = waiting + done;
    final double fraction = total == 0 ? 0 : (done / total).clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20.w, 2.h, 20.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            context.l10n.intentDoneCount(done),
            style: context.text.bodySmall.copyWith(color: colors.success),
          ),
          SizedBox(height: 7.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Stack(
              children: <Widget>[
                Container(height: 4.h, color: colors.surfaceVariant),
                // Animated, because this bar only ever moves as a direct
                // result of the user tapping Done — the one place in the app
                // where a progress change is something they just caused, and
                // so the one place watching it move is the reward rather than
                // a distraction.
                AnimatedFractionallySizedBox(
                  duration: AppMotion.reduced(context)
                      ? Duration.zero
                      : AppMotion.sheet,
                  curve: AppMotion.standard,
                  widthFactor: fraction,
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(height: 4.h, color: colors.success),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingRow extends StatelessWidget {
  final ScreenshotEntity screenshot;
  final VoidCallback onDone;

  /// The verb this row is filed under, for the line under the age.
  final String intentLabel;

  /// Re-answers the question for this one.
  ///
  /// The row used to offer exactly one verdict — finished — which is only half
  /// of what a waiting list is for. The other half is realising a thing was
  /// filed wrong, or that you are never going to do it: both are ways of
  /// getting a number down honestly, and without them the only way off this
  /// screen was to claim you had done something you had not.
  final VoidCallback onChange;

  const _WaitingRow({
    required this.screenshot,
    required this.onDone,
    required this.onChange,
    required this.intentLabel,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(scale: 0.98, onTap: onChange, child: _body(context));
  }

  Widget _body(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Fixed-size thumbnail rather than a full-bleed image: these rows
          // are read as a list, and a picture that changes height with its
          // subject makes the list impossible to scan.
          SizedBox(
            width: 96.h,
            height: 96.h,
            child: Image(
              image: AssetEntityImageProvider(
                screenshot.asset,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize.square(300),
              ),
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
          SizedBox(width: 14.w),
          // **The row had one line of grey text in it.**
          //
          // A 108px-tall row whose entire content was "3 weeks ago" at caption
          // weight, floating in the middle of a large gap — most of the row was
          // empty, and the one thing written in it was the quietest type on the
          // screen. The age is not a footnote here: "have I been sitting on
          // this" is the question the row exists to answer, so it is the line
          // that gets read first.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _When.of(context, screenshot.asset.createDateTime),
                  style: context.text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                // What tapping the row does, said rather than discovered. The
                // row's tap opens the intent picker — a destination nobody
                // guesses from a photograph and a date, which left the whole
                // row reading as inert.
                Text(
                  intentLabel,
                  style: context.text.caption.copyWith(
                    color: context.colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Padding(
            padding: EdgeInsetsDirectional.only(end: 12.w),
            child: PressableScale(
              scale: 0.9,
              onTap: onDone,
              // **A word, not a bare tick.**
              //
              // This is the one control on the screen that finishes something,
              // and it sat beside a row whose own tap did something completely
              // different — so the only thing distinguishing "done" from
              // "change what this is" was that one of them was a circle. A
              // labelled button removes the guess, and it fills the space the
              // empty row had going spare.
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
                decoration: BoxDecoration(
                  // Sage, the palette's completion colour — the one hue in the
                  // app that already means *finished*.
                  color: context.colors.success.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.check_rounded,
                      color: context.colors.success,
                      size: 17.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      context.l10n.commonDone,
                      style: context.text.button.copyWith(
                        color: context.colors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
