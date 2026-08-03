import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';

/// The one way this app shows a passing message.
///
/// Every call site used to reach for `ScaffoldMessenger.showSnackBar`
/// directly, and Material *queues* those: tapping a tool card four times
/// meant watching the same sentence four times in a row, long after the tap
/// that caused it. That reads as the app being stuck rather than as an
/// answer to what you did.
///
/// So a message showing already suppresses an identical one — press the same
/// card again and nothing new happens until the first has gone. A *different*
/// message replaces it immediately, because that one is the answer to the tap
/// you just made, and making somebody wait for an unrelated hint to expire
/// would be worse than the queue.
enum SnackKind { neutral, success, error }

/// Tracked globally rather than per-messenger: the point is one message on
/// screen at a time, and there is only ever one screen.
String? _visibleMessage;

void showAppSnackBar(
  BuildContext context,
  String message, {
  SnackKind kind = SnackKind.neutral,
}) {
  if (_visibleMessage == message) return;

  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  _visibleMessage = message;

  final Color tint = switch (kind) {
    SnackKind.neutral => AppColors.primary,
    SnackKind.success => AppColors.success,
    SnackKind.error => AppColors.error,
  };

  final ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller =
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                switch (kind) {
                  SnackKind.neutral => Icons.lightbulb_outline_rounded,
                  SnackKind.success => Icons.check_circle_outline_rounded,
                  SnackKind.error => Icons.error_outline_rounded,
                },
                color: tint,
                size: 19.sp,
              ),
              SizedBox(width: 11.w),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          // Clears the floating bottom nav, which lives in a Stack above the
          // body — a default-positioned snack bar slides in underneath it.
          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 104.h),
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 13.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(color: AppColors.border),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

  controller.closed.then((_) {
    // Only clear if this message is still the one on screen — a replacement
    // that arrived first must not be forgotten by its predecessor closing.
    if (_visibleMessage == message) _visibleMessage = null;
  });
}
