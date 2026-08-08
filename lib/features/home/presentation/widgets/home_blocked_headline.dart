import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/primary_button.dart';

/// What Home says when it could not read the library at all.
///
/// It used to say nothing, and that was the whole bug. Home decided what to
/// put in its headline slot from a single `isLoading` flag derived as "the
/// state is not loaded" — which is equally true of a denied photo permission
/// and of a failed read as it is of the half second before the first read
/// lands. All three drew [SizedBox.shrink], so on a phone that had refused
/// photo access the first screen of the app was a greeting and a list of
/// tools with a hole where the count, the sentence and the import button
/// belong, and nothing anywhere saying why.
///
/// The Library tab has explained both cases since it shipped — see
/// `ScreenshotsBody`. This is the same explanation in Home's voice, in the
/// slot the headline would have occupied, so the first screen is never the
/// one screen that stays silent.
class HomeBlockedHeadline extends StatelessWidget {
  /// Set when photo access is what is blocking the read, and true when the OS
  /// granted only the hand-picked subset. Null when the read itself failed.
  final bool? isPartialAccess;

  /// Set when the read failed for any other reason. Null when it is the
  /// permission.
  final AppMessage? failure;

  /// Only a failure can be retried. A permission is fixed in Settings, and
  /// offering "Try again" for it sends the user in a circle.
  final VoidCallback? onRetry;

  const HomeBlockedHeadline.permission({super.key, required bool partial})
    : isPartialAccess = partial,
      failure = null,
      onRetry = null;

  const HomeBlockedHeadline.failure(this.failure, {super.key, this.onRetry})
    : isPartialAccess = null;

  @override
  Widget build(BuildContext context) {
    final bool blockedByPermission = isPartialAccess != null;

    final String headline = switch ((blockedByPermission, isPartialAccess)) {
      (false, _) => context.l10n.commonSomethingWentWrong,
      (true, true) => context.l10n.permissionPartialTitle,
      _ => context.l10n.permissionNeededTitle,
    };

    final String detail = switch ((blockedByPermission, isPartialAccess)) {
      (false, _) => failure!.resolve(context),
      (true, true) => context.l10n.permissionPartialMessage,
      _ => context.l10n.permissionNeededMessage,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(headline, style: context.text.headlineMedium),
        SizedBox(height: 5.h),
        Text(
          detail,
          style: context.text.bodySmall.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        SizedBox(height: 16.h),
        PrimaryButton(
          label: blockedByPermission
              ? context.l10n.permissionOpenSettings
              : context.l10n.commonRetry,
          onPressed: blockedByPermission
              ? () => PhotoManager.openSetting()
              : onRetry,
        ),
      ],
    );
  }
}
