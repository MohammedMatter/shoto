import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
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
import 'package:shoto/features/screenshots/presentation/widgets/intent_picker_row.dart';
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
                child: _IntentSection(item: item, bloc: bloc),
              ),
              Divider(height: 1, color: AppColors.border),
              SizedBox(height: 6.h),
              _QuickActionTile(
                icon: item.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                iconColor: item.isFavorite
                    ? AppColors.error
                    : AppColors.textPrimary,
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
                iconColor: AppColors.secondary,
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
                iconColor: AppColors.error,
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
        leading: Icon(icon, color: iconColor ?? AppColors.textPrimary),
        title: Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            color: iconColor ?? AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// The intent row inside the quick-actions sheet, plus the tick when one is
/// set.
///
/// Stateful only so the chips repaint the instant they are tapped: the sheet
/// is built from the [ScreenshotEntity] handed in, which is a snapshot and
/// does not change under it while the sheet is open.
class _IntentSection extends StatefulWidget {
  final ScreenshotEntity item;
  final ScreenshotsBloc bloc;

  const _IntentSection({required this.item, required this.bloc});

  @override
  State<_IntentSection> createState() => _IntentSectionState();
}

class _IntentSectionState extends State<_IntentSection> {
  late ScreenshotIntent? _intent = widget.item.intent?.intent;
  late bool _isDone = widget.item.intent?.isDone ?? false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        IntentPickerRow(
          selected: _intent,
          onChanged: (ScreenshotIntent? next) {
            setState(() {
              _intent = next;
              // Changing the intent drops the tick with it, matching what the
              // repository does — the sheet must not show a finished state for
              // a task that has just been replaced.
              _isDone = false;
            });
            widget.bloc.add(SetIntentEvent(widget.item.id, next));
          },
        ),

        // The tick appears only once there is something to tick. Offering it
        // beforehand would be a control that does nothing, and this sheet has
        // no room to spend on those.
        AnimatedSize(
          duration: AppMotion.duration(context, AppMotion.instant),
          curve: AppMotion.standard,
          alignment: Alignment.topCenter,
          child: _intent == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: EdgeInsets.only(top: 12.h),
                  child: PressableScale(
                    scale: 0.97,
                    onTap: () {
                      Haptics.confirm();
                      setState(() => _isDone = !_isDone);
                      widget.bloc.add(
                        SetIntentDoneEvent(widget.item.id, _isDone),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(
                          _isDone
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 19.sp,
                          color: _isDone
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          _isDone
                              ? context.l10n.intentUndo
                              : context.l10n.intentMarkDone,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _isDone
                                ? AppColors.success
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
