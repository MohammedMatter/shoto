import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/services/account_service.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/app_snack_bar.dart';
import 'package:shoto/core/widgets/glass_layer.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';

/// The account, asked for at the only moment it is worth anything.
///
/// **One field pair, one button, and no choice between "sign in" and "sign
/// up".** Whether an account already exists for this address is something the
/// server knows and the user usually does not — see [AccountService.signIn].
///
/// Opened from Settings, from the confirmation after a purchase, and from a
/// restore that came back empty. Never from a router, never before the app has
/// shown what it is for.
Future<void> showAccountSheet(BuildContext context, {String? reason}) {
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => _AccountContent(reason: reason),
  );
}

class _AccountContent extends StatefulWidget {
  /// Why the sheet opened, in the user's terms — "your subscription is not on
  /// this phone yet", rather than nothing at all. Null when they came here
  /// deliberately from Settings and already know.
  final String? reason;

  const _AccountContent({this.reason});

  @override
  State<_AccountContent> createState() => _AccountContentState();
}

class _AccountContentState extends State<_AccountContent> {
  final AccountService _account = sl<AccountService>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final FocusNode _emailFocus = FocusNode();

  bool _busy = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _email.text = _account.email ?? '';
    // Same reasoning as the intent editor: the keyboard rising on the frames
    // the sheet is sliding costs the entrance.
    Future<void>.delayed(AppMotion.normal, () {
      if (mounted && !_account.isSignedIn) _emailFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final String email = _email.text.trim();
    final String password = _password.text;
    if (email.isEmpty || password.isEmpty) return;

    setState(() => _busy = true);
    final AppMessage? failure = await _account.signIn(
      email: email,
      password: password,
    );
    if (!mounted) return;

    if (failure != null) {
      setState(() => _busy = false);
      showAppSnackBar(context, failure.resolve(context), kind: SnackKind.error);
      return;
    }

    // The whole point of the account, in one call: the entitlement moves off
    // the device id and onto something the store does not own.
    final String? id = await _account.currentUserId();
    if (id != null) {
      await sl<SubscriptionRepository>().attachAccount(id);
      await sl<ProStatus>().refresh();
    }
    if (!mounted) return;

    Haptics.confirm();
    Navigator.of(context).pop();
    showAppSnackBar(context, context.l10n.accountSignedIn);
  }

  Future<void> _forgot() async {
    final String email = _email.text.trim();
    if (email.isEmpty) {
      _emailFocus.requestFocus();
      return;
    }

    final AppMessage? failure = await _account.sendPasswordReset(email);
    if (!mounted) return;
    showAppSnackBar(
      context,
      failure?.resolve(context) ?? context.l10n.accountResetSent,
      kind: failure == null ? SnackKind.neutral : SnackKind.error,
    );
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    await _account.signOut();
    await sl<SubscriptionRepository>().detachAccount();
    await sl<ProStatus>().refresh();
    if (!mounted) return;

    Navigator.of(context).pop();
    showAppSnackBar(context, context.l10n.accountSignedOut);
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
          child: ListenableBuilder(
            listenable: _account,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 12.h),
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Text(
                    context.l10n.accountTitle,
                    style: AppTextStyles.headlineMedium,
                  ),
                ),
                SizedBox(height: 8.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Text(
                    // What it does *and what it does not do*, both. An account
                    // that quietly implies your library is backed up is a
                    // promise this app cannot keep.
                    widget.reason ?? context.l10n.accountBody,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                SizedBox(height: 18.h),
                if (_account.isSignedIn)
                  ..._signedIn(context)
                else
                  ..._signedOut(context),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _signedOut(BuildContext context) => <Widget>[
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: _Field(
        controller: _email,
        focusNode: _emailFocus,
        hint: context.l10n.accountEmailHint,
        keyboardType: TextInputType.emailAddress,
      ),
    ),
    SizedBox(height: 10.h),
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: _Field(
        controller: _password,
        hint: context.l10n.accountPasswordHint,
        obscure: _obscure,
        onSubmitted: (_) => _submit(),
        suffix: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    ),
    SizedBox(height: 16.h),
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: PrimaryButton(
        label: context.l10n.accountContinue,
        isLoading: _busy,
        onPressed: _submit,
      ),
    ),
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton(
          onPressed: _forgot,
          child: Text(
            context.l10n.accountForgot,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    ),
  ];

  List<Widget> _signedIn(BuildContext context) => <Widget>[
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.mail_outline_rounded,
              size: 19.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                _account.email ?? '',
                style: AppTextStyles.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
    SizedBox(height: 14.h),
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: _busy ? null : _signOut,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
              side: BorderSide(color: AppColors.border),
            ),
          ),
          child: Text(
            context.l10n.accountSignOut,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
          ),
        ),
      ),
    ),
    SizedBox(height: 8.h),
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      // Said plainly, because signing out of most apps takes something away
      // and this one does not: the library is on the device and stays there.
      child: Text(
        context.l10n.accountSignOutNote,
        style: AppTextStyles.caption,
      ),
    ),
  ];
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  const _Field({
    required this.controller,
    required this.hint,
    this.focusNode,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: onSubmitted == null
          ? TextInputAction.next
          : TextInputAction.done,
      onSubmitted: onSubmitted,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textDisabled,
        ),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        suffixIcon: suffix,
      ),
    );
  }
}
