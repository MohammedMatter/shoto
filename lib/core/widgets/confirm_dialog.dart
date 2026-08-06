import 'package:flutter/material.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_dialog.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  bool isDestructive = false,
}) async {
  // The blur used to be built here, at full strength from the first frame,
  // so the background went soft before the panel it belonged to had arrived.
  // showAppDialog ramps it with the dialog instead.
  final bool? result = await showAppDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: context.colors.surface.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.colors.border),
      ),
      title: Text(title, style: context.text.titleLarge),
      content: Text(message, style: context.text.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            context.l10n.commonCancel,
            style: context.text.button.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            confirmLabel ?? context.l10n.commonConfirm,
            style: context.text.button.copyWith(
              color: isDestructive
                  ? context.colors.error
                  : context.colors.primary,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// A deletion confirmation that honours the "Ask before deleting" setting.
///
/// Deleting is the one action in SHOTO that cannot be undone, so the prompt
/// is on by default — but forcing it on someone who has explicitly turned it
/// off is just nagging. Returns true when the caller may proceed.
Future<bool> confirmDeletion(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  if (!sl<AppPreferences>().confirmBeforeDelete) return true;
  if (!context.mounted) return false;
  return showConfirmDialog(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    isDestructive: true,
  );
}
