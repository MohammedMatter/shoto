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
/// fifth option is for. Every preset lands on a round hour rather than "in
/// three hours", because a reminder at 19:00 is a time somebody can plan
/// around and 18:47 is an interruption.
enum ReminderPreset {
  /// Three hours from now, rounded up to the hour.
  ///
  /// Not a fixed clock time, because "later today" said at nine in the
  /// morning and at nine at night mean different things and only one of them
  /// is today.
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

/// How far ahead [ReminderPreset.laterToday] reaches before rounding.
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
      final DateTime raw = now.add(_laterTodayGap);
      // Rounded *up*: rounding down could land before `now` for anything
      // under an hour away, and this is the one preset whose target is not a
      // named hour to begin with.
      final DateTime rounded = DateTime(
        raw.year,
        raw.month,
        raw.day,
        raw.hour,
      ).add(const Duration(hours: 1));
      return rounded;

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
/// **"This evening" at eleven at night is not an option, it is a mistake
/// waiting to be made.** Resolving it rolls to tomorrow, which is correct and
/// is not what the words on the button say — so the button comes off the sheet
/// instead of quietly meaning something else. The rest are always honest:
/// "later today" is measured from now, and the two morning presets name the
/// day they land on.
bool isPresetOffered(ReminderPreset preset, DateTime now) {
  if (preset != ReminderPreset.thisEvening) return true;
  // Offered until the evening itself arrives, and for one hour before it so
  // the last offer is not a reminder three minutes away.
  return now.hour < _eveningHour - 1;
}

/// The presets to draw, at [now], in order.
List<ReminderPreset> offeredPresets(DateTime now) => <ReminderPreset>[
  for (final ReminderPreset preset in ReminderPreset.values)
    if (isPresetOffered(preset, now)) preset,
];
