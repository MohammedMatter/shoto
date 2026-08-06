import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_new_captures_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/request_photo_permission_use_case.dart';
import 'package:shoto/features/screenshots/presentation/pages/open_triage_page.dart';

class HomeIntake extends StatefulWidget {
  final bool hasLibrary;

  const HomeIntake({super.key, required this.hasLibrary});

  @override
  State<HomeIntake> createState() => _HomeIntakeState();
}

class _HomeIntakeState extends State<HomeIntake> {
  int _waiting = 0;

  @override
  void initState() {
    super.initState();
    _count();
  }

  Future<void> _count() async {
    final List<AssetEntity> captures = await sl<GetNewCapturesUseCase>()();
    if (!mounted) return;
    setState(() => _waiting = captures.length);
  }

  Future<void> _accept() async {
    final PermissionState permission =
        await sl<RequestPhotoPermissionUseCase>()();
    if (!permission.hasAccess) {
      if (!mounted) return;
      await sl<AppPreferences>().setTriageEnabled(false);
      return;
    }

    await sl<AppPreferences>().setTriageEnabled(true);
    if (!mounted) return;
    await openTriagePage(context);
    if (!mounted) return;
    await _count();
  }

  Future<void> _decline() async {
    await sl<AppPreferences>().setTriageEnabled(false);
    if (mounted) setState(() {});
  }

  Future<void> _review() async {
    await openTriagePage(context);
    if (!mounted) return;
    await _count();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<AppPreferences>(),
      builder: (context, _) {
        final AppPreferences prefs = sl<AppPreferences>();

        if (!prefs.triageAsked) {
          if (!widget.hasLibrary) return const SizedBox.shrink();
          return _IntakeInvite(onAccept: _accept, onDecline: _decline);
        }

        if (!prefs.triageEnabled || _waiting == 0) {
          return const SizedBox.shrink();
        }

        return _IntakeQueue(count: _waiting, onTap: _review);
      },
    );
  }
}

class _IntakeInvite extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _IntakeInvite({required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 10.h),
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.triageInviteTitle, style: context.text.titleLarge),
          SizedBox(height: 4.h),
          Text(context.l10n.triageInviteBody, style: context.text.bodySmall),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDecline,
                child: Text(
                  context.l10n.triageInviteDecline,
                  style: context.text.bodyMedium.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: onAccept,
                child: Text(
                  context.l10n.triageInviteAccept,
                  style: context.text.bodyMedium.asMedium.copyWith(
                    color: context.colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntakeQueue extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _IntakeQueue({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 19.sp,
              color: context.colors.textSecondary,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                context.l10n.triageNewCount(count),
                style: context.text.bodyMedium.asMedium,
              ),
            ),
            Text(
              context.l10n.triageReview,
              style: context.text.bodyMedium.copyWith(
                color: context.colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
