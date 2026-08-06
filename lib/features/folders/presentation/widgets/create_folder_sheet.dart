import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/services/biometric_auth_service.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/app_switch.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_colors.dart';

Future<void> showCreateFolderSheet(
  BuildContext context, {
  required void Function(String name, int color, bool isPrivate) onCreate,
}) {
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _CreateFolderSheetContent(onCreate: onCreate),
  );
}

class _CreateFolderSheetContent extends StatefulWidget {
  final void Function(String name, int color, bool isPrivate) onCreate;
  const _CreateFolderSheetContent({required this.onCreate});

  @override
  State<_CreateFolderSheetContent> createState() =>
      _CreateFolderSheetContentState();
}

class _CreateFolderSheetContentState extends State<_CreateFolderSheetContent> {
  final TextEditingController _controller = TextEditingController();
  int _selectedColor = kFolderColors.first;
  bool _isPrivate = false;

  /// Starts at the widest claim and narrows once the device answers. The
  /// lookup is a platform round-trip, so the row would otherwise pop from
  /// blank to text a frame later; naming both and then dropping one is the
  /// quieter correction.
  BiometricKind _lockKind = BiometricKind.faceAndFingerprint;

  @override
  void initState() {
    super.initState();
    _loadLockKind();
  }

  Future<void> _loadLockKind() async {
    final BiometricKind kind = await sl<BiometricAuthService>().enrolledKind();
    if (!mounted) return;
    setState(() => _lockKind = kind);
  }

  /// Says only what this phone can actually do. The label used to promise
  /// "face or fingerprint" everywhere, which reads as a bug on the many
  /// Androids whose face unlock never reaches BiometricPrompt — you turn the
  /// switch on, and the prompt that appears has no face in it.
  String get _privateLabel => switch (_lockKind) {
    BiometricKind.faceAndFingerprint => context.l10n.foldersPrivate,
    BiometricKind.face => context.l10n.foldersPrivateFace,
    BiometricKind.fingerprint => context.l10n.foldersPrivateFingerprint,
    BiometricKind.unknown => context.l10n.foldersPrivateGeneric,
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SheetSurface(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              SizedBox(height: 20.h),
              Text(context.l10n.foldersNew, style: context.text.headlineMedium),
              SizedBox(height: 16.h),
              TextField(
                controller: _controller,
                autofocus: true,
                style: context.text.bodyLarge,
                decoration: InputDecoration(
                  hintText: context.l10n.foldersNameLabel,
                  hintStyle: context.text.bodyLarge.copyWith(
                    color: context.colors.textDisabled,
                  ),
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
              SizedBox(height: 20.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 12.h,
                children: kFolderColors.map((colorValue) {
                  final bool isSelected = colorValue == _selectedColor;
                  return PressableScale(
                    scale: 0.9,
                    onTap: () => setState(() => _selectedColor = colorValue),
                    // Picking a colour used to be a hard cut: a white ring and
                    // a tick appeared on one swatch and vanished from another
                    // in the same frame, which reads as two unrelated events
                    // rather than as the choice moving.
                    child: AnimatedContainer(
                      duration: AppMotion.duration(context, AppMotion.press),
                      curve: AppMotion.standard,
                      width: 36.w,
                      height: 36.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Color(colorValue),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: AnimatedScale(
                        scale: isSelected ? 1 : 0.4,
                        duration: AppMotion.duration(context, AppMotion.press),
                        curve: AppMotion.standard,
                        child: AnimatedOpacity(
                          opacity: isSelected ? 1 : 0,
                          duration: AppMotion.duration(
                            context,
                            AppMotion.press,
                          ),
                          curve: AppMotion.standard,
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20.h),
              // **The whole row answers, not just the switch.**
              //
              // Even with the thumb finally legible (see AppSwitch), a 12px
              // knob sliding 20px is a very quiet way to report the one
              // decision on this sheet that cannot be undone by looking — you
              // cannot tell a locked folder from an unlocked one without
              // trying to open it. So the row it lives in carries the state
              // too: it lifts onto the accent, draws an edge, and the
              // fingerprint lights up. Three signals for one bit, which is the
              // right ratio when the bit is "is this private".
              //
              // The border is always 1.5px and only its *colour* animates, so
              // switching it on cannot nudge the sheet's layout.
              PressableScale(
                scale: 0.98,
                onTap: () => setState(() => _isPrivate = !_isPrivate),
                child: AnimatedContainer(
                  duration: AppMotion.duration(context, AppMotion.press),
                  curve: AppMotion.standard,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    // A wash of the accent rather than a hue. The accent is
                    // achromatic in both modes, so "on" reads as the row being
                    // lifted off the sheet instead of as a colour arriving —
                    // and colour in this app has to mean something more
                    // specific than "selected".
                    color: _isPrivate
                        ? context.colors.primary.withValues(alpha: 0.10)
                        : context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: _isPrivate
                          ? context.colors.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // The glyph swaps as well as re-tints. A fingerprint is
                      // how you *open* the folder; whether it is locked at all
                      // is a padlock, and the two states now differ in shape
                      // rather than only in shade — which is the half of this
                      // that survives being colour-blind.
                      AnimatedSwitcher(
                        duration: AppMotion.duration(context, AppMotion.press),
                        switchInCurve: AppMotion.standard,
                        switchOutCurve: AppMotion.standard,
                        child: Icon(
                          _isPrivate
                              ? Icons.lock_rounded
                              : Icons.lock_open_rounded,
                          // Keyed, or AnimatedSwitcher sees one Icon widget of
                          // one type and cross-fades nothing.
                          key: ValueKey<bool>(_isPrivate),
                          color: _isPrivate
                              ? context.colors.textPrimary
                              : context.colors.textSecondary,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          _privateLabel,
                          // bodyLarge, matching every other switch row in the
                          // app — this one was a step smaller for no reason.
                          style: context.text.bodyLarge,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      AppSwitch(
                        value: _isPrivate,
                        onChanged: (value) =>
                            setState(() => _isPrivate = value),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              PrimaryButton(
                label: context.l10n.foldersCreate,
                onPressed: () {
                  final String name = _controller.text.trim();
                  if (name.isEmpty) return;
                  widget.onCreate(name, _selectedColor, _isPrivate);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
