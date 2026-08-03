import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/app_snack_bar.dart';
import 'package:shoto/core/widgets/confirm_dialog.dart';
import 'package:shoto/features/settings/presentation/widgets/dev_unlock_dialog.dart';

/// The version line at the bottom of Settings, and the way into developer
/// access: tap it [DevAccess.tapsToReveal] times to be asked for the code.
///
/// Hidden behind a tap streak rather than shown as a switch because it is not
/// a setting anybody should be offered — it hands out every paid feature. The
/// version label is the conventional home for this and reads as decoration
/// until you know otherwise.
class AppVersionBlock extends StatefulWidget {
  const AppVersionBlock({super.key});

  @override
  State<AppVersionBlock> createState() => _AppVersionBlockState();
}

class _AppVersionBlockState extends State<AppVersionBlock> {
  int _taps = 0;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _onTap() {
    if (!DevAccess.enabled) return;

    _resetTimer?.cancel();
    _taps++;

    if (_taps < DevAccess.tapsToReveal) {
      // The streak has to expire, or three taps spread across a week would
      // still add up to an unlock.
      _resetTimer = Timer(DevAccess.tapWindow, () => _taps = 0);
      return;
    }

    _taps = 0;
    Haptics.tap();
    sl<DevAccess>().isUnlocked ? _confirmLock() : _promptUnlock();
  }

  Future<void> _promptUnlock() async {
    final bool unlocked = await showDevUnlockDialog(context);
    if (!unlocked || !mounted) return;

    showAppSnackBar(context, context.l10n.devModeOn, kind: SnackKind.success);
  }

  /// Leaving developer mode has to be as reachable as entering it, otherwise
  /// the paywall and the free-tier limits can never be tested again on this
  /// phone without clearing the app's data.
  Future<void> _confirmLock() async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: context.l10n.devModeOffTitle,
      message: context.l10n.devModeOffBody,
      confirmLabel: context.l10n.devModeOffConfirm,
    );
    if (!confirmed) return;
    await sl<DevAccess>().lock();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<DevAccess>(),
      builder: (context, _) {
        final bool unlocked = sl<DevAccess>().isUnlocked;

        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onTap,
            child: Padding(
              // A comfortable tap target without drawing attention to itself.
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 6.h),
              child: Column(
                children: [
                  Text('SHOTO', style: AppTextStyles.overline),
                  SizedBox(height: 3.h),
                  Text(
                    context.l10n.appVersion('1.0.0'),
                    style: AppTextStyles.caption,
                  ),
                  if (unlocked) ...[
                    SizedBox(height: 9.h),
                    // Visible on purpose: forgetting the override is on is
                    // how you end up convinced a paywall works when it has
                    // simply never run.
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.terminal_rounded,
                            size: 13.sp,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            context.l10n.devModeBadge,
                            style: AppTextStyles.overline.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      context.l10n.devTapToDisable(DevAccess.tapsToReveal),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
