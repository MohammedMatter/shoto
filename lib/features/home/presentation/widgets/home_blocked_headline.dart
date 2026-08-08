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

  /// What the one button does, or null when there is nothing to offer.
  ///
  /// Three different jobs, and the difference matters more than it looks:
  /// a failure is retried, a refusal is repaired in Settings, and a question
  /// that has never been asked is simply asked. Offering "Try again" for a
  /// permission sends the user in a circle; offering Settings to somebody who
  /// has not seen the dialog sends them to repair an app that is not broken.
  final VoidCallback? onRetry;

  /// True for the state that has no answer yet, as opposed to a refusal.
  final bool isUnasked;

  const HomeBlockedHeadline.permission({super.key, required bool partial})
    : isPartialAccess = partial,
      failure = null,
      onRetry = null,
      isUnasked = false;

  /// Photo access has not been asked for. Home is the first screen a fresh
  /// install opens on, so this is the app's opening sentence — it explains
  /// what is wanted before Android's dialog says "photos and videos", and its
  /// button raises that dialog rather than pointing at system settings.
  const HomeBlockedHeadline.unasked({super.key, required this.onRetry})
    : isPartialAccess = null,
      failure = null,
      isUnasked = true;

  const HomeBlockedHeadline.failure(this.failure, {super.key, this.onRetry})
    : isPartialAccess = null,
      isUnasked = false;

  @override
  Widget build(BuildContext context) {
    final bool blockedByPermission = isPartialAccess != null;

    final String headline = switch ((isUnasked, blockedByPermission, isPartialAccess)) {
      (true, _, _) => context.l10n.permissionAskTitle,
      (false, false, _) => context.l10n.commonSomethingWentWrong,
      (false, true, true) => context.l10n.permissionPartialTitle,
      _ => context.l10n.permissionNeededTitle,
    };

    final String detail = switch ((isUnasked, blockedByPermission, isPartialAccess)) {
      (true, _, _) => context.l10n.permissionAskMessage,
      (false, false, _) => failure!.resolve(context),
      (false, true, true) => context.l10n.permissionPartialMessage,
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
          label: switch ((isUnasked, blockedByPermission)) {
            (true, _) => context.l10n.permissionAllow,
            (false, true) => context.l10n.permissionOpenSettings,
            _ => context.l10n.commonRetry,
          },
          onPressed: blockedByPermission
              ? () => PhotoManager.openSetting()
              : onRetry,
        ),
      ],
    );
  }
}
