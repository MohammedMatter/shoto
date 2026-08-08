import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/widgets/app_snack_bar.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/byte_formatter.dart';
import 'package:shoto/core/widgets/confirm_dialog.dart';
import 'package:shoto/core/widgets/empty_state.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/features/duplicates/domain/entities/duplicate_group.dart';
import 'package:shoto/features/duplicates/presentation/bloc/duplicates_bloc.dart';
import 'package:shoto/features/duplicates/presentation/bloc/duplicates_event.dart';
import 'package:shoto/features/duplicates/presentation/bloc/duplicates_state.dart';
import 'package:shoto/features/duplicates/presentation/widgets/duplicate_group_card.dart';

/// Review screen for visually-identical screenshots.
///
/// Deliberately never deletes anything on its own: the scan only *proposes*
/// which copy to keep, everything stays editable, and the actual deletion is
/// behind an explicit confirm dialog — because getting it wrong destroys
/// someone's photo permanently.
class DuplicatesPage extends StatelessWidget {
  const DuplicatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DuplicatesBloc>()..add(ScanForDuplicatesEvent()),
      child: BlocConsumer<DuplicatesBloc, DuplicatesState>(
        listener: (context, state) {
          if (state is DuplicatesDeletedState) {
            showAppSnackBar(
              context,
              context.l10n.dupDeleted(
                state.deletedCount,
                formatBytes(state.freedBytes),
              ),
              kind: SnackKind.success,
            );
            // Re-scan so the list reflects what's actually left.
            context.read<DuplicatesBloc>().add(ScanForDuplicatesEvent());
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: context.colors.background,
            appBar: AppBar(
              backgroundColor: context.colors.background,
              elevation: 0,
              iconTheme: IconThemeData(color: context.colors.textPrimary),
              title: Text(
                context.l10n.dupTitle,
                style: context.text.titleLarge,
              ),
            ),
            body: SafeArea(top: false, child: _Body(state: state)),
            bottomNavigationBar:
                state is DuplicatesLoadedState && state.hasDuplicates
                ? _DeleteBar(state: state)
                : null,
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final DuplicatesState state;
  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    // Exhaustive on purpose, with no `default` — see
    // `docs/decisions/screen-states.md`. This was an `is!` chain ending in
    // `SizedBox.shrink()`, which drew *initial* and *deleted* as a blank page
    // under a title bar. Both are brief, and neither is nothing.
    return switch (state) {
      DuplicatesScanningState scanning => _ScanningView(state: scanning),

      // The scan is dispatched in the frame the page is built, so this is one
      // frame wide — until the day it isn't. A scan that never starts used to
      // be indistinguishable from a library with no duplicates in it.
      DuplicatesInitialState() => _ScanningView(state: DuplicatesScanningState()),

      // Deleting ends here and the listener immediately re-scans, so this is
      // the same one frame. Drawn as a scan for the same reason: whatever the
      // user sees between the delete and the fresh list, it is not "done".
      DuplicatesDeletedState() => _ScanningView(state: DuplicatesScanningState()),

      DuplicatesErrorState(:final AppMessage message) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: context.l10n.commonSomethingWentWrong,
        message: message.resolve(context),
        action: PrimaryButton(
          label: context.l10n.commonRetry,
          onPressed: () =>
              context.read<DuplicatesBloc>().add(ScanForDuplicatesEvent()),
        ),
      ),

      // The tick is earned only by a scan that finished and found nothing.
      DuplicatesLoadedState(hasDuplicates: false) => EmptyState(
        icon: Icons.verified_rounded,
        title: context.l10n.dupNoneTitle,
        message: context.l10n.dupNoneBody,
        action: PrimaryButton(
          label: context.l10n.dupScanAgain,
          onPressed: () =>
              context.read<DuplicatesBloc>().add(ScanForDuplicatesEvent()),
        ),
      ),

      DuplicatesLoadedState loaded => ListView(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
        children: [
          _SummaryBanner(
            groupCount: loaded.groups.length,
            reclaimableBytes: loaded.groups.fold(
              0,
              (int sum, DuplicateGroup group) => sum + group.reclaimableBytes,
            ),
          ),
          SizedBox(height: 18.h),
          ...loaded.groups.map(
            (DuplicateGroup group) => DuplicateGroupCard(
              group: group,
              selectedIds: loaded.selectedIds,
              onToggle: (assetId) => context.read<DuplicatesBloc>().add(
                ToggleCandidateEvent(assetId),
              ),
              onKeepAll: () => context.read<DuplicatesBloc>().add(
                KeepEntireGroupEvent(group.id),
              ),
              onResetSelection: () => context.read<DuplicatesBloc>().add(
                ResetGroupSelectionEvent(group.id),
              ),
            ),
          ),
        ],
      ),
    };
  }
}

class _ScanningView extends StatelessWidget {
  final DuplicatesScanningState state;
  const _ScanningView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56.w,
              height: 56.w,
              child: CircularProgressIndicator(
                value: state.total == 0 ? null : state.fraction,
                strokeWidth: 4,
                color: context.colors.primary,
                backgroundColor: context.colors.surfaceVariant,
              ),
            ),
            SizedBox(height: 22.h),
            Text(
              context.l10n.dupScanning,
              style: context.text.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              state.total == 0
                  ? context.l10n.dupReading
                  : context.l10n.dupProgress(state.processed, state.total),
              style: context.text.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final int groupCount;
  final int reclaimableBytes;

  const _SummaryBanner({
    required this.groupCount,
    required this.reclaimableBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: context.colors.primaryGradient,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: context.colors.onPrimary,
            size: 26.sp,
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.dupSetsFound(groupCount),
                  style: context.text.titleLarge.copyWith(
                    color: context.colors.onPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  context.l10n.dupReclaimable(formatBytes(reclaimableBytes)),
                  style: context.text.bodySmall.copyWith(
                    color: context.colors.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteBar extends StatelessWidget {
  final DuplicatesLoadedState state;
  const _DeleteBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final int count = state.selectedCount;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(top: BorderSide(color: context.colors.border)),
        ),
        child: PrimaryButton(
          label: count == 0
              ? context.l10n.dupNothingSelected
              : context.l10n.dupDeleteButton(
                  count,
                  formatBytes(state.selectedBytes),
                ),
          isLoading: state.isDeleting,
          onPressed: count == 0
              ? null
              : () async {
                  final DuplicatesBloc bloc = context.read<DuplicatesBloc>();
                  final bool confirmed = await showConfirmDialog(
                    context,
                    title: context.l10n.dupDeleteTitle(count),
                    message: context.l10n.dupDeleteMessage,
                    confirmLabel: context.l10n.commonDelete,
                    isDestructive: true,
                  );
                  if (confirmed) {
                    bloc.add(DeleteSelectedDuplicatesEvent());
                  }
                },
        ),
      ),
    );
  }
}
