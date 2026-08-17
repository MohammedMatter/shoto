import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/reminder_times.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/core/widgets/wheel_picker.dart';

/// Picks the day and the time for a reminder, on one surface.
///
/// **What this replaced, and why it had to go.** "Pick a time" used to open
/// `showDatePicker`, wait for an answer, and then open `showTimePicker` — a
/// month grid followed by a clock face, two modal dialogs deep, to say
/// "tomorrow at seven". Three things were wrong with it, and only the third is
/// about looks:
///
/// 1. **A clock face asks the wrong question.** The user is thinking of a
///    number and the dial wants an angle, dragged with a fingertip that covers
///    the very digit it is setting. Minutes cannot even be reached until the
///    hour has been committed, so a five-minute correction is a round trip.
/// 2. **Nothing stopped an impossible answer until it was too late.** The
///    pickers happily accepted a moment in the past and the app had to refuse
///    it afterwards with a snackbar — the user does the work, then gets told
///    off. Here the floor is drawn *on the control*: past values are dimmed,
///    and a wheel released past them slides back to the earliest one there is.
///    The sheet cannot return a time it would have to reject.
/// 3. **Two dialogs, neither of them Shoto's.** They arrived on Material's
///    surfaces, Material's timings and Material's shapes, in the middle of an
///    app that builds all three itself.
///
/// The composition is one screenful and reads top to bottom in the order the
/// decision is actually made: which day, then what time, then commit. Nothing
/// is behind a step.
///
/// Returns the chosen moment, or null if the sheet was dismissed. **What comes
/// back is always in the future**, and both halves of that are enforced here:
/// the wheels cannot be left on a moment behind the floor, and the button
/// re-reads the clock before it hands anything over, in case the sheet has
/// been sitting open long enough for its own answer to expire. See [_confirm].
Future<DateTime?> showReminderTimeSheet(
  BuildContext context, {
  DateTime Function() clock = DateTime.now,
}) {
  return showAppSheet<DateTime>(
    context: context,
    // Taller than half the screen, which is all a plain sheet is allowed. Not
    // *scrolling* — the whole point is that everything is reachable at once —
    // it simply needs permission to be its own size.
    isScrollControlled: true,
    builder: (BuildContext sheetContext) =>
        SheetSurface(child: _ReminderTimeSheet(clock: clock)),
  );
}

class _ReminderTimeSheet extends StatefulWidget {
  /// **The sheet's only source of time**, and a function rather than a moment
  /// because it is read exactly twice: once when the sheet opens, to set the
  /// floor, and once when the button is pressed, to check that floor has not
  /// gone stale.
  ///
  /// It was a plain `DateTime` first, and that quietly gave the sheet *two*
  /// clocks — the one it was handed and the real one it reached for on
  /// confirm. Fine in the app, where they agree; in a test, where the point of
  /// passing a time is that it is a fixed one in another month, the confirm
  /// read compared against today and refused every choice. A widget with two
  /// notions of "now" is a widget that cannot be tested at either of them.
  final DateTime Function() clock;

  const _ReminderTimeSheet({required this.clock});

  @override
  State<_ReminderTimeSheet> createState() => _ReminderTimeSheetState();
}

class _ReminderTimeSheetState extends State<_ReminderTimeSheet> {
  /// The moment the floor is measured from.
  ///
  /// Read once when the sheet opens, and moved only when [_confirm] catches
  /// the sheet's own answer having expired. It is deliberately **not** live: a
  /// floor that advanced once a minute would creep upward under a finger
  /// resting on it, and a wheel that shoves the user's choice along is worse
  /// than one that is a minute out of date.
  late DateTime _now = widget.clock();

  /// The days on the strip. Grows by at most one, when somebody picks a date
  /// from the calendar that is further out than the strip reaches.
  late final List<DateTime> _days = reminderDays(_now);

  late DateTime _day = _days.first;
  late int _hour = _opening.hour;
  late int _minute = _opening.minute;

  late final DateTime _opening = openingChoice(_day, _now);

  /// Set when a press on the button arrived after the chosen moment had gone.
  ///
  /// Says so in place of the date line rather than through a snack bar, and
  /// that is a fix rather than a preference: `ScaffoldMessenger` renders into
  /// the page's `Scaffold`, which is *underneath* this sheet — a message about
  /// the bottom of the screen, posted behind the panel covering the bottom of
  /// the screen. The refusal was invisible, which is the exact failure the
  /// message was added to prevent.
  bool _expired = false;

  final ScrollController _strip = ScrollController();

  /// Attached to whichever chip is currently selected, so a day chosen from
  /// the calendar can be scrolled into view without knowing how wide any chip
  /// turned out to be.
  final GlobalKey _selectedChip = GlobalKey();

  /// Read once, in [didChangeDependencies], because it decides how many items
  /// the hour wheel has and therefore what its controller's initial item
  /// means. A device whose clock format changes while a bottom sheet is open
  /// is not a case worth a rebuild path.
  bool _use24 = false;
  bool _ready = false;

  late final FixedExtentScrollController _hours;
  late final FixedExtentScrollController _minutes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _use24 = MediaQuery.alwaysUse24HourFormatOf(context);
    _hours = FixedExtentScrollController(initialItem: _hourIndex);
    _minutes = FixedExtentScrollController(initialItem: _minute);
    _ready = true;
  }

  @override
  void dispose() {
    _strip.dispose();
    if (_ready) {
      _hours.dispose();
      _minutes.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------------------- the floor
  //
  // Everything below reads [earliestChoiceOn] and nothing computes its own
  // idea of "too early". For any day but today it answers midnight, which is
  // what makes every test here branch-free: `hour >= 0` and `minute >= 0` are
  // true, so a future day disables nothing without a single `if`.

  DateTime get _floor => earliestChoiceOn(_day, _now);

  bool _hourAllowed(int hour24) => hour24 >= _floor.hour;

  bool _minuteAllowed(int minute) =>
      _hour > _floor.hour || minute >= _floor.minute;

  bool get _amAllowed => _floor.hour < 12;

  /// Pulls the choice up to the earliest allowed moment when it has fallen
  /// behind it — after a wheel is released, or after a day is chosen that has
  /// less of itself left than the last one did.
  ///
  /// The wheels are declarative: setting the state here is what makes them
  /// animate, and they suppress their own detent haptic while they travel. A
  /// correction the user did not ask for should not feel like one they made.
  void _enforceFloor() {
    if (!composeReminder(_day, _hour, _minute).isBefore(_floor)) return;
    setState(() {
      _hour = _floor.hour;
      _minute = _floor.minute;
    });
  }

  // ------------------------------------------------------- hour index maths
  //
  // The wheel's index is not the hour. In 24-hour mode they coincide; in
  // 12-hour mode the wheel holds twelve rows reading 12, 1, 2 … 11, so row 0
  // is midnight or noon depending on the period beside it.

  int get _hourIndex => _use24 ? _hour : _hour % 12;

  bool get _isPm => _hour >= 12;

  int _hourFor(int index) => _use24 ? index : index + (_isPm ? 12 : 0);

  void _onHourIndex(int index) {
    final int hour = _hourFor(index);
    if (hour == _hour) return;
    setState(() {
      _hour = hour;
      _touched();
    });
  }

  void _onMinute(int minute) {
    if (minute == _minute) return;
    setState(() {
      _minute = minute;
      _touched();
    });
  }

  void _setPeriod({required bool pm}) {
    if (pm == _isPm) return;
    setState(() {
      _hour = pm ? _hour + 12 : _hour - 12;
      _touched();
    });
    _enforceFloor();
  }

  void _selectDay(DateTime day) {
    setState(() {
      _day = day;
      _touched();
    });
    _enforceFloor();
    _revealSelectedChip();
  }

  void _revealSelectedChip() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? chip = _selectedChip.currentContext;
      if (chip == null || !mounted) return;
      Scrollable.ensureVisible(
        chip,
        duration: AppMotion.duration(context, AppMotion.normal),
        curve: AppMotion.standard,
        // Kept off the edge of the strip, so the chosen day never looks like
        // the last one there is.
        alignment: 0.5,
      );
    });
  }

  /// The way out for anything further off than the strip reaches.
  ///
  /// **Material's calendar is kept on purpose.** A month grid is the right
  /// instrument for a date and there is nothing wrong with this one — the
  /// complaint was never the calendar, it was being sent through a calendar to
  /// set a time three hours from now. Behind the fourteenth chip it is where a
  /// rare answer belongs, and rewriting it would be a month of work to arrive
  /// back where we started.
  Future<void> _openCalendar() async {
    final DateTime? day = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: _days.first,
      // Far enough to be no limit in practice, near enough that a mis-scroll
      // cannot set a reminder for the next century.
      lastDate: DateTime(_now.year + 2, _now.month, _now.day),
    );
    if (day == null || !mounted) return;

    final DateTime picked = DateTime(day.year, day.month, day.day);
    if (!_days.any((DateTime d) => isSameDay(d, picked))) {
      // Appended rather than inserted in date order: it is the one day on the
      // strip the user typed out by hand, and putting it at the end means it
      // is always the chip nearest the calendar button they just used.
      setState(() => _days.add(picked));
    }
    _selectDay(picked);
  }

  /// **The one moment the clock is read again.**
  ///
  /// Everything above is measured against the [_now] the sheet opened with,
  /// which is what keeps the floor still while somebody is choosing. That
  /// leaves exactly one hole, and it is a real one: a sheet left open through
  /// a conversation is a sheet whose own answer has quietly expired, and
  /// pressing the button would arm a reminder for a minute already gone.
  ///
  /// So the press re-reads the clock. If the choice still stands it is
  /// returned; if it does not, the sheet takes the new time as its floor,
  /// slides the wheels up to the earliest minute there is, and says why. The
  /// second press is the one that works, and it costs a tap rather than a trip
  /// back through the whole flow.
  void _confirm() {
    final DateTime at = composeReminder(_day, _hour, _minute);
    final DateTime fresh = widget.clock();
    if (at.isAfter(fresh)) {
      Navigator.of(context).pop(at);
      return;
    }

    setState(() {
      _now = fresh;
      _expired = true;
      // Rebuilt because a sheet can be left open across midnight, and the day
      // it is sitting on may not be offered any more. Without this the floor
      // would be a midnight in the past and every further press would be
      // refused for the same reason, forever.
      _days
        ..clear()
        ..addAll(reminderDays(fresh));
      if (!_days.any((DateTime day) => isSameDay(day, _day))) {
        _day = _days.first;
      }
    });
    _enforceFloor();
  }

  /// Any deliberate change clears the warning — it was about a choice that is
  /// no longer the one on screen.
  void _touched() {
    if (_expired) _expired = false;
  }

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations material = MaterialLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(20.w, 6.h, 20.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.reminderPickTime,
                    style: context.text.headlineMedium,
                  ),
                  SizedBox(height: 2.h),
                  // The answer in full, spelled out by the platform in the
                  // reader's own conventions. The strip says "Wed"; this is
                  // what stops a chip two weeks out being a guess about which
                  // Wednesday.
                  //
                  // It is also where the sheet says a choice has expired,
                  // rather than adding a second line that is blank most of the
                  // time — the date and the reason it cannot be used are the
                  // same fact about the same moment.
                  Text(
                    _expired
                        ? context.l10n.reminderPastTime
                        : material.formatFullDate(_day),
                    style: context.text.bodySmall.copyWith(
                      color: _expired ? context.colors.error : null,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            _DayStrip(
              days: _days,
              selected: _day,
              now: _now,
              controller: _strip,
              selectedKey: _selectedChip,
              onSelect: _selectDay,
              onCalendar: _openCalendar,
            ),
            SizedBox(height: 6.h),
            if (_ready) _clock(context, material),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(20.w, 8.h, 20.w, 4.h),
              child: PrimaryButton(
                label: context.l10n.reminderConfirm,
                onPressed: _confirm,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clock(BuildContext context, MaterialLocalizations material) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20.w, 0, 20.w, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // **Always left-to-right, in every locale.** A digital clock reads
          // hour-then-minute the world over, including in scripts that read
          // the other way; letting the row mirror would put the minutes where
          // the hours belong and quietly make 9:05 into 5:09.
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              height: WheelPicker.height,
              width: WheelPicker.columnWidth * 2 + _colonWidth,
              child: Stack(
                children: [
                  const Positioned.fill(child: WheelSelectionBand()),
                  Row(
                    children: [
                      SizedBox(
                        width: WheelPicker.columnWidth,
                        child: WheelPicker(
                          controller: _hours,
                          count: _use24 ? 24 : 12,
                          selected: _hourIndex,
                          semanticLabel: material.timePickerHourLabel,
                          label: _hourLabel,
                          enabled: (int index) => _hourAllowed(_hourFor(index)),
                          onChanged: _onHourIndex,
                          onSettled: (_) => _enforceFloor(),
                        ),
                      ),
                      SizedBox(
                        width: _colonWidth,
                        child: Center(
                          child: Text(':', style: _separator(context)),
                        ),
                      ),
                      SizedBox(
                        width: WheelPicker.columnWidth,
                        child: WheelPicker(
                          controller: _minutes,
                          count: 60,
                          selected: _minute,
                          semanticLabel: material.timePickerMinuteLabel,
                          label: _minuteLabel,
                          enabled: _minuteAllowed,
                          onChanged: _onMinute,
                          onSettled: (_) => _enforceFloor(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!_use24) ...[
            SizedBox(width: 14.w),
            _PeriodSelector(
              isPm: _isPm,
              amEnabled: _amAllowed,
              am: material.anteMeridiemAbbreviation,
              pm: material.postMeridiemAbbreviation,
              onChanged: (bool pm) => _setPeriod(pm: pm),
            ),
          ],
        ],
      ),
    );
  }

  /// Room for the colon and no more. Wide enough to breathe, narrow enough
  /// that the two figures stay one time rather than two numbers.
  double get _colonWidth => 22.w;

  TextStyle _separator(BuildContext context) => context.text.mono.copyWith(
    fontSize: 20.sp,
    color: context.colors.textSecondary,
  );

  /// Padded in 24-hour mode and bare in 12-hour mode, which is how each format
  /// is written everywhere else: 09:30, and 9:30 AM. Row 0 of the twelve-hour
  /// wheel reads "12", because no clock has ever had a nought on it.
  String _hourLabel(int index) =>
      _use24 ? _twoDigits(index) : (index == 0 ? '12' : '$index');

  String _minuteLabel(int minute) => _twoDigits(minute);

  /// **ASCII digits, and that is a limit worth stating.** Every language Shoto
  /// ships in writes numbers in Latin figures, so padding with a `'0'` is
  /// correct for all seven. Add a locale that uses Eastern Arabic or
  /// Devanagari numerals and this is the line that has to change — padding
  /// `٧` with `0` would produce `0٧`, which is not a time in any script.
  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

/// The days, as a row of chips.
///
/// **Fourteen chips and a calendar, rather than a calendar.** A reminder set
/// from a screenshot is nearly always inside the next couple of weeks — come
/// back to this receipt, this address, this booking — and for those the day is
/// now one tap rather than a modal, a month grid and a confirm. The calendar
/// at the end is what keeps the rare answer possible without letting it set
/// the shape of the common one.
class _DayStrip extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;
  final DateTime now;
  final ScrollController controller;
  final GlobalKey selectedKey;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onCalendar;

  const _DayStrip({
    required this.days,
    required this.selected,
    required this.now,
    required this.controller,
    required this.selectedKey,
    required this.onSelect,
    required this.onCalendar,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62.h,
      child: ListView.separated(
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsetsDirectional.symmetric(horizontal: 20.w),
        itemCount: days.length + 1,
        separatorBuilder: (BuildContext context, int _) =>
            SizedBox(width: 8.w),
        itemBuilder: (BuildContext context, int index) {
          if (index == days.length) {
            return _CalendarChip(onTap: onCalendar);
          }
          final DateTime day = days[index];
          final bool isSelected = isSameDay(day, selected);
          return _DayChip(
            key: isSelected ? selectedKey : null,
            day: day,
            now: now,
            isSelected: isSelected,
            onTap: () => onSelect(day),
          );
        },
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final DateTime day;
  final DateTime now;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayChip({
    super.key,
    required this.day,
    required this.now,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations material = MaterialLocalizations.of(context);
    final String name = _name(context, material);
    final String number = material.formatDecimal(day.day);

    final Color foreground = isSelected
        ? context.colors.onPrimary
        : context.colors.textPrimary;

    return PressableScale(
      onTap: onTap,
      selected: isSelected,
      // Both lines at once, and the full date rather than "Wed 20" — a screen
      // reader user has no strip to scan for context.
      semanticLabel: material.formatFullDate(day),
      child: Container(
        constraints: BoxConstraints(minWidth: 58.w),
        padding: EdgeInsetsDirectional.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primary
              : context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? Colors.transparent : context.colors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: context.text.caption.copyWith(
                color: isSelected
                    ? context.colors.onPrimary.withValues(alpha: 0.85)
                    : context.colors.textSecondary,
              ),
            ),
            Text(
              number,
              style: context.text.mono.copyWith(
                fontSize: 15.sp,
                fontWeight: AppTypography.semiBold,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Today", "Tomorrow", or the weekday.
  ///
  /// Compared against the real dates rather than against the chip's position,
  /// because the first chip is **not** always today: once the last minute of
  /// the day is spent the strip drops it, and a label keyed on index would
  /// then call tomorrow "Today" — a reminder off by twenty-four hours from a
  /// word.
  String _name(BuildContext context, MaterialLocalizations material) {
    if (isSameDay(day, now)) return context.l10n.dateToday;
    if (isSameDay(day, DateTime(now.year, now.month, now.day + 1))) {
      return context.l10n.dateTomorrow;
    }
    // `formatMediumDate` is "Wed, Aug 20" in every locale Flutter knows, and
    // the first component of it is the weekday — but only in the locales that
    // put it first. Taking the platform's own weekday list avoids parsing a
    // formatted string, which is the sort of thing that works in English and
    // silently produces "20" somewhere else.
    return material.narrowWeekdays[day.weekday % 7];
  }
}

/// The way to a date the strip does not reach.
class _CalendarChip extends StatelessWidget {
  final VoidCallback onTap;

  const _CalendarChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      semanticLabel: context.l10n.reminderOtherDay,
      child: Container(
        width: 58.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: context.colors.border),
        ),
        child: Icon(
          Icons.calendar_month_rounded,
          size: 20.sp,
          color: context.colors.iconSecondary,
        ),
      ),
    );
  }
}

/// AM and PM, as two stacked pills rather than a third wheel.
///
/// **A two-item drum is the one place the wheel metaphor stops paying.** It
/// costs a drag to move between exactly two values, leaves three empty rows of
/// nothing above and below, and is the only column where every possible value
/// is already on screen. Two pills make it a tap, and they make an unavailable
/// morning legible as a disabled control rather than as a row you can scroll
/// to and not keep.
class _PeriodSelector extends StatelessWidget {
  final bool isPm;

  /// False once the earliest allowed moment is in the afternoon — choosing
  /// "AM" then means choosing a morning that has already happened.
  final bool amEnabled;

  final String am;
  final String pm;
  final ValueChanged<bool> onChanged;

  const _PeriodSelector({
    required this.isPm,
    required this.amEnabled,
    required this.am,
    required this.pm,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PeriodPill(
          label: am,
          isSelected: !isPm,
          enabled: amEnabled,
          onTap: () => onChanged(false),
        ),
        SizedBox(height: 8.h),
        _PeriodPill(
          label: pm,
          isSelected: isPm,
          enabled: true,
          onTap: () => onChanged(true),
        ),
      ],
    );
  }
}

class _PeriodPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _PeriodPill({
    required this.label,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color foreground = !enabled
        ? context.colors.textDisabled
        : isSelected
        ? context.colors.onPrimary
        : context.colors.textPrimary;

    return PressableScale(
      onTap: enabled ? onTap : null,
      selected: isSelected,
      child: AnimatedContainer(
        duration: AppMotion.duration(context, AppMotion.press),
        curve: AppMotion.standard,
        width: 54.w,
        height: 38.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primary
              : context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? Colors.transparent : context.colors.border,
          ),
        ),
        child: Text(
          label,
          style: context.text.titleSmall.copyWith(color: foreground),
        ),
      ),
    );
  }
}
