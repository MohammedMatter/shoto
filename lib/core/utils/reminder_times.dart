/// When "later" actually is.
///
/// Pure Dart, no Flutter, so every one of these answers can be checked against
/// a fixed clock instead of against whenever the test happened to run — the
/// same split [PerceptualHash] and [ScrollStitcher] use. It matters more here
/// than it looks: every rule below has an edge an hour wide, and the only way
/// to know they are right is to ask them from both sides of it.
library;

/// The offers a person is given, in the order they are shown.
///
/// **Four, and all of them relative.** A reminder set from a screenshot is set
/// in the second after deciding to deal with it later, usually one-handed —
/// so the common answers have to be one tap, and a date picker is what the
/// fifth option is for.
///
/// **A named hour is round; a measured gap is exact.** "This evening" is seven
/// o'clock because seven o'clock is what the words mean. "Later today" is three
/// hours, and three hours from 16:22 is 19:22 — rounding that to a tidier
/// number is the app deciding the user meant something they did not say. Every
/// resolved time is printed beside its own row, so neither kind is a guess the
/// reader has to make.
enum ReminderPreset {
  /// Three hours from now, to the minute.
  ///
  /// Not a fixed clock time, because "later today" said at nine in the
  /// morning and at nine at night mean different things and only one of them
  /// is today.
  ///
  /// **It used to round up to the next whole hour, and that was wrong.** The
  /// argument was that 20:00 is a time somebody can plan around where 19:22 is
  /// an interruption — true of a time the user *names*, and not true of one
  /// the app derives. Asked at 16:22 it produced 20:00: three hours and
  /// thirty-eight minutes, a 21% overshoot on the only number the button
  /// implies, and the user is the one who noticed. Rounding a relative offset
  /// silently spends the user's time on the app's taste in clock faces.
  ///
  /// The tidy hours below stay, because there the round number *is* the
  /// meaning — "this evening" is seven, not "seven-ish derived from now".
  laterToday,

  /// 19:00, the same evening — or tomorrow's, if it has already passed.
  thisEvening,

  /// 09:00 tomorrow.
  tomorrowMorning,

  /// 09:00, seven days on.
  nextWeek,
}

/// The hour "this evening" means.
const int _eveningHour = 19;

/// The hour every morning-ish preset lands on.
const int _morningHour = 9;

/// How far ahead [ReminderPreset.laterToday] reaches. Exactly this, now.
const Duration _laterTodayGap = Duration(hours: 3);

/// The moment [preset] refers to, measured from [now].
///
/// Always strictly after [now]. Two of these can resolve into the past when
/// asked at the wrong time of day — "this evening" at eight at night, "later
/// today" is fine but "tomorrow morning" from a phone whose clock is being
/// adjusted is not — and a reminder in the past is one that either fires
/// immediately or never, depending on which layer notices first. Each rule
/// below rolls forward by a whole day rather than clamping to "now plus a
/// minute", because somebody who asked for the evening meant an evening.
DateTime resolveReminder(ReminderPreset preset, DateTime now) {
  switch (preset) {
    case ReminderPreset.laterToday:
      // Exactly three hours. Not rounded in either direction: rounding up
      // charges the user up to fifty-nine minutes they did not ask for, and
      // rounding down would land this on 19:00 at 16:22 — the same moment
      // [ReminderPreset.thisEvening] already offers, two rows apart.
      return now.add(_laterTodayGap);

    case ReminderPreset.thisEvening:
      final DateTime evening = DateTime(
        now.year,
        now.month,
        now.day,
        _eveningHour,
      );
      return evening.isAfter(now)
          ? evening
          : evening.add(const Duration(days: 1));

    case ReminderPreset.tomorrowMorning:
      final DateTime tomorrow = now.add(const Duration(days: 1));
      return DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        _morningHour,
      );

    case ReminderPreset.nextWeek:
      final DateTime week = now.add(const Duration(days: 7));
      return DateTime(week.year, week.month, week.day, _morningHour);
  }
}

/// Whether [preset] is worth offering at [now].
///
/// **A button whose words have stopped being true comes off the sheet, rather
/// than quietly meaning something else.** Both of the relative presets can
/// stop being true late in the day, and each resolves *correctly* when they do
/// — which is exactly the problem: the answer is right and the label is not.
///
/// The two morning presets name the day they land on and are always honest.
bool isPresetOffered(ReminderPreset preset, DateTime now) {
  switch (preset) {
    // "This evening" at eleven at night resolves to tomorrow evening. Offered
    // until an hour before seven, so the last one shown is not a reminder
    // three minutes away.
    case ReminderPreset.thisEvening:
      return now.hour < _eveningHour - 1;

    // **"Later today" has to still be today.** Three hours on from 22:30 is
    // half past one the next morning — a correct offset under a label that is
    // plainly false, and the sort of thing somebody discovers by being woken
    // up. Checked against the resolved date rather than an hour threshold, so
    // it stays right if the gap ever changes.
    case ReminderPreset.laterToday:
      final DateTime at = now.add(_laterTodayGap);
      return at.year == now.year && at.month == now.month && at.day == now.day;

    case ReminderPreset.tomorrowMorning:
    case ReminderPreset.nextWeek:
      return true;
  }
}

/// The presets to draw, at [now], in order.
List<ReminderPreset> offeredPresets(DateTime now) => <ReminderPreset>[
  for (final ReminderPreset preset in ReminderPreset.values)
    if (isPresetOffered(preset, now)) preset,
];

/// The least notice the picker's own default is ever allowed to give.
///
/// The opening time is rounded up from here to the next [_openingStep], so the
/// default lands somewhere between five and ten minutes out — never nearer than
/// this, and always on a round minute.
const Duration _pickerHeadStart = Duration(minutes: 5);

/// The minute the picker's default is allowed to land on.
///
/// **A default should look like a decision, and 11:31 does not.** Opening on
/// exactly `now + 5` produced whatever minute the clock happened to be showing
/// — 11:23, 11:26, 11:31 — which reads as a timestamp rather than as a
/// suggestion, and starts the minute wheel on a number nobody would have
/// chosen. Rounding up to the next five gives a figure that looks picked.
///
/// **Nothing is lost by it**, and that is what makes the rounding safe rather
/// than merely tidier: the floor is still [earliestChoiceOn], one minute from
/// now, so every minute between there and the opening figure is still there to
/// be scrolled back to. The default moves; the range does not.
///
/// Five rather than fifteen, because the whole reason this picker exists is
/// that somebody wants a time the presets do not offer — often a near one. A
/// quarter-hour step would push "in a few minutes" out to as much as fifteen,
/// which is the very failure [pickerOpensAt] was rewritten to fix.
const int _openingStep = 5;

/// How many days the picker offers before somebody has to open a calendar.
///
/// Two weeks, and the number is a claim about what reminders on screenshots
/// are *for*: come back to this receipt, this address, this code. Anything
/// further out is a diary entry, and the calendar behind the last chip is the
/// honest place for it. Offering ninety days would not make those reminders
/// easier to set, it would make the fourteen common ones a longer scroll.
const int _offeredDays = 14;

/// The days the picker offers, in order, each normalised to midnight.
///
/// **Today is dropped once there is nothing left of it.** At 23:59 the only
/// minute today still owns is already gone by the time a thumb reaches the
/// wheel, so the chip would be a day that cannot be chosen — see
/// [earliestChoiceOn], which is the single rule both this and the wheels read.
List<DateTime> reminderDays(DateTime now, {int span = _offeredDays}) {
  final DateTime today = DateTime(now.year, now.month, now.day);
  return <DateTime>[
    for (int i = 0; i < span; i++)
      if (dayHasChoices(_addDays(today, i), now)) _addDays(today, i),
  ];
}

/// The earliest moment still choosable on [day].
///
/// **This one function is the whole constraint system.** The wheels dim what
/// is before it, snap back to it when a finger lets go past it, and the day
/// strip drops a day it cannot land inside. Writing it once means the three
/// cannot disagree — and because it answers *midnight* for every day that is
/// not today, all three call sites are branch-free: an hour is allowed when it
/// is at or after this hour, and for a future day that test is `h >= 0`.
///
/// A minute is the granularity because a minute is what the wheels offer.
/// Asked at 10:30:45 this answers 10:31 rather than 10:30 — the current minute
/// is already partly spent, and a reminder set inside it is one the user
/// watches fire before they have put the phone down.
DateTime earliestChoiceOn(DateTime day, DateTime now) {
  if (!isSameDay(day, now)) return DateTime(day.year, day.month, day.day);

  final DateTime next = now.add(const Duration(minutes: 1));
  return DateTime(next.year, next.month, next.day, next.hour, next.minute);
}

/// Whether [day] still has a minute somebody could pick.
///
/// True for every future day, and true for today until the last minute of it
/// is spent — at which point [earliestChoiceOn] has rolled into tomorrow and
/// no longer lands on [day].
bool dayHasChoices(DateTime day, DateTime now) =>
    !day.isBefore(DateTime(now.year, now.month, now.day)) &&
    isSameDay(earliestChoiceOn(day, now), day);

/// Where the wheels open on [day], as a moment on that day.
///
/// [pickerOpensAt] holds the reasoning — nine in the morning for a day nobody
/// has an opinion about, five minutes ahead for today. This adds the two
/// clamps that a wheel needs and a dialog did not:
///
/// * **Never before the floor**, so the picker cannot open on a time it would
///   immediately snap away from.
/// * **Never past the day it belongs to.** At 23:58 the head start lands at
///   00:03 *tomorrow*, and a picker that opened on today with 00:03 on its
///   wheels would be showing a moment sixteen hours gone.
DateTime openingChoice(DateTime day, DateTime now) {
  final DateTime floor = earliestChoiceOn(day, now);
  final DateTime lastMinute = DateTime(day.year, day.month, day.day, 23, 59);
  final DateTime opening = pickerOpensAt(day, now);

  if (opening.isBefore(floor)) return floor;
  if (opening.isAfter(lastMinute)) return lastMinute;
  return opening;
}

/// A day and a time on it, as one moment.
///
/// Trivial, and named anyway: three call sites compose this and a
/// `DateTime(...)` with five positional arguments is the kind of line that
/// gets a field transposed without anybody noticing.
DateTime composeReminder(DateTime day, int hour, int minute) =>
    DateTime(day.year, day.month, day.day, hour, minute);

/// Whether two moments fall on the same calendar day.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// [days] on from [start], via the calendar rather than via arithmetic.
///
/// `add(Duration(days: n))` adds exact 24-hour blocks, which is a different
/// question: across a daylight-saving change it answers 23 or 25 hours later
/// and lands on the wrong date or on 23:00 the previous evening. The day strip
/// is a list of *dates*, so it counts in dates.
DateTime _addDays(DateTime start, int days) =>
    DateTime(start.year, start.month, start.day + days);

/// The moment the clock face should open on, once [day] has been chosen.
///
/// **This was a flat nine in the morning, and that is what made "today, in
/// five minutes" impossible.** Choosing today put the dial on 09:00 — a time
/// already gone for most of the day — so somebody reaching for a few minutes
/// ahead moved the *minute* hand, which is the half the task is about, and
/// composed 09:05 out of an hour nobody chose. The reminder was then refused
/// for being in the past, and refused in silence, so the whole feature looked
/// broken for the most ordinary request anybody would make of it.
///
/// So the default belongs to the day. Any later date opens on nine, which is
/// the sensible guess for a morning nobody has expressed an opinion about.
/// **Today opens five minutes from now**: that is the request this exists to
/// serve, and a dial that opened exactly on the current minute would invite a
/// reminder already late by the time it was confirmed.
///
/// Returned as a [DateTime] rather than a `TimeOfDay` so this file stays free
/// of Flutter and testable against a fixed clock; the caller takes the time
/// off it.
DateTime pickerOpensAt(DateTime day, DateTime now) {
  final bool isToday =
      day.year == now.year && day.month == now.month && day.day == now.day;
  if (!isToday) {
    return DateTime(day.year, day.month, day.day, _morningHour);
  }

  return _roundUpToStep(now.add(_pickerHeadStart));
}

/// [at] moved forward to the next whole [_openingStep] minutes, seconds
/// dropped.
///
/// Already-on-the-step moments are left alone rather than pushed a further five
/// minutes out. Seconds go because the wheels have no notion of them — carrying
/// them made this function's answer un-comparable with the floor it is checked
/// against, which is truncated to the minute.
///
/// Overflow past the hour, the day or the year is left to [DateTime], which
/// normalises it: minute 62 becomes the next hour, 23:58 becomes 00:03
/// tomorrow. [openingChoice] is what refuses a result that has left the day.
DateTime _roundUpToStep(DateTime at) {
  final int over = at.minute % _openingStep;
  final int minute = over == 0 ? at.minute : at.minute + (_openingStep - over);
  return DateTime(at.year, at.month, at.day, at.hour, minute);
}
