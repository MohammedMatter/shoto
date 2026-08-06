import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/glass_layer.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';

/// Asks for the one thing Safe Share cannot work out on its own.
///
/// Card numbers carry a Luhn checksum and IBANs a mod-97 one, so the app can
/// *prove* it found those. A name has no arithmetic behind it: "Ahmed Khalil"
/// on a line by itself is a name only if you already know whose screenshot
/// this is. This is that knowledge, and it is the only personal detail SHOTO
/// ever asks anybody to type.
///
/// It used to be read from the signed-in Google account, which is where a
/// whole sign-in wall came from — for a string that is often wrong anyway,
/// since the name on somebody's email is not always the name their bank
/// prints. See `docs/decisions/accounts.md`.
Future<void> showOwnerNameSheet(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => const _OwnerNameContent(),
  );
}

class _OwnerNameContent extends StatefulWidget {
  const _OwnerNameContent();

  @override
  State<_OwnerNameContent> createState() => _OwnerNameContentState();
}

class _OwnerNameContentState extends State<_OwnerNameContent> {
  final AppPreferences _preferences = sl<AppPreferences>();
  late final TextEditingController _controller = TextEditingController(
    text: _preferences.ownerName,
  );
  final FocusNode _focusNode = FocusNode();

  /// Long enough for a full name with a middle one in it, short enough that
  /// nobody mistakes this for a notes field.
  static const int _maxLength = 48;

  /// Same reasoning as the intent editor: raising the keyboard on the frames
  /// the sheet is sliding costs the entrance, so it follows the sheet in
  /// rather than arriving with it.
  static const Duration _focusDelay = AppMotion.normal;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(_focusDelay, () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SheetSurface(
        sigma: AppBlur.panel,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 12.h),
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  context.l10n.ownerNameTitle,
                  style: context.text.headlineMedium,
                ),
              ),
              SizedBox(height: 8.h),
              // The explanation is not fine print here. Every other screen in
              // SHOTO can promise that nothing is collected; this one asks for
              // something, so it says what for and where it goes before the
              // field it is asking into.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  context.l10n.ownerNameBody,
                  style: context.text.bodySmall,
                ),
              ),
              SizedBox(height: 18.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLength: _maxLength,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  style: context.text.bodyLarge,
                  onSubmitted: (_) => _save(),
                  decoration: InputDecoration(
                    hintText: context.l10n.ownerNameFieldHint,
                    hintStyle: context.text.bodyLarge.copyWith(
                      color: context.colors.textDisabled,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: context.colors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // No disabled state and no separate "clear" control: an empty
              // field saved is how the name is removed, which is the same
              // gesture as changing it and needs no second button to explain.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _save,
                    style: TextButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: Text(
                      context.l10n.commonSave,
                      style: context.text.bodyLarge.asMedium.copyWith(
                        color: context.colors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    await _preferences.setOwnerName(_controller.text);
    if (!mounted) return;
    Haptics.confirm();
    Navigator.of(context).pop();
  }
}
