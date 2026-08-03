import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';

/// Explains what a rule *is*, before asking anyone to write one.
///
/// The builder was already well made — pick conditions, read the sentence
/// back — and people still could not use it, because it answered "how do I
/// fill this in" while the actual question was "what is this for". A screen
/// that jumps straight to controls assumes a concept the user does not have
/// yet, and no amount of polish on the controls fixes that.
///
/// So this leads with the one-sentence idea and a concrete example, then the
/// three steps, in that order. It is expanded by default the first time (when
/// there are no rules) and collapsible after — an explanation you cannot
/// dismiss becomes clutter the second time you read it.
class RulesExplainer extends StatefulWidget {
  /// Whether it starts open. True when the user has no rules at all: at that
  /// point the explanation *is* the screen's content, not an aside.
  final bool startExpanded;

  const RulesExplainer({super.key, required this.startExpanded});

  @override
  State<RulesExplainer> createState() => _RulesExplainerState();
}

class _RulesExplainerState extends State<RulesExplainer> {
  late bool _open = widget.startExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        // An expand/collapse is the one accepted exception to "never animate
        // a layout property": no transform can reveal content whose height is
        // not known in advance.
        duration: AppMotion.duration(context, AppMotion.normal),
        curve: AppMotion.standard,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PressableScale(
              scale: 0.99,
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.w, 14.h, 14.w, 14.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 11.w),
                    Expanded(
                      child: Text(
                        _open
                            ? context.l10n.rulesTeachHeadline
                            : context.l10n.rulesTeachShow,
                        style: AppTextStyles.titleSmall,
                      ),
                    ),
                    Icon(
                      _open
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 20.sp,
                    ),
                  ],
                ),
              ),
            ),

            if (_open)
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.w, 0, 16.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.rulesTeachIntro,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // The example is set apart from the prose deliberately.
                    // It is the single line most people will actually read,
                    // and it teaches the shape of a rule faster than the
                    // paragraph above it does.
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 13.w,
                        vertical: 11.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(13.r),
                      ),
                      child: Text(
                        context.l10n.rulesTeachExample,
                        style: AppTextStyles.bodySmall.asMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    _Step(
                      icon: Icons.folder_rounded,
                      title: context.l10n.rulesTeachStep1Title,
                      body: context.l10n.rulesTeachStep1Body,
                    ),
                    _Step(
                      icon: Icons.search_rounded,
                      title: context.l10n.rulesTeachStep2Title,
                      body: context.l10n.rulesTeachStep2Body,
                    ),
                    _Step(
                      icon: Icons.auto_awesome_rounded,
                      title: context.l10n.rulesTeachStep3Title,
                      body: context.l10n.rulesTeachStep3Body,
                    ),

                    // Only offered once there are rules to look at instead.
                    // Collapsing this on an otherwise empty screen would
                    // leave the user staring at nothing.
                    if (!widget.startExpanded)
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: PressableScale(
                          scale: 0.94,
                          onTap: () => setState(() => _open = false),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            child: Text(
                              context.l10n.rulesTeachHide,
                              style: AppTextStyles.bodySmall.asMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Step({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 13.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30.w,
            height: 30.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 16.sp, color: AppColors.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                SizedBox(height: 1.h),
                Text(body, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
