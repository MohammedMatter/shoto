import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/sensitive_data.dart';
import 'package:shoto/features/safe_share/domain/entities/sensitive_region.dart';

/// The free scan's verdict: how many private details are in this screenshot,
/// and what they are.
///
/// This card is the entire free tier, and it is deliberately generous. Naming
/// the kinds — "your location, your account number, your name" — tells
/// somebody something they did not know about a picture they were about to
/// send, which is worth having whether or not they ever pay. Withholding the
/// list to make the paywall bite harder would only teach people the scan was
/// theatre.
class ScanReportCard extends StatelessWidget {
  final RedactionPlan plan;

  const ScanReportCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final Map<SensitiveKind, int> counts = plan.countsByKind;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 13.h, 14.w, 13.h),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: context.colors.marker.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                size: 17.sp,
                color: context.colors.marker,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  context.l10n.safeShareFoundTitle(plan.regions.length),
                  style: context.text.titleLarge,
                ),
              ),
            ],
          ),
          SizedBox(height: 9.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              for (final MapEntry<SensitiveKind, int> entry in counts.entries)
                _KindChip(kind: entry.key, count: entry.value),
            ],
          ),
          SizedBox(height: 9.h),
          Text(context.l10n.safeShareFreeScan, style: context.text.caption),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  final SensitiveKind kind;
  final int count;

  const _KindChip({required this.kind, required this.count});

  @override
  Widget build(BuildContext context) {
    final bool certain = kind.isCertain;
    final Color accent = certain ? context.colors.error : context.colors.marker;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Text(
        // The count only appears when it is more than one — "Phone number 1"
        // reads as a label with a stray digit stuck to it.
        count > 1 ? '${kind.label(context)} ×$count' : kind.label(context),
        style: context.text.caption.copyWith(
          color: context.colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// The one-paragraph explanation of what "protected" actually means here,
/// shown before anyone has paid for it.
///
/// It is on the free side of the wall on purpose. "We hide your card number"
/// is a claim every screenshot tool makes; what the user needs to know before
/// paying is *how* — a solid block, not a blur, and not a rewrite they would
/// have to trust the app to get right.
class CoverExplainer extends StatelessWidget {
  const CoverExplainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 15.sp,
                color: context.colors.textPrimary,
              ),
              SizedBox(width: 7.w),
              Text(
                context.l10n.safeShareHowTitle,
                style: context.text.titleSmall,
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(context.l10n.safeShareHowBody, style: context.text.bodySmall),
        ],
      ),
    );
  }
}
