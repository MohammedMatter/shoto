import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_dialog.dart';
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/glass_layer.dart';

/// Asks for the four-digit code that turns the developer unlock on.
///
/// Returns true once it is on. Styled like [showConfirmDialog] so it reads as
/// part of SHOTO rather than a debug panel bolted on — this dialog can appear
/// in a release build, and anything that looks like a leftover test screen
/// makes the app feel unfinished.
Future<bool> showDevUnlockDialog(BuildContext context) async {
  final bool? unlocked = await showAppDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    // The panel frosts its own backdrop below, so the shared one stays off.
    blurSigma: 0,
    builder: (_) => const _DevUnlockDialog(),
  );
  return unlocked == true;
}

class _DevUnlockDialog extends StatefulWidget {
  const _DevUnlockDialog();

  @override
  State<_DevUnlockDialog> createState() => _DevUnlockDialogState();
}

class _DevUnlockDialogState extends State<_DevUnlockDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bool ok = await sl<DevAccess>().unlock(_controller.text);
    if (!mounted) return;

    if (!ok) {
      Haptics.reject();
      setState(() {
        _wrong = true;
        _controller.clear();
      });
      return;
    }

    Haptics.confirm();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 34.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppBlur.panel,
            sigmaY: AppBlur.panel,
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 18.h),
            decoration: BoxDecoration(
              color: context.colors.surface.withValues(alpha: 0.92),
              border: Border.all(color: context.colors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54.w,
                  height: 54.w,
                  decoration: BoxDecoration(
                    gradient: context.colors.brandGradient,
                    borderRadius: BorderRadius.circular(17.r),
                  ),
                  child: Icon(
                    Icons.terminal_rounded,
                    color: context.colors.onPrimary,
                    size: 26.sp,
                  ),
                ),
                SizedBox(height: 15.h),
                Text(
                  context.l10n.devAccessTitle,
                  style: context.text.titleLarge,
                ),
                SizedBox(height: 5.h),
                Text(
                  context.l10n.devAccessBody,
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall,
                ),
                SizedBox(height: 18.h),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  obscureText: true,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) {
                    if (_wrong) setState(() => _wrong = false);
                  },
                  onSubmitted: (_) => _submit(),
                  style: context.text.headlineMedium.copyWith(
                    letterSpacing: 12,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••',
                    hintStyle: context.text.headlineMedium.copyWith(
                      color: context.colors.textDisabled,
                      letterSpacing: 12,
                    ),
                    filled: true,
                    fillColor: context.colors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.r),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.r),
                      borderSide: BorderSide(
                        color: _wrong
                            ? context.colors.error
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
                if (_wrong) ...[
                  SizedBox(height: 8.h),
                  Text(
                    context.l10n.devWrongCode,
                    style: context.text.bodySmall.copyWith(
                      color: context.colors.error,
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: PressableScale(
                        scale: 0.96,
                        onTap: () => Navigator.of(context).pop(false),
                        child: Container(
                          height: 48.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: context.colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          child: Text(
                            context.l10n.commonCancel,
                            style: context.text.button.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: PressableScale(
                        scale: 0.96,
                        onTap: _submit,
                        child: Container(
                          height: 48.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: context.colors.primaryGradient,
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          child: Text(
                            context.l10n.commonUnlock,
                            style: context.text.button.copyWith(
                              color: context.colors.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
