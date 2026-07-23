import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/routes/app_router.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/confirm_dialog.dart';
import 'package:shoto/features/auth/domain/entities/user_entity.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';
import 'package:shoto/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shoto/features/auth/presentation/bloc/auth_event.dart';
import 'package:shoto/features/auth/presentation/bloc/auth_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final UserEntity? user = sl<AuthRepository>().currentUser;

    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSignedOutState) {
            context.goNamed(AppRouter.authPage);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 120.h),
              children: [
                Text('Settings', style: AppTextStyles.headlineLarge),
                SizedBox(height: 20.h),
                _ProfileCard(user: user),
                SizedBox(height: 28.h),
                Text(
                  'ACCOUNT',
                  style: AppTextStyles.caption.copyWith(letterSpacing: 1.1),
                ),
                SizedBox(height: 8.h),
                Builder(
                  builder: (context) => _SettingsTile(
                    icon: Icons.logout_rounded,
                    label: 'Sign out',
                    isDestructive: true,
                    onTap: () async {
                      final bool confirmed = await showConfirmDialog(
                        context,
                        title: 'Sign out?',
                        message:
                            "You'll need to sign in again to access your screenshots.",
                        confirmLabel: 'Sign out',
                        isDestructive: true,
                      );
                      if (confirmed && context.mounted) {
                        context.read<AuthBloc>().add(SignOutRequestedEvent());
                      }
                    },
                  ),
                ),
                SizedBox(height: 40.h),
                Center(
                  child: Text('SHOTO · v1.0.0', style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserEntity? user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28.r,
            backgroundColor: AppColors.surfaceVariant,
            backgroundImage: (user?.photoUrl != null)
                ? NetworkImage(user!.photoUrl!)
                : null,
            child: user?.photoUrl == null
                ? Icon(
                    Icons.person_rounded,
                    color: AppColors.textSecondary,
                    size: 26.sp,
                  )
                : null,
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (user?.name?.isNotEmpty ?? false)
                      ? user!.name!
                      : 'SHOTO user',
                  style: AppTextStyles.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user?.email != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    user!.email!,
                    style: AppTextStyles.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20.sp),
              SizedBox(width: 14.w),
              Text(
                label,
                style: AppTextStyles.bodyLarge.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
