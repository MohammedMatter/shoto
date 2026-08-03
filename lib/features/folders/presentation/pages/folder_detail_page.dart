import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/biometric_auth_service.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_actions_sheet.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshots_body.dart';

class FolderDetailPage extends StatefulWidget {
  final FolderEntity folder;
  const FolderDetailPage({super.key, required this.folder});

  @override
  State<FolderDetailPage> createState() => _FolderDetailPageState();
}

class _FolderDetailPageState extends State<FolderDetailPage> {
  late bool _unlocked = !widget.folder.isPrivate;
  bool _authenticating = false;

  /// Held in state rather than read straight off the widget so a rename
  /// made from this page updates the title immediately instead of showing
  /// the stale name until you navigate away and back.
  late FolderEntity _folder = widget.folder;

  void _showActions() {
    showFolderActionsSheet(
      context,
      folder: _folder,
      bloc: context.read<FoldersBloc>(),
      onRenamed: (name) =>
          setState(() => _folder = _folder.copyWith(name: name)),
      // The folder this page exists to show is gone — there's nothing left
      // to display, so step back to the grid.
      onDeleted: () => Navigator.of(context).pop(),
    );
  }

  Future<void> _authenticate() async {
    setState(() => _authenticating = true);
    final bool success = await sl<BiometricAuthService>().authenticate(
      reason: context.l10n.folderLockedTitle(widget.folder.name),
    );
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      _unlocked = success;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_rounded,
                  size: 48.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 16.h),
                Text(
                  widget.folder.name,
                  style: AppTextStyles.titleLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  context.l10n.folderLockedMessage,
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                PrimaryButton(
                  label: context.l10n.commonUnlock,
                  icon: Icons.fingerprint_rounded,
                  isLoading: _authenticating,
                  onPressed: _authenticate,
                ),
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    context.l10n.commonCancel,
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final FolderEntity folder = _folder;
    return BlocProvider(
      create: (_) =>
          sl<ScreenshotsBloc>()..add(LoadScreenshotsEvent(folderId: folder.id)),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(4.w, 4.h, 20.w, 4.h),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: Color(folder.color).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.folder_rounded,
                        color: Color(folder.color),
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        folder.name,
                        style: AppTextStyles.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.foldersOptions,
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: _showActions,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ScreenshotsBody(
                  emptyTitle: context.l10n.folderEmptyTitle,
                  emptyMessage: context.l10n.folderEmptyMessage,
                  showFavoritesFilter: false,
                  // Its own namespace even though this is its own route:
                  // the library grid below it is showing the same
                  // screenshots, and relying on route boundaries to keep two
                  // identical tags apart is a trap for whoever changes how
                  // this screen is presented later.
                  heroPrefix: 'folder',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
