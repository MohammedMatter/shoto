import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/pro_badge.dart';

class HomeGreeting extends StatelessWidget {
  /// The clock this widget reads, overridable from a test and nowhere else.
  ///
  /// This is the only nondeterministic thing on Home, and it is enough to make
  /// a golden that asserts unusable: the same screen says "Good morning",
  /// "Good afternoon" or "Good evening" depending on the hour the suite is
  /// run, so a committed baseline would go red twice a day for no reason.
  ///
  /// A static rather than a constructor argument, because [HomeGreeting] is
  /// built by [HomePage] — threading a parameter down would put a test-only
  /// field on the page's public API to solve a problem that lives here.
  @visibleForTesting
  static DateTime Function()? debugClock;

  const HomeGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    final int hour = (debugClock?.call() ?? DateTime.now()).hour;
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
