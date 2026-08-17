import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/photo_viewer_route.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/asset_thumbnail_image.dart';
import 'package:shoto/core/widgets/empty_state.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/use_cases/set_reminder_use_case.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/pages/screenshot_detail_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/library_unavailable.dart';

/// Everything the user asked to be brought back to.
///
/// **The feature had nowhere to be looked at.** A reminder was invisible unless
/// you long-pressed the exact screenshot it was set on, so the app could not
/// answer "what have I asked to be reminded about?" — and finding one meant
/// remembering which picture it was, which is the thing the reminder was
/// supposed to remember for you.
///
/// **Missed ones lead, and that is the reason this screen matters most.** A
/// notification clears itself when it fires. Without a list, the single moment
/// the app asked for attention was also the only one it would ever get: miss it
/// and the reminder was gone with nothing left behind. Here it stays, in the
/// alert colour, until it is dealt with.
class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenshotsBloc, ScreenshotsState>(
      builder: (context, state) {
        // An unread library is not an empty one — same reasoning as IntentPage.
        final Widget? blocked = LibraryUnavailable.maybeOf(state);
        final ScreenshotsLoadedState? loaded = state is ScreenshotsLoadedState
            ? state
            : null;
        final List<ScreenshotEntity> all =
            loaded?.reminders ?? const <ScreenshotEntity>[];

        // Split here rather than on the state: which side of the line a
        // reminder falls on is a fact about the clock, and read here it is as
        // old as this frame instead of as old as the last library load.
        final DateTime now = DateTime.now();
        final List<ScreenshotEntity> missed = <ScreenshotEntity>[
          for (final ScreenshotEntity item in all)
            if (!item.remindAt!.isAfter(now)) item,
        ];
        final List<ScreenshotEntity> upcoming = <ScreenshotEntity>[
          for (final ScreenshotEntity item in all)
            if (item.remindAt!.isAfter(now)) item,
        ];

        return Scaffold(
          backgroundColor: context.colors.background,
          appBar: AppBar(
            backgroundColor: context.colors.background,
            elevation: 0,
            iconTheme: IconThemeData(color: context.colors.textPrimary),
            title: Text(
              context.l10n.remindersTitle,
              style: context.text.titleLarge,
            ),
          ),
          body: SafeArea(
            child:
                blocked ??
                (all.isEmpty
                    ? EmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: context.l10n.remindersNoneTitle,
                        message: context.l10n.remindersNoneBody,
                      )
                    : ListView(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          20.w,
                          4.h,
                          20.w,
                          120.h,
                        ),
                        children: <Widget>[
                          // **Missed first, and only when there are some.** An
                          // empty heading is a section that says nothing but
                          // still costs a row.
                          if (missed.isNotEmpty) ...<Widget>[
                            _Heading(
                              label: context.l10n.remindersMissed,
                              color: context.colors.error,
                            ),
                            for (final ScreenshotEntity item in missed)
                              _ReminderRow(item: item, isMissed: true),
                          ],
                          if (missed.isNotEmpty && upcoming.isNotEmpty)
                            SizedBox(height: 18.h),
                          if (upcoming.isNotEmpty) ...<Widget>[
                            _Heading(label: context.l10n.remindersUpcoming),
                            for (final ScreenshotEntity item in upcoming)
                              _ReminderRow(item: item, isMissed: false),
                          ],
                        ],
                      )),
          ),
        );
      },
    );
  }
}

class _Heading extends StatelessWidget {
  final String label;
  final Color? color;

  const _Heading({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(4.w, 12.h, 4.w, 8.h),
      child: Text(
        label.toUpperCase(),
        style: context.text.caption.copyWith(
          color: color ?? context.colors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// One reminder: the picture, when it is due, and a way to be rid of it.
///
/// **The clear button is not a convenience.** A missed reminder stays in this
/// list until something removes it, and the only other way to remove one is to
/// find that screenshot in the grid and long-press it — which is the exact
/// problem this screen exists to solve. A list you cannot empty becomes a
/// second pile.
class _ReminderRow extends StatelessWidget {
  final ScreenshotEntity item;
  final bool isMissed;

  const _ReminderRow({required this.item, required this.isMissed});

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations l = MaterialLocalizations.of(context);
    final DateTime at = item.remindAt!;
    final String when =
        '${l.formatMediumDate(at)}, ${l.formatTimeOfDay(TimeOfDay.fromDateTime(at))}';

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: PressableScale(
        feedback: PressFeedback.highlight,
        semanticLabel: '${context.l10n.remindersTitle}, $when',
        onTap: () => _open(context),
        child: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isMissed
                  ? context.colors.error.withValues(alpha: 0.35)
                  : context.colors.border,
            ),
          ),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: SizedBox(
                  width: 52.w,
                  height: 52.w,
                  child: AssetThumbnailImage(asset: item.asset),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      when,
                      style: context.text.bodyMedium.copyWith(
                        color: isMissed
                            ? context.colors.error
                            : context.colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isMissed
                          ? context.l10n.remindersMissed
                          : context.l10n.remindersUpcoming,
                      style: context.text.caption.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.remindersClearOne,
                icon: Icon(
                  Icons.close_rounded,
                  size: 20.sp,
                  color: context.colors.textSecondary,
                ),
                onPressed: () => _clear(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clear(BuildContext context) async {
    final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
    await sl<SetReminderUseCase>().call(item.id, null);
    // The reminder lives on the same row as the folder and the favourite, so
    // the library has to be re-read for this list to lose the item.
    bloc.add(LoadScreenshotsEvent());
  }

  void _open(BuildContext context) {
    final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
    final ScreenshotsState state = bloc.state;
    if (state is! ScreenshotsLoadedState) return;

    final int at = state.screenshots.indexWhere(
      (ScreenshotEntity s) => s.id == item.id,
    );
    if (at < 0) return;

    Navigator.of(context).push(
      PhotoViewerRoute(
        builder: (_) => BlocProvider<ScreenshotsBloc>.value(
          value: bloc,
          child: ScreenshotDetailPage(
            screenshots: state.screenshots,
            initialIndex: at,
          ),
        ),
      ),
    );
  }
}
