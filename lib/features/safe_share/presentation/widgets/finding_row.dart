import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/sensitive_data.dart';
import 'package:shoto/features/safe_share/domain/entities/sensitive_region.dart';
import 'package:shoto/features/safe_share/presentation/widgets/treatment_selector.dart';

/// One finding in the review list.
///
/// It answers two questions in the order people ask them: what did you find,
/// and what will happen to it. The row shows the real value — masked where
/// showing it in full would repeat the secret — because a list the user
/// cannot read is a list they cannot correct.
class FindingRow extends StatelessWidget {
  final SensitiveRegion region;

  /// Null before the feature is unlocked: the finding is listed and no choice
  /// is offered.
  final ValueChanged<RegionTreatment>? onTreatmentChanged;

  const FindingRow({super.key, required this.region, this.onTreatmentChanged});

  @override
  Widget build(BuildContext context) {
    final bool locked = onTreatmentChanged == null;
    final bool certain = region.kind.isCertain;

    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: region.treatment == RegionTreatment.keep && !locked
              ? context.colors.error.withValues(alpha: 0.35)
              : context.colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color:
                      (certain ? context.colors.error : context.colors.marker)
                          .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Icon(
                  _iconFor(region.kind),
                  size: 15.sp,
                  color: certain ? context.colors.error : context.colors.marker,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  region.kind.label(context),
                  style: context.text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (locked)
                Icon(
                  Icons.lock_outline_rounded,
                  size: 15.sp,
                  color: context.colors.textDisabled,
                ),
            ],
          ),
          SizedBox(height: 8.h),
          _BeforeAfter(region: region, locked: locked),
          if (!locked) ...[
            SizedBox(height: 9.h),
            TreatmentSelector(
              value: region.treatment,
              onChanged: onTreatmentChanged!,
            ),
          ],
        ],
      ),
    );
  }

  static IconData _iconFor(SensitiveKind kind) => switch (kind) {
    SensitiveKind.card => Icons.credit_card_rounded,
    SensitiveKind.iban => Icons.account_balance_rounded,
    SensitiveKind.nationalId => Icons.badge_outlined,
    SensitiveKind.code => Icons.password_rounded,
    SensitiveKind.postalAddress => Icons.location_on_outlined,
    SensitiveKind.personName => Icons.person_outline_rounded,
    SensitiveKind.phone => Icons.phone_outlined,
    SensitiveKind.email => Icons.alternate_email_rounded,
    SensitiveKind.orderNumber => Icons.receipt_long_outlined,
    SensitiveKind.number => Icons.numbers_rounded,
  };
}

/// "•••• 5566 becomes ▮▮▮▮".
///
/// The real value is masked and what replaces it is not, which looks
/// backwards for exactly one second. It is the right way round: the user
/// already knows what their own card number is, and what they cannot know
/// without being told is what a stranger will see instead.
class _BeforeAfter extends StatelessWidget {
  final SensitiveRegion region;
  final bool locked;

  const _BeforeAfter({required this.region, required this.locked});

  @override
  Widget build(BuildContext context) {
    final bool numeric = switch (region.kind) {
      SensitiveKind.card ||
      SensitiveKind.iban ||
      SensitiveKind.nationalId ||
      SensitiveKind.code ||
      SensitiveKind.orderNumber ||
      SensitiveKind.number ||
      SensitiveKind.phone => true,
      _ => false,
    };
    final TextStyle valueStyle = numeric
        ? context.text.monoBody
        : context.text.bodySmall;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8.w,
      runSpacing: 3.h,
      children: [
        Text(
          region.maskedOriginal,
          style: valueStyle.copyWith(color: context.colors.textSecondary),
        ),
        if (locked)
          Text(
            context.l10n.safeShareLockedPreview,
            style: context.text.caption.copyWith(
              color: context.colors.textDisabled,
            ),
          )
        else ...[
          Icon(
            Icons.arrow_forward_rounded,
            size: 12.sp,
            color: context.colors.textDisabled,
          ),
          Text(
            region.treatment == RegionTreatment.cover
                ? '▮▮▮▮'
                : region.maskedOriginal,
            style: valueStyle.copyWith(
              color: region.treatment == RegionTreatment.keep
                  ? context.colors.error
                  : context.colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
