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

/// How far past [now] the custom time picker opens when it has to guess.
const Duration _pickerHeadStart = Duration(minutes: 5);

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

  return now.add(_pickerHeadStart);
}
