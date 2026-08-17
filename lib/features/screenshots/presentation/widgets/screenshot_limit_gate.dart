import 'package:flutter/material.dart';
import 'package:shoto/core/constants/subscription_constants.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_managed_screenshot_count_use_case.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/use_cases/get_subscription_status_use_case.dart';
import 'package:shoto/features/subscription/presentation/pages/paywall_page.dart';

/// Checks the free tier's one cap — [SubscriptionConstants.freeScreenshotLimit]
/// screenshots — before an action would bring [additionalNewItems]
/// not-yet-managed screenshots under management
/// (favorited or filed into a folder for the first time). Already-managed
/// screenshots stay freely editable — pass 0 for those.
///
/// Returns true if the action should proceed (under the cap, already
/// premium, or the user just purchased from the paywall shown here).
Future<bool> ensureUnderScreenshotLimit(
  BuildContext context, {
  required int additionalNewItems,
}) async {
  if (additionalNewItems <= 0) return true;

  final int managedCount = await sl<GetManagedScreenshotCountUseCase>()();
  if (managedCount + additionalNewItems <=
      SubscriptionConstants.freeScreenshotLimit) {
    return true;
  }

  final SubscriptionStatus status = await sl<GetSubscriptionStatusUseCase>()();
  if (status.isPremium) return true;

  if (!context.mounted) return false;
  final bool? purchased = await Navigator.of(
    context,
  ).push<bool>(FadeSlidePageRoute(builder: (_) => const PaywallPage()));
  return purchased == true;
}
