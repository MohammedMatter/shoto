import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/widgets/app_snack_bar.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/widgets/empty_state.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/features/stitch/domain/entities/stitch_outcome.dart';
import 'package:shoto/features/stitch/presentation/bloc/stitch_bloc.dart';
import 'package:shoto/features/stitch/presentation/bloc/stitch_event.dart';
import 'package:shoto/features/stitch/presentation/bloc/stitch_state.dart';

/// Merges a run of scrolling screenshots and shows the result for approval.
///
/// Nothing reaches the gallery until the user has actually looked at the
/// join: automatic overlap detection is good but never certain, and only a
/// person can tell whether the merged page reads correctly.
class StitchPage extends StatelessWidget {
  final List<String> assetIds;

  const StitchPage({super.key, required this.assetIds});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StitchBloc>()..add(RunStitchEvent(assetIds)),
      child: ListenableBuilder(
        listenable: sl<ThemeController>(),
        builder: (context, child) => Scaffold(
          backgroundColor: context.colors.background,
          appBar: AppBar(
            backgroundColor: context.colors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: context.colors.textPrimary),
            title: Text(
              context.l10n.stitchTitle,
              style: context.text.titleLarge,
            ),
          ),
          body: const SafeArea(top: false, child: _Body()),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StitchBloc, StitchState>(
      listenWhen: (previous, current) => current is StitchSavedState,
      listener: (context, state) {
        showAppSnackBar(
          context,
          context.l10n.stitchSaved,
          kind: SnackKind.success,
        );
      },
      builder: (context, state) {
        // Exhaustive, no `default` — see `docs/decisions/screen-states.md`.
        // The old tail folded *initial* and *working* together silently; here
        // they still draw the same thing, but the file now says they do.
        return switch (state) {
          StitchFailedState(:final AppMessage message) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: EmptyState(
              icon: Icons.link_off_rounded,
              title: context.l10n.stitchFailed,
              message: message.resolve(context),
              action: PrimaryButton(
                label: context.l10n.commonBack,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          StitchReadyState() => _Preview(
            outcome: state.outcome,
            isSaving: state.isSaving,
          ),
          StitchSavedState() => _Preview(outcome: state.outcome, isSaved: true),
          StitchWorkingState() => _Working(fraction: state.fraction),

          // Merging starts in the frame the page is built, so the bar has no
          // progress to report yet — indeterminate is the honest answer, not
          // an empty screen while the first pair is decoded.
          StitchInitialState() => const _Working(fraction: null),
        };
      },
    );
  }
}

class _Working extends StatelessWidget {
  final double? fraction;
  const _Working({required this.fraction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 54.w,
              height: 54.w,
              child: CircularProgressIndicator(
                value: fraction,
                strokeWidth: 3.5,
                color: context.colors.primary,
                backgroundColor: context.colors.surfaceVariant,
              ),
            ),
            SizedBox(height: 22.h),
            Text(
              context.l10n.stitchWorking,
              style: context.text.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              context.l10n.stitchWorkingBody,
              style: context.text.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  final StitchOutcome outcome;
  final bool isSaving;
  final bool isSaved;

  const _Preview({
    required this.outcome,
    this.isSaving = false,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Summary(outcome: outcome),
        Expanded(
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
            decoration: BoxDecoration(
              color: context.colors.surfaceVariant,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: context.colors.border),
            ),
            clipBehavior: Clip.antiAlias,
            // The whole point is to check the joins, so the result is
            // scrollable at full width and pinch-zoomable rather than
            // squeezed into a thumbnail nobody can judge.
            child: InteractiveViewer(
              maxScale: 6,
              child: SingleChildScrollView(
                child: Image.memory(
                  outcome.pngBytes,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
          child: isSaved
              ? PrimaryButton(
                  label: context.l10n.commonDone,
                  icon: Icons.check_rounded,
                  onPressed: () => Navigator.of(context).pop(true),
                )
              // Discard takes the width of its own word; Save takes the rest.
              //
              // It was `Expanded` against `Expanded(flex: 2)`, which handed a
              // third of the row to a one-word text button and left "Save to
              // gallery" 38px short of fitting beside its icon. A fixed ratio
              // cannot know how long either word is, and the two are not the
              // same length in any of the seven languages.
              : Row(
                  children: [
                    TextButton(
                      onPressed: isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: 16.h,
                          horizontal: 12.w,
                        ),
                      ),
                      child: Text(
                        context.l10n.stitchDiscard,
                        style: context.text.button.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: PrimaryButton(
                        label: context.l10n.stitchSave,
                        icon: Icons.download_rounded,
                        isLoading: isSaving,
                        onPressed: () =>
                            context.read<StitchBloc>().add(SaveStitchEvent()),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  final StitchOutcome outcome;
  const _Summary({required this.outcome});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 10.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(9.w),
            decoration: BoxDecoration(
              color: context.colors.secondary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.photo_size_select_large_rounded,
              color: context.colors.secondary,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.stitchResultMerged(outcome.sourceCount),
                  style: context.text.bodyLarge.asSemiBold,
                ),
                SizedBox(height: 2.h),
                Text(
                  '${outcome.width} × ${outcome.height} px  ·  '
                  '${context.l10n.stitchResultTrimmed(outcome.trimmedRows)}',
                  style: context.text.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
