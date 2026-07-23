import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.textSecondary, size: 32.sp),
            ),
            SizedBox(height: 20.h),
            Text(title, style: AppTextStyles.titleLarge, textAlign: TextAlign.center),
            SizedBox(height: 8.h),
            Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            if (action != null) ...[SizedBox(height: 20.h), action!],
          ],
        ),
      ),
    );
  }
}
