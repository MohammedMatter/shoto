import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/constants/subscription_constants.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/core/widgets/privacy_note.dart';
import 'package:shoto/features/subscription/domain/entities/premium_feature.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/use_cases/get_subscription_status_use_case.dart';
import 'package:shoto/features/subscription/presentation/pages/paywall_page.dart';

/// Opens [WhatsIncludedPage].
///
/// Deliberately **not** gated behind [ensurePremium], which is what the
/// Settings row used to call. That check does nothing for a subscriber — it
/// returns true and the row silently did nothing at all — and for everybody
/// else it answered "what do I get?" by pushing a price at them. This page is
/// the answer to the question that was asked; the offer comes after it.
Future<void> openWhatsIncludedPage(BuildContext context) {
  return Navigator.of(
    context,
  ).push(FadeSlidePageRoute(builder: (_) => const WhatsIncludedPage()));
}

/// The long-form answer to "what is included": every premium feature, each one
/// expandable into what it actually does and three things it genuinely can do.
///
/// One card open at a time. An accordion rather than free expansion because
/// seven open cards is a wall of prose — and the point of this screen is that
/// somebody can read *one* feature properly and decide.
class WhatsIncludedPage extends StatefulWidget {
  const WhatsIncludedPage({super.key});

  @override
  State<WhatsIncludedPage> createState() => _WhatsIncludedPageState();
}

class _WhatsIncludedPageState extends State<WhatsIncludedPage> {
  SubscriptionStatus? _status;

  /// Which feature is expanded, or null. See the class doc for why it is one
  /// index rather than a set.
  int? _openIndex;

  /// Stamped once so the entrance stagger runs on first paint and never
  /// again — see [EntranceStagger].
  final DateTime _builtAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    sl<GetSubscriptionStatusUseCase>()().then((SubscriptionStatus status) {
      if (!mounted) return;
      setState(() => _status = status);
    });
  }

  Future<void> _openPaywall() async {
    await Navigator.of(
      context,
    ).push<bool>(FadeSlidePageRoute(builder: (_) => const PaywallPage()));
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final SubscriptionStatus? status = _status;

    // Until the answer arrives the page is neither "yours" nor "for sale", so
    // it claims neither: the strip and the bottom bar are the only two things
    // that depend on it, and both simply wait. Guessing here would flash an
    // upsell at somebody who is already paying.
    final bool? isPremium = status?.isPremium;

    return ListenableBuilder(
      listenable: sl<ThemeController>(),
      builder: (context, _) => Scaffold(
        backgroundColor: context.colors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        20.w,
                        6.h,
                        20.w,
                        // Room for the unlock bar, which floats over the list
                        // rather than sitting under it — a page whose last
                        // card is half-covered reads as broken.
                        isPremium == false ? 130.h : 34.h,
                      ),
                      children: [
                        if (status != null) ...[
                          _StatusStrip(status: status),
                          SizedBox(height: 18.h),
                        ],

                        Padding(
                          padding: EdgeInsetsDirectional.only(start: 2.w),
                          child: Text(
                            context.l10n.includedHint,
                            style: context.text.sectionLabel,
                          ),
                        ),
                        SizedBox(height: 10.h),

                        for (int i = 0; i < PremiumFeature.all.length; i++) ...[
                          EntranceStagger(
                            index: i,
                            since: _builtAt,
                            child: _FeatureCard(
                              feature: PremiumFeature.all[i],
                              isOpen: _openIndex == i,
                              onTap: () => setState(
                                () => _openIndex = _openIndex == i ? null : i,
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),
                        ],

                        if (isPremium == false) ...[
                          SizedBox(height: 8.h),
                          const _FreeTierNote(),
                        ],

                        SizedBox(height: 16.h),
                        const PrivacyNote(),
                      ],
                    ),

                    if (isPremium == false)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsetsDirectional.fromSTEB(
                            20.w,
                            20.h,
                            20.w,
                            20.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: context.colors.scrimGradient,
                          ),
                          child: SafeArea(
                            top: false,
                            child: PrimaryButton(
                              label: context.l10n.subUnlockEverything,
                              onPressed: _openPaywall,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(12.w, 8.h, 20.w, 6.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: context.colors.textPrimary,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.settingsWhatsIncluded,
                  style: context.text.headlineMedium,
                ),
                Text(
                  context.l10n.includedSubtitle,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One line about where the reader stands, and nothing more.
///
/// For a subscriber it confirms the features below are theirs. For everyone
/// else it says so plainly and then gets out of the way — the actual offer is
/// the bar at the bottom, and putting a second one up here would turn an
/// explanation into a sales page.
class _StatusStrip extends StatelessWidget {
  final SubscriptionStatus status;

  const _StatusStrip({required this.status});

  @override
  Widget build(BuildContext context) {
    final bool premium = status.isPremium;
    final bool dev = status.isTesterAccess;

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(14.w, 13.h, 14.w, 13.h),
      decoration: BoxDecoration(
        color: premium
            ? context.colors.success.withValues(alpha: 0.1)
            : context.colors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: premium
              ? context.colors.success.withValues(alpha: 0.3)
              : context.colors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            premium
                ? (dev ? Icons.terminal_rounded : Icons.check_circle_rounded)
                : Icons.lock_outline_rounded,
            color: premium
                ? context.colors.success
                : context.colors.textSecondary,
            size: 19.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  premium
                      ? (dev
                            ? context.l10n.subDevUnlock
                            : context.l10n.includedActiveTitle)
                      : context.l10n.includedLockedTitle,
                  style: context.text.titleSmall,
                ),
                SizedBox(height: 2.h),
                Text(
                  premium
                      ? (dev
                            ? context.l10n.subDevUnlockBody
                            : context.l10n.includedActiveBody)
                      : context.l10n.includedLockedBody,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One feature: always its name and one-line claim, and on tap the paragraph
/// behind the claim plus three things it can actually do.
class _FeatureCard extends StatefulWidget {
  final PremiumFeature feature;
  final bool isOpen;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.feature,
    required this.isOpen,
    required this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  @override
  void didUpdateWidget(_FeatureCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isOpen && widget.isOpen) _revealAfterExpanding();
  }

  /// Scrolls the card back into view once it has finished growing.
  ///
  /// Without this, opening one of the last cards drops most of what was just
  /// revealed below the fold — the reader taps to read something and has to
  /// go find it. Waiting for [AnimatedSize] to settle first is what makes the
  /// scroll land in the right place: measured mid-animation, the card is
  /// still the wrong height.
  void _revealAfterExpanding() {
    final Duration grow = AppMotion.duration(context, AppMotion.normal);
    Future<void>.delayed(grow + const Duration(milliseconds: 20), () {
      if (!mounted || !widget.isOpen) return;
      Scrollable.ensureVisible(
        context,
        duration: AppMotion.duration(context, AppMotion.sheet),
        curve: AppMotion.standard,
        // The card grows downwards, so the *bottom* is the edge that leaves
        // the screen. Anything taller than the viewport still keeps its
        // header visible, which is where the reading starts.
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool open = widget.isOpen;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          // The open card is the one being read; a slightly firmer edge is
          // enough to say so without tinting the whole surface.
          color: open
              ? context.colors.primary.withValues(alpha: 0.35)
              : context.colors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        // The one accepted exception to "never animate a layout property":
        // no transform can reveal content whose height isn't known up front.
        duration: AppMotion.duration(context, AppMotion.normal),
        curve: AppMotion.standard,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PressableScale(
              // A tint rather than a shrink: this is a full-width row inside a
              // scrolling page, and seven cards that flinch as a finger passes
              // over them make the page look like it shuddered. See
              // PressFeedback.
              feedback: PressFeedback.highlight,
              onTap: widget.onTap,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(15.w, 15.h, 12.w, 15.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: AppMotion.duration(context, AppMotion.normal),
                      curve: AppMotion.standard,
                      width: 40.w,
                      height: 40.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        // Fills with the accent while open — the same
                        // inversion the app uses for a selected chip, so the
                        // open card is legible at a glance on a page of seven.
                        color: open
                            ? context.colors.primary
                            : context.colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(13.r),
                      ),
                      child: Icon(
                        widget.feature.icon,
                        size: 19.sp,
                        color: open
                            ? context.colors.onPrimary
                            : context.colors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 13.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.feature.title(context),
                            style: context.text.titleSmall,
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            widget.feature.description(context),
                            style: context.text.bodySmall,
                            // Clamped while closed so seven cards stay a list
                            // you can scan rather than seven paragraphs.
                            maxLines: open ? null : 2,
                            overflow: open
                                ? TextOverflow.clip
                                : TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: AnimatedRotation(
                        turns: open ? 0.5 : 0,
                        duration: AppMotion.duration(context, AppMotion.normal),
                        curve: AppMotion.standard,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: context.colors.textSecondary,
                          size: 21.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (open) _FeatureDetail(feature: widget.feature),
          ],
        ),
      ),
    );
  }
}

class _FeatureDetail extends StatelessWidget {
  final PremiumFeature feature;
  const _FeatureDetail({required this.feature});

  @override
  Widget build(BuildContext context) {
    // Fades in as the card grows. [AnimatedSize] alone reveals by clipping,
    // which slides the text up from behind the edge; the fade is what turns
    // that into the content arriving rather than the card scrolling.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.duration(context, AppMotion.normal),
      curve: AppMotion.standard,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(15.w, 0, 15.w, 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 1, color: context.colors.border),
            SizedBox(height: 14.h),
            Text(context.l10n.includedHowLabel, style: context.text.overline),
            SizedBox(height: 6.h),
            Text(
              feature.how(context),
              style: context.text.bodySmall.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            SizedBox(height: 14.h),
            for (final String Function(BuildContext) point in feature.points)
              _Point(text: point(context)),
          ],
        ),
      ),
    );
  }
}

/// One checkable specific.
///
/// The tick is drawn in the accent rather than in [AppPalette.success]: green
/// means *finished* everywhere else in this app, and a list of things the
/// feature can do is not a list of things that have happened.
class _Point extends StatelessWidget {
  final String text;
  const _Point({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 9.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            // Nudged down onto the first line's baseline rather than its box.
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(
              Icons.check_rounded,
              size: 15.sp,
              color: context.colors.primary,
            ),
          ),
          SizedBox(width: 9.w),
          Expanded(child: Text(text, style: context.text.bodySmall)),
        ],
      ),
    );
  }
}

/// What somebody keeps if they never pay.
///
/// Shown only to free users, and shown *after* the seven cards on purpose: a
/// page that lists what you are missing owes the reader the other half of the
/// picture, and a free tier stated plainly is more persuasive than one left
/// vague.
class _FreeTierNote extends StatelessWidget {
  const _FreeTierNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.includedFreeTitle, style: context.text.titleSmall),
          SizedBox(height: 3.h),
          Text(
            context.l10n.includedFreeBody(
              SubscriptionConstants.freeScreenshotLimit,
            ),
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}
