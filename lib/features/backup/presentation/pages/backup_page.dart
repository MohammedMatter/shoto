import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/backup_file_service.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/backup_manifest.dart';
import 'package:shoto/core/widgets/app_snack_bar.dart';
import 'package:shoto/core/widgets/confirm_dialog.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/features/backup/domain/entities/backup_outcome.dart';
import 'package:shoto/features/backup/domain/use_cases/create_backup_use_case.dart';
import 'package:shoto/features/backup/domain/entities/restore_plan.dart';
import 'package:shoto/features/backup/presentation/widgets/restore_merge_sheet.dart';
import 'package:shoto/features/backup/domain/use_cases/preview_backup_use_case.dart';
import 'package:shoto/features/backup/domain/use_cases/restore_backup_use_case.dart';
import 'package:shoto/features/screenshots/presentation/bloc/intent_catalog.dart';

/// Making a copy of the library, and putting one back.
///
/// A plain page rather than a bloc-backed feature screen: there is no state to
/// share and nothing else in the app reads it. What it does need is to be
/// *unmistakable* — this is the one screen where a misunderstanding costs
/// somebody their library — so both actions say plainly what they do before
/// they do it, and the restore says it adds rather than replaces.
class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

/// Which of the two jobs is running, if either.
///
/// A value rather than the on-screen wording: the spinner belongs to the button
/// whose job is running, and deciding that by comparing translated strings
/// would quietly put it on the wrong button in any language where the two read
/// alike.
enum _Job { backup, restore }

class _BackupPageState extends State<BackupPage> {
  _Job? _job;
  double? _progress;

  bool get _busy => _job != null;

  void _setProgress(int done, int total) {
    if (!mounted || total == 0) return;
    setState(() => _progress = done / total);
  }

  Future<void> _createBackup() async {
    setState(() {
      _job = _Job.backup;
      _progress = 0;
    });

    try {
      final BackupResult result = await sl<CreateBackupUseCase>()(
        onProgress: _setProgress,
      );
      if (!mounted) return;

      // The share sheet is opened straight away rather than after a
      // confirmation: the file is in cache and cache is cleared by the system
      // whenever it likes, so a backup nobody has saved anywhere yet is not a
      // backup.
      await sl<BackupFileService>().exportFile(
        result.filePath,
        subject: context.mounted ? context.l10n.backupTitle : null,
      );
      if (!mounted) return;

      showAppSnackBar(
        context,
        result.isComplete
            ? context.l10n.backupDone(result.screenshots, result.folders)
            : context.l10n.backupDoneWithSkips(
                result.screenshots,
                result.unreadable,
              ),
        kind: result.isComplete ? SnackKind.success : SnackKind.neutral,
      );
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        context.l10n.backupFailed,
        kind: SnackKind.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _job = null;
          _progress = null;
        });
      }
    }
  }

  Future<void> _restore() async {
    final String? path = await sl<BackupFileService>().pickBackup();
    if (path == null || !mounted) return;

    // Asked *after* the file is chosen, so the question names what is about to
    // happen rather than what might.
    // showConfirmDialog rather than confirmDeletion: the latter honours the
    // "ask before deleting" preference and returns true without asking when it
    // is off, which is right for a delete and wrong here. Restoring is not a
    // deletion, and it is never the thing that preference was turned off for.
    // Read the index first. The one question worth asking is about folder
    // names already in use, and it can only be asked usefully *before*
    // anything is written — afterwards it would be asking about duplicates
    // that already exist.
    final BackupPreview preview;
    try {
      preview = await sl<PreviewBackupUseCase>()(path);
    } on BackupFormatException {
      if (!mounted) return;
      showAppSnackBar(
        context,
        context.l10n.restoreNotABackup,
        kind: SnackKind.error,
      );
      return;
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        context.l10n.restoreFailed,
        kind: SnackKind.error,
      );
      return;
    }
    if (!mounted) return;

    FolderMergeChoice choice = FolderMergeChoice.keepSeparate;

    if (preview.hasCollisions) {
      // Asked once for the whole file rather than once per folder: three
      // dialogs in a row to answer the same question is how somebody starts
      // tapping the default without reading.
      final FolderMergeChoice? answer = await showRestoreMergeSheet(
        context,
        names: preview.collidingFolderNames,
      );
      if (answer == null || !mounted) return;
      choice = answer;
    } else {
      final bool confirmed = await showConfirmDialog(
        context,
        title: context.l10n.restoreConfirmTitle,
        message: context.l10n.restoreConfirmMessage,
        confirmLabel: context.l10n.restoreAction,
      );
      if (!confirmed || !mounted) return;
    }

    setState(() {
      _job = _Job.restore;
      _progress = 0;
    });

    try {
      final RestoreResult result = await sl<RestoreBackupUseCase>()(
        path,
        onNameClash: choice,
        onProgress: _setProgress,
      );
      // The restore wrote custom intents straight into the database, under a
      // catalog that has been held in memory since the app started. Without
      // this the verbs are back but no picker can see them until the next
      // launch — which reads exactly like the restore having dropped them.
      await sl<IntentCatalog>().refresh();
      if (!mounted) return;

      showAppSnackBar(
        context,
        result.isComplete
            ? context.l10n.restoreDone(result.screenshots, result.folders)
            : context.l10n.restoreDoneWithSkips(
                result.screenshots,
                result.missing + result.failed,
              ),
        kind: result.isComplete ? SnackKind.success : SnackKind.neutral,
      );
    } on BackupFormatException {
      // Told apart from a crash on purpose. "That is not a SHOTO backup" is
      // something the user can act on; "something went wrong" is not.
      if (!mounted) return;
      showAppSnackBar(
        context,
        context.l10n.restoreNotABackup,
        kind: SnackKind.error,
      );
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        context.l10n.restoreFailed,
        kind: SnackKind.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _job = null;
          _progress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        title: Text(context.l10n.backupTitle, style: context.text.titleLarge),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsetsDirectional.fromSTEB(20.w, 8.h, 20.w, 40.h),
          children: [
            Text(
              context.l10n.backupIntro,
              style: context.text.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            SizedBox(height: 24.h),

            _Card(
              icon: Icons.save_alt_rounded,
              tint: context.colors.primary,
              title: context.l10n.backupCreateTitle,
              body: context.l10n.backupCreateBody,
              action: PrimaryButton(
                label: context.l10n.backupCreateAction,
                icon: Icons.save_alt_rounded,
                isLoading: _job == _Job.backup,
                onPressed: _busy ? null : _createBackup,
              ),
            ),
            SizedBox(height: 16.h),

            _Card(
              icon: Icons.settings_backup_restore_rounded,
              tint: context.colors.secondary,
              title: context.l10n.restoreTitle,
              body: context.l10n.restoreBody,
              action: PrimaryButton(
                label: context.l10n.restoreAction,
                icon: Icons.settings_backup_restore_rounded,
                isLoading: _job == _Job.restore,
                onPressed: _busy ? null : _restore,
              ),
            ),

            // A determinate bar, not a spinner. A library of several hundred
            // takes long enough that "is this stuck?" is a real question, and
            // the only honest answer is a number that moves.
            AnimatedSize(
              duration: AppMotion.duration(context, AppMotion.normal),
              curve: AppMotion.standard,
              alignment: Alignment.topCenter,
              child: !_busy
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: EdgeInsets.only(top: 24.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _job == _Job.restore
                                ? context.l10n.restoreWorking
                                : context.l10n.backupWorking,
                            style: context.text.bodySmall.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: LinearProgressIndicator(
                              value: _progress,
                              minHeight: 6.h,
                              backgroundColor: context.colors.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                context.colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            SizedBox(height: 28.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 15.sp,
                  color: context.colors.textSecondary,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    context.l10n.backupPrivacyNote,
                    style: context.text.caption.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String body;
  final Widget action;

  const _Card({
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Icon(icon, color: tint, size: 18.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(title, style: context.text.bodyLarge.asMedium),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            body,
            style: context.text.bodySmall.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(width: double.infinity, child: action),
        ],
      ),
    );
  }
}
