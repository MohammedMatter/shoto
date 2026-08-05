import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/content_traits.dart';
import 'package:shoto/features/screenshots/presentation/widgets/content_trait_visuals.dart';

/// A line under the filter strip saying **where the active lens's answer came
/// from, and what it cannot see.**
///
/// This is the feature's honesty mechanism, and it is not optional decoration.
/// Every trait except `sensitive` is read out of text OCR recovered from a
/// picture, which means the failure mode is silent: the grid shows four
/// screenshots and looks complete, while the ones nobody has ever run
/// recognition over are simply absent. Without this line an empty or short
/// result reads as "you have none of these", which is a claim the app has no
/// basis to make.
///
/// It states two separate things because they can be wrong independently:
/// how the match was established (a checksum, or a reading), and how much of
/// the library has been read at all.
///
/// Same reasoning as `RuleSummary.describe` — the readback *is* the trust
/// mechanism. A filter nobody can check is a filter nobody should believe.
class LensProvenanceNote extends StatelessWidget {
  /// The active lens, or null when the grid is unfiltered by content.
  final ContentTrait? lens;

  /// Screenshots whose text has never been recognised — invisible to any lens.
  final int unreadCount;

  const LensProvenanceNote({
    super.key,
    required this.lens,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final ContentTrait? active = lens;

    // Sized rather than merely faded: the grid below must close the gap when
    // the lens is cleared, or the row leaves a hole where an explanation used
    // to be. Short — this sits directly above content the user is reading.
    return AnimatedSize(
      duration: AppMotion.duration(context, AppMotion.instant),
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: active == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: EdgeInsetsDirectional.fromSTEB(20.w, 0, 20.w, 10.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    active.certaintyIcon,
                    size: 13.sp,
                    // Verified detections earn the accent; a reading is
                    // reported in the same muted grey as any other caption,
                    // so the stronger claim is the one that stands out.
                    color: active.certainty == TraitCertainty.verified
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      // Two facts, joined only when the second applies. An
                      // unread count of zero means the lens really has seen
                      // everything, and saying so in a sentence about what it
                      // might have missed would undersell a complete answer.
                      unreadCount > 0
                          ? context.l10n.libraryLensNoteWithUnread(
                              active.certaintyNote(context),
                              unreadCount,
                            )
                          : active.certaintyNote(context),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
