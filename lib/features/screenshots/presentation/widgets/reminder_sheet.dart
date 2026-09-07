import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/services/reminders.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/utils/reminder_schedule.dart';
import 'package:shoto/core/utils/reminder_times.dart';
import 'package:shoto/core/widgets/app_snack_bar.dart';
import 'package:shoto/core/widgets/asset_thumbnail_image.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/use_cases/set_reminder_use_case.dart';
import 'package:shoto/features/screenshots/presentation/widgets/reminder_time_sheet.dart';

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
    // **Permission to be its own size, which it did not have.**
    //
    // A plain sheet is capped at about half the screen. This one measured 368
    // logical pixels against a cap of 368.1 — a tenth of a pixel of headroom,
    // in English, at the default text size. At 1.3× it burst, and it would
    // have burst on any phone shorter than the one it was drawn on, or the
    // first time a fifth preset was added. Scroll-controlled changes nothing
    // about the ordinary case: the content is still `MainAxisSize.min`, so
    // the sheet is still exactly as tall as its rows.
    isScrollControlled: true,
    builder: (sheetContext) => SheetSurface(
      child: _ReminderSheet(item: item, onChanged: onChanged),
    ),
  );
}

/// One reminder, or a band of them, taken off — and offered back.
///
/// **Three places clear a reminder and there is one way to do it.** The row's
/// ✕, the sheet's "Remove reminder", and the bulk clear on the missed heading
/// were all going to need the same four steps: write the change, tell the
/// library, say what happened, and keep the way back on screen. Written three
/// times, the third one is where the undo quietly goes missing — which is
/// exactly what had already happened to the sheet's copy before this existed.
///
/// **Undo rather than a confirmation.** A dialog charges every deliberate
/// removal for the rare accident, and asks its question at the moment the user
/// is least interested in it. This is cheap to offer because the thing being
/// restored is one value per screenshot, which the caller is already holding.
///
/// The restore goes back through [SetReminderUseCase] rather than writing the
/// row directly: that is what re-arms the alarm, so an undone removal is a
/// working reminder again and not a date sitting in a database.
Future<void> removeRemindersWithUndo(
  BuildContext context,
  List<({String assetId, DateTime was})> cleared, {
  VoidCallback? onChanged,
}) async {
  if (cleared.isEmpty) return;

  final AppLocalizations l10n = context.l10n;

  for (final ({String assetId, DateTime was}) one in cleared) {
    await sl<SetReminderUseCase>().call(one.assetId, null);
  }
  onChanged?.call();

  if (!context.mounted) return;
  showAppSnackBar(
    context,
    l10n.remindersRemoved(cleared.length),
    actionLabel: l10n.commonUndo,
    onAction: () async {
      for (final ({String assetId, DateTime was}) one in cleared) {
        await sl<SetReminderUseCase>().call(
          one.assetId,
          one.was,
          title: l10n.reminderNotificationTitle,
          body: l10n.reminderNotificationBody,
        );
      }
      onChanged?.call();
    },
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
      // The backstop under [showReminderSheet]'s scroll-controlled cap: with
      // room to spare this is sized by its content and does not scroll, and
      // on a short phone at a large text size it moves rather than overflows.
      // The quick-actions sheet this one opens from takes the same pair.
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(item: item),
              SizedBox(height: 6.h),
              for (final ReminderPreset preset in presets)
                _Row(
                  icon: _iconFor(preset),
                  label: _labelFor(context, preset),
                  detail: _presetWhen(
                    context,
                    resolveReminder(preset, now),
                    now,
                  ),
                  onTap: () => _set(context, resolveReminder(preset, now)),
                ),
              // **A gap rather than a rule, and it is the last thing on this
              // sheet that needed separating.** The four above are answers;
              // this one is a door to somewhere the answer gets composed. A
              // second divider in a six-row sheet would have ruled it into
              // thirds, and the chevron already says what kind of row it is.
              SizedBox(height: 4.h),
              _Row(
                // Not `event_rounded`, which is a calendar page and was very
                // nearly the same glyph as the `date_range_rounded` on "Next
                // week" directly above it — two near-identical icons on two
                // rows that do entirely different things. A clock with a plus
                // is the ordinary sign for a time you are about to specify.
                icon: Icons.more_time_rounded,
                label: context.l10n.reminderPickTime,
                // The one row here that opens something rather than deciding
                // something. Without it, a sheet of five identical rows gives
                // no warning that the fifth is a detour.
                leadsOn: true,
                onTap: () => _pick(context),
              ),
              if (item.remindAt != null) ...[
                SizedBox(height: 4.h),
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
      ),
    );
  }

  /// A preset's moment, at the precision its own label has not already given.
  ///
  /// **Every row said the date, and for four rows out of five the date was
  /// what the row was called.** "Later today — Tue, Aug 18, 4:54 PM"; "This
  /// evening — Tue, Aug 18, 7:00 PM"; "Tomorrow morning — Wed, Aug 19, 9:00
  /// AM". The label names the day and then the value names it again, in a
  /// column of five near-identical grey strings where the only part that
  /// differed — the time — was the last thing on each line and the hardest to
  /// compare.
  ///
  /// This is safe rather than merely shorter, and [isPresetOffered] is why: a
  /// preset whose words have stopped naming the day it lands on is taken off
  /// the sheet entirely, so a label that says "today" is on screen only when
  /// the moment really is today.
  ///
  /// The rule is [reminderBandFor], the same one the reminders list bands by,
  /// rather than a switch over [ReminderPreset]. A preset added or retimed
  /// later gets the right amount of detail without anybody remembering to come
  /// back here — and "next week", seven days out, lands in [ReminderBand.later]
  /// and keeps its date, because there the day is the whole news.
  String _presetWhen(BuildContext context, DateTime at, DateTime now) {
    final MaterialLocalizations l = MaterialLocalizations.of(context);
    final String clock = l.formatTimeOfDay(TimeOfDay.fromDateTime(at));

    return switch (reminderBandFor(at, now: now)) {
      ReminderBand.today || ReminderBand.tomorrow => clock,
      ReminderBand.thisWeek ||
      ReminderBand.later ||
      // Unreachable from a preset, which always resolves into the future —
      // written out rather than left to a wildcard, like the rest of this app's
      // switches, so adding a band is a compile error and not a silent case.
      ReminderBand.missed => '${l.formatMediumDate(at)}, $clock',
    };
  }

  /// A date and a time, in the reader's own conventions.
  ///
  /// For the one moment on this sheet that has no label above it carrying half
  /// of it — see [_Header] and [_presetWhen].
  ///
  /// `MaterialLocalizations` rather than seven hand-written formats, the same
  /// reasoning as the thumbnail's accessibility label.
  String _when(BuildContext context, DateTime at) {
    final MaterialLocalizations l = MaterialLocalizations.of(context);
    return '${l.formatMediumDate(at)}, ${l.formatTimeOfDay(TimeOfDay.fromDateTime(at))}';
  }

  /// The custom day-and-time sheet — see [showReminderTimeSheet], which
  /// replaced a date dialog followed by a clock face.
  Future<void> _pick(BuildContext context) async {
    final DateTime? at = await showReminderTimeSheet(context);
    if (at == null || !context.mounted) return;

    // **A backstop, and honestly labelled as one.**
    //
    // The picker now refuses a past moment twice over — its wheels will not
    // settle behind the earliest allowed minute, and its button re-reads the
    // clock before returning — so in practice this cannot fire. It stays
    // because arming a reminder for a moment already gone is the failure that
    // either rings instantly or never rings at all, and one comparison is a
    // cheap price for never doing it.
    //
    // The message belongs on the picker rather than here: a snack bar posted
    // while a sheet is up renders into the page's `Scaffold`, underneath the
    // panel covering the bottom of the screen, where nobody sees it.
    if (!at.isAfter(DateTime.now())) {
      showAppSnackBar(context, context.l10n.reminderPastTime);
      return;
    }
    await _set(context, at);
  }

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

    // **Removing is not "setting to null", and treating it as one is how this
    // path lost its undo.** Everything below is about a reminder that now
    // exists and wants announcing; a removal is the opposite event, and the
    // one thing it owes the user is a way back.
    if (at == null) {
      final DateTime? was = item.remindAt;
      navigator.pop();
      if (was == null || !context.mounted) return;
      await removeRemindersWithUndo(context, <({String assetId, DateTime was})>[
        (assetId: item.id, was: was),
      ], onChanged: onChanged);
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
    if (!context.mounted) return;

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

/// The screenshot the sheet is about, over what is already set for it.
///
/// **"Remind me about this" — and *this* was not on screen.** The sheet is
/// reached three ways, and every one of them puts it over the thing it is
/// asking about: a long-press in the grid raises it across the tile, the
/// reminders list raises it across the row that was tapped, and the viewer
/// raises it across the picture. So the demonstrative pointed at whatever the
/// panel had just covered.
///
/// A thumbnail is a smaller answer than rewording the title in eight
/// languages, and a better one: it is the same picture at the same size the
/// reminders list uses, so somebody arriving from there sees the row they
/// tapped continue into the sheet rather than disappear behind it.
class _Header extends StatelessWidget {
  final ScreenshotEntity item;

  const _Header({required this.item});

  @override
  Widget build(BuildContext context) {
    final DateTime? pending = item.hasPendingReminder ? item.remindAt : null;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20.w, 6.h, 20.w, 6.h),
      child: Row(
        children: <Widget>[
          // **Trailing, and that is not a preference.** Led with, it pushed
          // the title 22 pixels further in than every label under it, so the
          // sheet had two left edges and its heading started on neither the
          // margin nor the rows. A title belongs on the margin; the picture is
          // what the title is about, and it can sit at the other end.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  context.l10n.reminderTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.headlineMedium,
                ),
                // What is already set, if anything — so the sheet answers
                // "when is it coming?" before offering to change it. In full,
                // because this is the one moment here with no label above it
                // carrying the day.
                if (pending != null) ...<Widget>[
                  SizedBox(height: 2.h),
                  Text(
                    context.l10n.reminderPending(_when(context, pending)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 14.w),
          // Silent to a screen reader: it is the subject of the title beside
          // it, not a second thing to stop on.
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 42.w,
                height: 42.w,
                child: AssetThumbnailImage(
                  asset: item.asset,
                  background: context.colors.surfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _when(BuildContext context, DateTime at) {
    final MaterialLocalizations l = MaterialLocalizations.of(context);
    return '${l.formatMediumDate(at)}, ${l.formatTimeOfDay(TimeOfDay.fromDateTime(at))}';
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;

  /// The moment the label resolves to, spelled out.
  ///
  /// A preset is a promise about a time, and showing the time next to it is
  /// what stops "later today" being a guess the user has to make about the
  /// app's opinion. How much of the moment gets said is [_presetWhen]'s
  /// business, not this widget's.
  final String? detail;

  /// Whether this row opens another surface rather than settling the question.
  ///
  /// Draws the chevron every list in this app uses for the same promise. It is
  /// the only difference in weight the sheet needs: a row that decides and a
  /// row that navigates should not be indistinguishable.
  final bool leadsOn;

  final Color? iconColor;
  final VoidCallback onTap;

  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.detail,
    this.leadsOn = false,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium.copyWith(
                  color: iconColor ?? context.colors.textPrimary,
                ),
              ),
            ),
            // **The label is the half that gives way, and that is deliberate.**
            //
            // It is `Expanded` and this is not, so when the two cannot both
            // fit, the words shrink and the moment stays whole. That is the
            // right way round: "La semaine prochai…" is still plainly next
            // week, where "mer. 25 sept., 09:…" is a time nobody can act on.
            //
            // It bites in French, Italian and Portuguese at the 1.3× text
            // size, on the one row carrying a date — and no arrangement of
            // this row avoids it. Dropping the weekday buys about four pixels
            // of the forty it is over, at the cost of this sheet printing a
            // date differently from every other surface in the app.
            if (detail != null) ...<Widget>[
              SizedBox(width: 10.w),
              Text(
                detail!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall.copyWith(
                  color: context.colors.textSecondary,
                  // The four times sit in a column and are read against each
                  // other. Proportional digits put "9:00 AM" and "11:45 AM" on
                  // different rhythms and the comparison becomes work.
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
            if (leadsOn) ...<Widget>[
              SizedBox(width: 6.w),
              Icon(
                Icons.chevron_right_rounded,
                size: 18.sp,
                color: context.colors.textDisabled,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
