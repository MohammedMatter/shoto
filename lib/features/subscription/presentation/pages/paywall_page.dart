import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/constants/subscription_constants.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/core/widgets/shoto_logo.dart';
import 'package:shoto/features/subscription/domain/entities/premium_feature.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_package_info.dart';
import 'package:shoto/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:shoto/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:shoto/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:shoto/features/subscription/presentation/pages/pro_welcome_page.dart';
import 'package:shoto/features/subscription/presentation/widgets/subscription_package_card.dart';

/// Pushed whenever a free-tier limit is hit (see FoldersPage) or opened
/// directly from Settings. Purchases only actually work once real
/// subscription products exist behind [SubscriptionConstants] — until then
/// this renders the intended pricing but the "Continue" button explains
/// that subscriptions aren't live yet instead of crashing.
class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  bool _selectedYearly = true;

  /// Runs the welcome screen, then closes the paywall reporting success.
  ///
  /// `context` is captured before the `await` and re-checked after it, because
  /// this is a bloc listener: the widget can be gone by the time the welcome
  /// screen is dismissed, and popping a dead Navigator throws.
  Future<void> _celebrate(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    await showProWelcome(context);
    if (navigator.mounted) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SubscriptionBloc>()..add(LoadOfferingsEvent()),
      child: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state is SubscriptionPurchaseSuccessState) {
            // Celebrated **here**, in the paywall itself, rather than at the
            // places that open it. The paywall is pushed from `ensurePremium`
            // — which is called from the folder cap, the screenshot cap,
            // Duplicates and Settings — so hanging the welcome screen off each
            // caller would mean remembering it at every one of them and
            // getting it wrong at one. This is the single point every purchase
            // passes through.
            _celebrate(context);
          } else if (state is SubscriptionLoadedState &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!.resolve(context)),
                  backgroundColor: AppColors.error,
                ),
              );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: state is SubscriptionErrorState
                  ? _ErrorBody(message: state.message.resolve(context))
                  : _PaywallBody(
                      state: state,
                      selectedYearly: _selectedYearly,
                      onSelect: (isYearly) =>
                          setState(() => _selectedYearly = isYearly),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  const _ErrorBody({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.commonClose),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaywallBody extends StatelessWidget {
  final SubscriptionState state;
  final bool selectedYearly;
  final ValueChanged<bool> onSelect;

  const _PaywallBody({
    required this.state,
    required this.selectedYearly,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLoading = state is SubscriptionLoadingState;
    final List<SubscriptionPackageInfo> packages =
        state is SubscriptionLoadedState
        ? (state as SubscriptionLoadedState).packages
        : const [];
    final bool isPurchasing =
        state is SubscriptionLoadedState &&
        (state as SubscriptionLoadedState).isPurchasing;
    final bool offeringsLive = packages.isNotEmpty;

    final SubscriptionPackageInfo? monthly = packages
        .where((p) => !p.isYearly)
        .cast<SubscriptionPackageInfo?>()
        .firstWhere((_) => true, orElse: () => null);
    final SubscriptionPackageInfo? yearly = packages
        .where((p) => p.isYearly)
        .cast<SubscriptionPackageInfo?>()
        .firstWhere((_) => true, orElse: () => null);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 140.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Center(child: ShotoLogo(size: 60)),
              SizedBox(height: 18.h),
              Text(
                context.l10n.paywallTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineLarge,
              ),
              SizedBox(height: 6.h),
              Text(
                context.l10n.paywallSubtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              SizedBox(height: 24.h),
              // The full, honest list. Someone hitting this screen has just
              // been stopped from doing something; the least it can do is
              // show them exactly what they would be getting rather than
              // three vague bullet points.
              for (final PremiumFeature feature in PremiumFeature.all) ...[
                _FeatureRow(feature: feature),
                SizedBox(height: 14.h),
              ],
              SizedBox(height: 10.h),
              if (isLoading)
                Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              else ...[
                SubscriptionPackageCard(
                  title: context.l10n.paywallYearly,
                  priceString:
                      yearly?.priceString ??
                      SubscriptionConstants.yearlyFallbackPrice,
                  periodLabel: '/year',
                  badgeLabel: 'Save 73%',
                  isSelected: selectedYearly,
                  onTap: () => onSelect(true),
                ),
                SizedBox(height: 12.h),
                SubscriptionPackageCard(
                  title: context.l10n.paywallMonthly,
                  priceString:
                      monthly?.priceString ??
                      SubscriptionConstants.monthlyFallbackPrice,
                  periodLabel: '/month',
                  isSelected: !selectedYearly,
                  onTap: () => onSelect(false),
                ),
                if (!offeringsLive) ...[
                  SizedBox(height: 12.h),
                  Text(
                    "Subscriptions aren't live yet — pricing shown for preview.",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
              SizedBox(height: 20.h),
              Text(
                context.l10n.paywallLegal,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
            decoration: BoxDecoration(gradient: AppColors.scrimGradient),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryButton(
                  label: offeringsLive
                      ? context.l10n.paywallContinue
                      : context.l10n.paywallUnavailable,
                  isLoading: isPurchasing,
                  onPressed: !offeringsLive
                      ? () => ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Subscriptions aren't set up yet — check back soon.",
                              ),
                            ),
                          )
                      : () {
                          final SubscriptionPackageInfo? chosen = selectedYearly
                              ? yearly
                              : monthly;
                          if (chosen == null) return;
                          context.read<SubscriptionBloc>().add(
                            PurchasePackageEvent(chosen),
                          );
                        },
                ),
                SizedBox(height: 8.h),
                TextButton(
                  onPressed: isPurchasing
                      ? null
                      : () => context.read<SubscriptionBloc>().add(
                          RestorePurchasesEvent(),
                        ),
                  child: Text(
                    context.l10n.paywallRestore,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final PremiumFeature feature;
  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: Icon(feature.icon, color: AppColors.primary, size: 18.sp),
        ),
        SizedBox(width: 13.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(feature.title(context), style: AppTextStyles.titleSmall),
              SizedBox(height: 2.h),
              Text(
                feature.description(context),
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
