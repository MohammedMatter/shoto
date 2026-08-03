import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/premium_gate.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/smart_actions/domain/entities/detected_action.dart';
import 'package:shoto/features/smart_actions/presentation/bloc/smart_actions_cubit.dart';
import 'package:shoto/features/smart_actions/presentation/widgets/action_options.dart';

/// Premium gate + entry point for the actions sheet, matching the shape used
/// by search, duplicates and merging.
Future<void> showSmartActionsSheet(
  BuildContext context,
  ScreenshotEntity screenshot,
) async {
  if (!await ensurePremium(context)) return;
  if (!context.mounted) return;
  await showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => SheetSurface(
      child: BlocProvider(
        create: (_) => SmartActionsCubit(sl())..scan(screenshot),
        child: _Sheet(),
      ),
    ),
  );
}

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(top: 10.h, bottom: 14.h),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Flexible(
              child: BlocBuilder<SmartActionsCubit, SmartActionsState>(
                builder: (context, state) {
                  if (state is SmartActionsErrorState) {
                    return _Message(
                      icon: Icons.error_outline_rounded,
                      title: context.l10n.safeShareUnreadableTitle,
                      body: context.l10n.safeShareUnreadableBody,
                    );
                  }
                  if (state is! SmartActionsLoadedState) {
                    return _Message(
                      icon: Icons.auto_fix_high_rounded,
                      title: context.l10n.actionsWorking,
                      body: context.l10n.actionsWorkingBody,
                      trailing: SizedBox(
                        width: 26.w,
                        height: 26.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }
                  if (state.isEmpty) {
                    return _Message(
                      icon: Icons.search_off_rounded,
                      title: context.l10n.actionsNoneTitle,
                      body: context.l10n.actionsNoneBody,
                    );
                  }
                  return _Results(actions: state.actions);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  final List<DetectedAction> actions;
  const _Results({required this.actions});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
      itemCount: actions.length,
      separatorBuilder: (_, _) =>
          Divider(height: 24.h, thickness: 1, color: AppColors.border),
      itemBuilder: (context, index) => _ActionRow(action: actions[index]),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final DetectedAction action;
  const _ActionRow({required this.action});

  Future<void> _run(BuildContext context, ActionOption option) async {
    Haptics.tap();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);
    // Resolved before the await for the same reason the two above are: after
    // it the widget may be gone, and reading a translation is reading the
    // tree.
    final String noAppMessage = context.l10n.actionsNoApp;
    final String copiedMessage = context.l10n.actionsCopied;

    final bool handled = await option.run();
    if (!handled) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(noAppMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (option.icon == Icons.copy_rounded) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(copiedMessage),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
    // Leaving for another app, or having copied, means this sheet has done
    // its job — keeping it open would just be in the way on return.
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(action.icon, size: 17.sp, color: AppColors.primary),
            SizedBox(width: 8.w),
            Text(action.kindLabel(context), style: AppTextStyles.caption),
          ],
        ),
        SizedBox(height: 6.h),
        SelectableText(
          action.display,
          // A code or an account number gets read digit by digit, and a
          // proportional font makes that unnecessarily hard.
          style:
              action.kind == DetectedActionKind.iban ||
                  action.kind == DetectedActionKind.code
              ? AppTextStyles.monoBody.asSemiBold
              : AppTextStyles.bodyLarge.asSemiBold,
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final ActionOption option in action.options(context))
              _OptionChip(option: option, onTap: () => _run(context, option)),
          ],
        ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  final ActionOption option;
  final VoidCallback onTap;

  const _OptionChip({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.94,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 9.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(option.icon, size: 15.sp, color: AppColors.textPrimary),
              SizedBox(width: 6.w),
              Text(
                option.label,
                style: AppTextStyles.bodySmall.asMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? trailing;

  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(28.w, 12.h, 28.w, 36.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          trailing ?? Icon(icon, size: 30.sp, color: AppColors.textSecondary),
          SizedBox(height: 14.h),
          Text(
            title,
            style: AppTextStyles.titleLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),
          Text(
            body,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
