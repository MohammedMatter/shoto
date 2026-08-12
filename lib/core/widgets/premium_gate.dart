import 'package:flutter/material.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/services/feature_trials.dart';
import 'package:shoto/core/widgets/app_snack_bar.dart';
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
/// Returns true when the caller may proceed: the user is already premium, they
/// spent a free trial here, or they subscribed on the paywall this presented.
///
/// ## The order of the three checks is the whole design
///
/// A subscription is asked about **first**, so a subscriber never burns a
/// trial they had no use for — and the counter still reads full if they ever
/// lapse. The trial comes second, so a free user meets the feature rather than
/// the price. The paywall is last, and only once there is genuinely nothing
/// left to give.
Future<bool> ensurePremium(BuildContext context, {FeatureTrial? trial}) async {
  final SubscriptionStatus status = await sl<GetSubscriptionStatusUseCase>()();
  if (status.isPremium) return true;

  // Spent here rather than by the caller, so "the trial was used" and "the
  // feature actually opened" can never come apart. A gate that returns true
  // without charging, or charges without returning true, is the same class of
  // bug the single implementation above exists to prevent.
  if (trial != null && await sl<FeatureTrials>().consume(trial)) {
    if (context.mounted) {
      // Said plainly, and only at the moment it is spent. Somebody handed a
      // paid feature with no explanation assumes the app is broken or that
      // they have been charged; "this one is on us" tells them both what they
      // are getting and that it will not repeat.
      showAppSnackBar(context, context.l10n.trialUsed, kind: SnackKind.success);
    }
    return true;
  }

  if (!context.mounted) return false;
  final bool? purchased = await Navigator.of(
    context,
  ).push<bool>(FadeSlidePageRoute(builder: (_) => const PaywallPage()));

  return purchased == true && context.mounted;
}
