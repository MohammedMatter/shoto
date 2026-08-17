import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/confirm_dialog.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/features/folders/presentation/widgets/move_to_folder_sheet.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/widgets/intent_section.dart';
import 'package:shoto/features/screenshots/presentation/widgets/reminder_sheet.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshot_limit_gate.dart';

/// Shared "share to another app" action, used by both the detail viewer and
/// the per-thumbnail quick-actions sheet so the logic only lives once.
Future<void> shareScreenshot(ScreenshotEntity item) async {
  final File? file = await item.asset.file;
  if (file == null) return;
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
}

/// A compact bottom sheet of one-tap actions (favorite, share, move to
/// folder, delete) for a single screenshot — reachable directly from its
/// grid thumbnail without needing to open the full-screen viewer or enter
/// multi-select mode first.
Future<void> showScreenshotQuickActionsSheet(
  BuildContext context,
  ScreenshotEntity item,
) {
  final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
  return showAppSheet<void>(
    context: context,
    builder: (sheetContext) => SheetSurface(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // **Above the actions, because it is not one.**
              //
              // Everything below this row does something to the screenshot now
              // — share it, move it, delete it. This records what the user
              // intends to do with it later, and mixing a statement of intent
              // into a list of verbs would make it read as a sixth thing to
              // trigger. It also stays open after a tap, since changing your
              // mind twice is normal and closing the sheet to reopen it is not.
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20.w, 8.h, 20.w, 14.h),
                child: IntentSection(item: item, bloc: bloc),
              ),
              Divider(height: 1, color: context.colors.border),
              SizedBox(height: 6.h),
              // **First of the verbs, and directly under the intent row.**
              //
              // It belongs to the same thought: the row above records what the
              // user is going to do about this, and this is the only control
              // in the app that makes the app say so again later. Everything
              // below acts on the picture now.
              _QuickActionTile(
                icon: item.hasPendingReminder
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                iconColor: item.hasPendingReminder
                    ? context.colors.primary
                    : context.colors.textPrimary,
                label: context.l10n.reminderTitle,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  showReminderSheet(
                    context,
                    item,
                    // The bloc holds the library, and a reminder is stored on
                    // the same row as the folder and the favourite — so the
                    // grid has to be told, or the bell on this tile stays
                    // hollow until the next full load.
                    onChanged: () => bloc.add(LoadScreenshotsEvent()),
                  );
                },
              ),
              _QuickActionTile(
                icon: item.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                iconColor: item.isFavorite
                    ? context.colors.error
                    : context.colors.textPrimary,
                label: item.isFavorite
                    ? context.l10n.detailUnfavorite
                    : context.l10n.detailAddFavorite,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _toggleFavoriteWithLimitCheck(context, bloc, item);
                },
              ),
              _QuickActionTile(
                icon: Icons.ios_share_rounded,
                label: context.l10n.commonShare,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  shareScreenshot(item);
                },
              ),
              _QuickActionTile(
                icon: Icons.drive_file_move_rounded,
                iconColor: context.colors.secondary,
                label: context.l10n.foldersMoveTitle,
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final bool allowed = await ensureUnderScreenshotLimit(
                    context,
                    additionalNewItems: _isAlreadyManaged(item) ? 0 : 1,
                  );
                  if (!allowed || !context.mounted) return;
                  showMoveToFolderSheet(
                    context,
                    currentFolderId: item.folderId,
                    onSelected: (folderId) => bloc.add(
                      MoveScreenshotToFolderEvent(item.id, folderId),
                    ),
                  );
                },
              ),
              _QuickActionTile(
                icon: Icons.delete_outline_rounded,
                iconColor: context.colors.error,
                label: context.l10n.commonDelete,
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final bool confirmed = await showConfirmDialog(
                    context,
                    title: context.l10n.detailDeleteTitle,
                    message: context.l10n.detailDeleteMessage,
                    confirmLabel: context.l10n.commonDelete,
                    isDestructive: true,
                  );
                  if (confirmed) bloc.add(DeleteScreenshotEvent(item.id));
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

bool _isAlreadyManaged(ScreenshotEntity item) =>
    item.isFavorite || item.folderId != null;

Future<void> _toggleFavoriteWithLimitCheck(
  BuildContext context,
  ScreenshotsBloc bloc,
  ScreenshotEntity item,
) async {
  final bool allowed = await ensureUnderScreenshotLimit(
    context,
    additionalNewItems: _isAlreadyManaged(item) ? 0 : 1,
  );
  if (!allowed) return;
  bloc.add(ToggleFavoriteEvent(item.id));
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The tap lives on PressableScale rather than on the ListTile: a Material
    // ripple spreading across a full-width row on a tinted sheet reads as a
    // grey wash in dark mode, and it only starts on release. The scale starts
    // on press-down, which is the half of the interaction that decides whether
    // the sheet feels responsive.
    return PressableScale(
      scale: 0.98,
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? context.colors.textPrimary),
        title: Text(
          label,
          style: context.text.bodyLarge.copyWith(
            color: iconColor ?? context.colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
