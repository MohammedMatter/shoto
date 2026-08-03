import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/widgets/asset_thumbnail_image.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/byte_formatter.dart';
import 'package:shoto/features/duplicates/domain/entities/duplicate_group.dart';

class DuplicateGroupCard extends StatelessWidget {
  final DuplicateGroup group;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onKeepAll;
  final VoidCallback onResetSelection;

  const DuplicateGroupCard({
    super.key,
    required this.group,
    required this.selectedIds,
    required this.onToggle,
    required this.onKeepAll,
    required this.onResetSelection,
  });

  @override
  Widget build(BuildContext context) {
    final int selectedInGroup = group.candidates
        .where((candidate) => selectedIds.contains(candidate.id))
        .length;
    final bool nothingSelected = selectedInGroup == 0;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.dupSimilarCopies(group.candidates.length),
                      style: AppTextStyles.titleLarge,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      nothingSelected
                          ? context.l10n.dupKeepingAll
                          : context.l10n.dupFrees(
                              formatBytes(_selectedBytes()),
                            ),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: nothingSelected
                            ? AppColors.secondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: nothingSelected ? onResetSelection : onKeepAll,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  nothingSelected
                      ? context.l10n.dupUndo
                      : context.l10n.dupKeepAll,
                  style: AppTextStyles.bodySmall.asMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 132.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: group.candidates.length,
              separatorBuilder: (_, _) => SizedBox(width: 10.w),
              itemBuilder: (context, index) {
                final DuplicateCandidate candidate = group.candidates[index];
                return _CandidateTile(
                  candidate: candidate,
                  isMarkedForDeletion: selectedIds.contains(candidate.id),
                  isSuggestedKeeper: candidate.id == group.suggestedKeeperId,
                  onTap: () => onToggle(candidate.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _selectedBytes() => group.candidates
      .where((candidate) => selectedIds.contains(candidate.id))
      .fold(0, (sum, candidate) => sum + candidate.fileSizeBytes);
}

class _CandidateTile extends StatelessWidget {
  final DuplicateCandidate candidate;
  final bool isMarkedForDeletion;
  final bool isSuggestedKeeper;
  final VoidCallback onTap;

  const _CandidateTile({
    required this.candidate,
    required this.isMarkedForDeletion,
    required this.isSuggestedKeeper,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.95,
      onTap: onTap,
      child: SizedBox(
        width: 92.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14.r),
                    child: AssetThumbnailImage(
                      asset: candidate.screenshot.asset,
                    ),
                  ),
                  // Dim copies that are about to be deleted so the ones
                  // being kept visually stand out.
                  //
                  // Faded rather than inserted: marking a copy for deletion
                  // is the whole interaction on this screen, and it used to
                  // happen between two frames — the tile went dark, its ring
                  // went red and its badge became a bin all at once, with no
                  // sense that one tap caused it.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14.r),
                    child: AnimatedOpacity(
                      opacity: isMarkedForDeletion ? 1 : 0,
                      duration: AppMotion.duration(context, AppMotion.press),
                      curve: AppMotion.standard,
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: AppMotion.duration(context, AppMotion.press),
                      curve: AppMotion.standard,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: isMarkedForDeletion
                              ? AppColors.error
                              : AppColors.secondary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6.h,
                    right: 6.w,
                    child: AnimatedContainer(
                      duration: AppMotion.duration(context, AppMotion.press),
                      curve: AppMotion.standard,
                      width: 22.w,
                      height: 22.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isMarkedForDeletion
                            ? AppColors.error
                            : AppColors.secondary,
                      ),
                      child: AnimatedSwitcher(
                        duration: AppMotion.duration(context, AppMotion.press),
                        switchInCurve: AppMotion.standard,
                        switchOutCurve: AppMotion.standard,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            // From 0.6 — a glyph that grows from a point
                            // inside a 22px circle reads as a rendering
                            // artefact rather than as a symbol changing.
                            scale: Tween<double>(
                              begin: 0.6,
                              end: 1,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Icon(
                          isMarkedForDeletion
                              ? Icons.delete_outline_rounded
                              : Icons.check_rounded,
                          key: ValueKey<bool>(isMarkedForDeletion),
                          color: AppColors.onPrimary,
                          size: 14.sp,
                        ),
                      ),
                    ),
                  ),
                  if (isSuggestedKeeper && !isMarkedForDeletion)
                    Positioned(
                      left: 6.w,
                      bottom: 6.h,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          context.l10n.dupBest,
                          style: AppTextStyles.caption.asSemiBold.copyWith(
                            color: AppColors.onPrimary,
                            fontSize: 8.sp,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              formatBytes(candidate.fileSizeBytes),
              style: AppTextStyles.caption,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
