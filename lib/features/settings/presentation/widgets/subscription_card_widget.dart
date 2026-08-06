import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/features/subscription/domain/entities/premium_feature.dart';
import 'package:shoto/features/subscription/domain/use_cases/restore_purchases_use_case.dart';
import 'package:shoto/features/subscription/presentation/pages/paywall_page.dart';

/// The one card at the top of Settings that says where this account stands.
///
/// It used to own the app's Pro state outright: it asked the repository in
/// `initState` and parked the reply in a **static field**, because Settings is
/// long enough that the card scrolls out of the `ListView`'s cache extent, gets
/// disposed, and rebuilds from nothing on the way back — which meant a fresh
/// platform-channel round trip mid-drag, and a card that rendered the wrong
/// height for a frame and shoved the whole page down.
///
/// All of that now lives in [ProStatus], which is the actual fix rather than a
/// workaround: the answer belongs to the app, not to one widget in a scroll
/// view, and once it belongs to the app the profile card and Home's wordmark
/// can read it too.
class SubscriptionCard extends StatefulWidget {
  const SubscriptionCard({super.key});

  @override
  State<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<SubscriptionCard> {
  bool _isRestoring = false;

  Future<void> _restore() async {
    setState(() => _isRestoring = true);
    try {
      await sl<RestorePurchasesUseCase>()();
    } finally {
      if (mounted) setState(() => _isRestoring = false);
      await sl<ProStatus>().refresh();
    }
  }

  Future<void> _openPaywall() async {
    await Navigator.of(
      context,
    ).push<bool>(FadeSlidePageRoute(builder: (_) => PaywallPage()));
    await sl<ProStatus>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<ProStatus>(),
      builder: (context, _) {
        final ProStatus pro = sl<ProStatus>();

        // Nothing, rather than a guess. "Not known yet" is not "not
        // subscribed", and rendering the upsell on the maybe put an
        // advertisement on a paying customer's own settings screen — then
        // corrected the card's height under their thumb when the truth landed.
        if (pro.status == null) return const SizedBox.shrink();

        return pro.isPro
            ? _ProCard(
                isTesterAccess: pro.isTesterAccess,
                isRestoring: _isRestoring,
                onRestore: _isRestoring ? null : _restore,
              )
            : _UpgradeCard(onTap: _openPaywall);
      },
    );
  }
}

/// Every state of this card, laid out for a golden to photograph.
///
/// The card itself cannot be built in a widget test — it reads [ProStatus] out
/// of the service locator, which needs RevenueCat and a resolved subscription
/// behind it, none of which have anything to say about the layout. Exposing
/// the three arrangements directly is the smaller lie: it tests the pictures,
/// which is all a golden can check anyway.
@visibleForTesting
List<Widget> get debugSubscriptionCardStates => [
  _UpgradeCard(onTap: () {}),
  _ProCard(isRestoring: false, isTesterAccess: false, onRestore: () {}),
  _ProCard(isRestoring: false, isTesterAccess: true, onRestore: null),
];

/// The pill on the upgrade slab.
///
/// It used to appear on both cards. On the Pro card it was the **third** PRO
/// mark within one screen of itself — one on the avatar's ring, one on the name
/// in the profile card directly above, and this one 250px below — and three
/// ways of saying the same thing is not emphasis, it is noise. The profile card
/// is where somebody looks to answer "what account am I on", so the badge stays
/// there and comes off here.
class _ProPill extends StatelessWidget {
  const _ProPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        // Legible *on* the accent rather than made of it.
        color: AppColors.onMarker.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        context.l10n.subPremiumBadge,
        style: AppTextStyles.overline.asSemiBold.copyWith(
          color: AppColors.onMarker,
        ),
      ),
    );
  }
}

/// The free-tier card, which doubles as the pitch.
///
/// **It names the features.** The card already carried the right principle in
/// a comment — "'more' is not a reason to pay" — and then showed four
/// anonymous icon chips, which is exactly "more" drawn as pictures. Nobody
/// recognises a rule engine from a folder glyph. Three real titles and a count
/// of the rest is the same space spent on something a person can actually
/// decide from.
///
/// It is the one deliberately loud surface in Settings, and it is allowed to
/// be: it is a single card, it is the commercial pitch, and it is the same
/// accent fill [PrimaryButton] uses everywhere else.
class _UpgradeCard extends StatelessWidget {
  final VoidCallback onTap;
  const _UpgradeCard({required this.onTap});

  /// Named on the card. Past three the card stops being a pitch and starts
  /// being the "what is included" page, which already exists and is one tap
  /// away.
  static const int _named = 3;

  @override
  Widget build(BuildContext context) {
    final List<PremiumFeature> features = PremiumFeature.all;

    return PressableScale(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 20.h),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _ProPill(),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.onMarker,
                  size: 19.sp,
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              context.l10n.subUnlockEverything,
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.onMarker,
              ),
            ),
            SizedBox(height: 14.h),
            for (final PremiumFeature feature in features.take(_named))
              Padding(
                padding: EdgeInsets.only(bottom: 9.h),
                child: Row(
                  children: [
                    Icon(
                      feature.icon,
                      color: AppColors.onMarker.withValues(alpha: 0.85),
                      size: 15.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        feature.title(context),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onMarker,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            // The total, not "and 4 more" — the string is "{count} features,
            // one plan", which closes the list by saying what the whole thing
            // costs to think about rather than by counting what was left out.
            Text(
              context.l10n.settingsFeatureCount(features.length),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.onMarker.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card somebody who is already paying sees.
///
/// It is the quietest card on the page on purpose, and it took two corrections
/// to get there.
///
/// The first version was a 44px icon, a title and a subtitle in a row — the
/// same shape as the profile card directly above it, so a subscriber's settings
/// screen opened with two near-identical rows and no sense that anything had
/// been earned. The answer to that was a membership card: a full-strength
/// accent ring and every feature icon lit at once.
///
/// That overcorrected. The accent in dark mode is `#EBEBEB`, so "the accent at
/// full strength" is a **bright white ring 1.5px thick around the largest card
/// on the screen** — measured on a device it was the loudest object in Settings
/// by a wide margin, louder than the profile card, the headings, and the page
/// title. And the row of seven unlabelled icons could not say the thing it was
/// there to say: nobody recognises a rule engine from a folder glyph, which is
/// the exact criticism the *upgrade* card's own doc comment makes about
/// anonymous icon chips. It was the mistake this file had already learned once.
///
/// What is left is the part that works. A soft accent edge still says *issued
/// to you* — the only card on the page wearing the accent at all — and the
/// title says the rest in words. Nothing here competes with the pitch card a
/// non-subscriber sees, which is the one surface in Settings that has a reason
/// to be loud.
class _ProCard extends StatelessWidget {
  final bool isRestoring;
  final bool isTesterAccess;
  final VoidCallback? onRestore;

  const _ProCard({
    required this.isRestoring,
    required this.isTesterAccess,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 18.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.r),
        // Half strength and a hairline. Enough to be the only accented edge in
        // Settings; not enough to out-shout the page title. See the note above
        // for why full strength was wrong.
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTesterAccess
                      ? context.l10n.subDevUnlock
                      : context.l10n.subPremiumTitle,
                  style: AppTextStyles.headlineMedium,
                ),
                SizedBox(height: 3.h),
                Text(
                  // Named for what it is. A card claiming a subscription
                  // that was never bought is how you end up shipping a
                  // paywall nobody ever actually saw work.
                  isTesterAccess
                      ? context.l10n.subDevUnlockBody
                      : context.l10n.subPremiumBody,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          // Restoring purchases is meaningless for a local override, and
          // the button would only ever appear to do nothing.
          if (isTesterAccess)
            const SizedBox.shrink()
          else if (isRestoring)
            SizedBox(
              width: 18.w,
              height: 18.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else
            PressableScale(
              scale: 0.85,
              onTap: onRestore,
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: 10.w, top: 2.h),
                child: Icon(
                  Icons.refresh_rounded,
                  color: AppColors.textSecondary,
                  size: 19.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
