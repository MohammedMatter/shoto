import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/services/reminders.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/reminder_times.dart';
import 'package:shoto/core/widgets/app_snack_bar.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/use_cases/set_reminder_use_case.dart';

/// Asks when to bring a screenshot back.
///
/// **The gap this closes.** The app already knows what somebody meant to *do*
/// with a picture — they said so in one tap when they saved it — and it could
/// only ever show that back to them when they opened the app and looked. That
/// is a to-do list with no alarm clock, and the screenshots that most need one
/// are exactly the ones nobody reopens the app to find.
///
/// Four presets and a picker. The presets are relative and land on round hours
/// (see [resolveReminder]) because this is used one-handed in the second after
/// deciding to deal with something later, and "19:00" is a time somebody can
/// plan around where "in three hours" is an interruption.
///
/// An option whose words have stopped being true is **removed rather than
/// quietly redefined**: "this evening", tapped at eleven at night, would mean
/// tomorrow evening. See [isPresetOffered].
Future<void> showReminderSheet(
  BuildContext context,
  ScreenshotEntity item, {
  VoidCallback? onChanged,
}) {
  return showAppSheet<void>(
    context: context,
    builder: (sheetContext) => SheetSurface(
      child: _ReminderSheet(item: item, onChanged: onChanged),
    ),
  );
}

class _ReminderSheet extends StatelessWidget {
  final ScreenshotEntity item;
  final VoidCallback? onChanged;

  const _ReminderSheet({required this.item, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final List<ReminderPreset> presets = offeredPresets(now);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(20.w, 6.h, 20.w, 4.h),
              child: Text(
                context.l10n.reminderTitle,
                style: context.text.headlineMedium,
              ),
            ),
            // What is already set, if anything — so the sheet answers "when is
            // it coming?" before offering to change it.
            if (item.hasPendingReminder)
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20.w, 0, 20.w, 8.h),
                child: Text(
                  context.l10n.reminderPending(_when(context, item.remindAt!)),
                  style: context.text.bodySmall.copyWith(
                    color: context.colors.primary,
                  ),
                ),
              ),
            SizedBox(height: 6.h),
            for (final ReminderPreset preset in presets)
              _Row(
                icon: _iconFor(preset),
                label: _labelFor(context, preset),
                detail: _when(context, resolveReminder(preset, now)),
                onTap: () => _set(context, resolveReminder(preset, now)),
              ),
            _Row(
              icon: Icons.event_rounded,
              label: context.l10n.reminderPickTime,
              onTap: () => _pick(context, now),
            ),
            if (item.remindAt != null) ...[
              Divider(height: 1, color: context.colors.border),
              _Row(
                icon: Icons.notifications_off_outlined,
                iconColor: context.colors.error,
                label: context.l10n.reminderClear,
                onTap: () => _set(context, null),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// A date and a time, in the reader's own conventions.
  ///
  /// `MaterialLocalizations` rather than seven hand-written formats, the same
  /// reasoning as the thumbnail's accessibility label.
  String _when(BuildContext context, DateTime at) {
    final MaterialLocalizations l = MaterialLocalizations.of(context);
    return '${l.formatMediumDate(at)}, ${l.formatTimeOfDay(TimeOfDay.fromDateTime(at))}';
  }

  Future<void> _pick(BuildContext context, DateTime now) async {
    final DateTime? day = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      // Far enough to be no limit in practice, near enough that a mis-scroll
      // cannot set a reminder for the next century.
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (day == null || !context.mounted) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: _openTimeAt(day),
    );
    if (time == null || !context.mounted) return;

    final DateTime at = DateTime(
      day.year,
      day.month,
      day.day,
      time.hour,
      time.minute,
    );

    // **A moment already gone gets said out loud.**
    //
    // This used to `return` in silence, on the reasoning that the user can see
    // the date they chose. They cannot see *why nothing happened*, and the
    // report that came back was exactly that: "it won't make a reminder for
    // today". Nothing in the app is more corrosive than a control that answers
    // a deliberate tap by doing nothing at all — it reads as broken, and there
    // is no way for the user to find out otherwise.
    //
    // The sheet deliberately stays open, so the correction costs one tap
    // rather than a second trip through both pickers.
    if (!at.isAfter(DateTime.now())) {
      showAppSnackBar(context, context.l10n.reminderPastTime);
      return;
    }
    await _set(context, at);
  }

  /// What the clock face opens on — see [pickerOpensAt] for why it is not a
  /// constant.
  TimeOfDay _openTimeAt(DateTime day) =>
      TimeOfDay.fromDateTime(pickerOpensAt(day, DateTime.now()));

  Future<void> _set(BuildContext context, DateTime? at) async {
    final NavigatorState navigator = Navigator.of(context);
    final AppLocalizations l10n = context.l10n;

    if (at != null && !Reminders.isSupported) {
      navigator.pop();
      if (context.mounted) {
        showAppSnackBar(context, l10n.reminderUnsupported);
      }
      return;
    }

    final bool visible = await sl<SetReminderUseCase>().call(
      item.id,
      at,
      title: l10n.reminderNotificationTitle,
      body: l10n.reminderNotificationBody,
    );

    onChanged?.call();
    navigator.pop();
    if (!context.mounted || at == null) return;

    // **Two different sentences, and the difference is the point.** A reminder
    // set while Shoto's notifications are switched off is armed and will never
    // be seen, which is worth saying now rather than leaving somebody to
    // discover it by not being reminded.
    showAppSnackBar(
      context,
      visible ? l10n.reminderSet(_when(context, at)) : l10n.reminderMuted,
      kind: visible ? SnackKind.success : SnackKind.neutral,
    );
  }

  static IconData _iconFor(ReminderPreset preset) => switch (preset) {
    ReminderPreset.laterToday => Icons.hourglass_bottom_rounded,
    ReminderPreset.thisEvening => Icons.nightlight_round,
    ReminderPreset.tomorrowMorning => Icons.wb_sunny_rounded,
    ReminderPreset.nextWeek => Icons.date_range_rounded,
  };

  static String _labelFor(BuildContext context, ReminderPreset preset) =>
      switch (preset) {
        ReminderPreset.laterToday => context.l10n.reminderLaterToday,
        ReminderPreset.thisEvening => context.l10n.reminderThisEvening,
        ReminderPreset.tomorrowMorning => context.l10n.reminderTomorrow,
        ReminderPreset.nextWeek => context.l10n.reminderNextWeek,
      };
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;

  /// The moment the label resolves to, spelled out.
  ///
  /// A preset is a promise about a time, and showing the time next to it is
  /// what stops "later today" being a guess the user has to make about the
  /// app's opinion.
  final String? detail;
  final Color? iconColor;
  final VoidCallback onTap;

  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.detail,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      feedback: PressFeedback.highlight,
      semanticLabel: detail == null ? label : '$label, $detail',
      onTap: onTap,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(20.w, 13.h, 20.w, 13.h),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: iconColor ?? context.colors.textSecondary,
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                label,
                style: context.text.bodyMedium.copyWith(
                  color: iconColor ?? context.colors.textPrimary,
                ),
              ),
            ),
            if (detail != null)
              Text(
                detail!,
                style: context.text.bodySmall.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
