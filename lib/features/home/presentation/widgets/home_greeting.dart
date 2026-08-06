import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/pro_badge.dart';

class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    final int hour = DateTime.now().hour;
    final String part = hour < 12
        ? context.l10n.homeGreetingMorning
        : hour < 18
        ? context.l10n.homeGreetingAfternoon
        : context.l10n.homeGreetingEvening;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(part, style: context.text.bodyMedium),
              SizedBox(height: 1.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'SHOTO',
                    style: context.text.headlineLarge.copyWith(
                      color: context.colors.textPrimary,
                      letterSpacing: -1,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  const ProBadgeIfSubscribed(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
