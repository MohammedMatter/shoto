import 'package:flutter/material.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/use_cases/get_subscription_status_use_case.dart';
import 'package:shoto/features/subscription/presentation/pages/paywall_page.dart';

/// The one place that decides whether a paid feature may open.
///
/// Every premium entry point used to repeat this check by hand, and the
/// condition had been written inverted in more than one of them — the
/// paywall was shown to subscribers while free users walked straight in.
/// That is the kind of mistake that only ever gets found in production, and
/// it is impossible to make once there is a single implementation of it.
///
/// Returns true when the caller may proceed: either the user is already
/// premium, or they just subscribed on the paywall this call presented.
Future<bool> ensurePremium(BuildContext context) async {
  final SubscriptionStatus status = await sl<GetSubscriptionStatusUseCase>()();
  if (status.isPremium) return true;

  if (!context.mounted) return false;
  final bool? purchased = await Navigator.of(
    context,
  ).push<bool>(FadeSlidePageRoute(builder: (_) => const PaywallPage()));

  return purchased == true && context.mounted;
}
