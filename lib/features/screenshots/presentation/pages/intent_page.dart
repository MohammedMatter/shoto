import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
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

/// Everything still waiting under one intent, and one gesture to finish it.
///
/// **This is the screen the whole feature exists for.** Every other number in
/// SHOTO only goes up — screenshots, folders, unsorted. This is the one place
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
        final List<ScreenshotEntity> waiting = state is ScreenshotsLoadedState
            ? state.waitingFor(intent)
            : const <ScreenshotEntity>[];
        final int done = state is ScreenshotsLoadedState
            ? state.doneFor(intent)
            : 0;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  intent.waitingTitle(context),
                  style: AppTextStyles.titleLarge,
                ),
                // The finished count sits under the title rather than in the
                // list. It is the reward for having used the screen, and it
                // would be noise anywhere it competed with what is still to do.
                if (done > 0)
                  Text(
                    context.l10n.intentDoneCount(done),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                    ),
                  ),
              ],
            ),
          ),
          body: SafeArea(
            child: waiting.isEmpty
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
                      120.h,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      // **One column, deliberately.** A grid turns this
                      // into another gallery to browse; a list turns each
                      // row into one thing to decide about, which is what
                      // the screen is for.
                      crossAxisCount: 1,
                      mainAxisSpacing: 12.h,
                      mainAxisExtent: 108.h,
                    ),
                    itemBuilder: (context, item, index, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SizeTransition(
                          sizeFactor: animation,
                          child: _WaitingRow(
                            screenshot: item,
                            onChange: () => _changeIntent(context, item),
                            onDone: () {
                              // Fires before the row leaves, so the feedback
                              // and the movement are one event rather than a
                              // buzz followed by a disappearance.
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
        );
      },
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

  const _WaitingRow({
    required this.screenshot,
    required this.onDone,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.98,
      onTap: onChange,
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Fixed-size thumbnail rather than a full-bleed image: these rows
          // are read as a list, and a picture that changes height with its
          // subject makes the list impossible to scan.
          SizedBox(
            width: 108.h,
            height: 108.h,
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
          Expanded(
            child: Text(
              _When.of(context, screenshot.asset.createDateTime),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(end: 12.w),
            child: PressableScale(
              scale: 0.88,
              onTap: onDone,
              child: Container(
                width: 46.w,
                height: 46.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  // Sage, the palette's completion colour — the one hue in the
                  // app that already means *finished*.
                  color: AppColors.success.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: AppColors.success,
                  size: 24.sp,
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
