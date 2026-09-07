/// Which band of the reminders list a due moment belongs in.
///
/// The mirror image of `date_sections.dart`, and deliberately not a reuse of
/// it. That file addresses the **past** — today, yesterday, last week — because
/// it groups screenshots by when they were taken. A reminder is a fact about
/// the **future**, and the two vocabularies do not overlap: there is no
/// "yesterday" band here, and the one band that matters most on this screen —
/// a moment that has already gone — has no counterpart there at all.
///
/// Pure Dart, no Flutter, for the same reason [reminderDays] is: every
/// boundary below is a line an instant wide, and the only honest way to know a
/// line is in the right place is to ask from both sides of it against a clock
/// that does not move.
library;

/// A reminder's place in the list, in the order the bands are drawn.
enum ReminderBand {
  /// Due at or before now, and still sitting there.
  ///
  /// **First, and the reason this screen exists.** A notification clears itself
  /// when it fires; without a band that keeps missed reminders visible, the one
  /// moment the app asked for attention was also the only one it would ever
  /// get.
  missed,

  /// Still to come, today.
  today,

  tomorrow,

  /// Within the next week, but not today or tomorrow.
  thisWeek,

  /// Everything further out.
  later,
}

/// How far ahead [ReminderBand.thisWeek] reaches, in calendar days from today.
///
/// Seven, counted in *dates* rather than in hours — see [_daysBetween]. A
/// reminder set for Friday morning is "this week" whether it is asked about on
/// Thursday night or Friday at one minute past midnight, because that is what
/// the words mean to the person reading them.
const int _thisWeekSpan = 7;

/// Which band [at] falls in, relative to [now].
///
/// **The missed test is the only one measured in instants**, and that is the
/// one asymmetry in this file worth stating. Every other boundary is a
/// calendar-day comparison, because "tomorrow" is a date. But a reminder due at
/// 14:00 is missed at 14:01 and not before — rounding that to a day would leave
/// this morning's missed reminder sitting under "Today" as though it were still
/// coming, which is the single thing this screen must never say.
ReminderBand reminderBandFor(DateTime at, {required DateTime now}) {
  if (!at.isAfter(now)) return ReminderBand.missed;

  final int days = _daysBetween(now, at);
  if (days <= 0) return ReminderBand.today;
  if (days == 1) return ReminderBand.tomorrow;
  if (days < _thisWeekSpan) return ReminderBand.thisWeek;
  return ReminderBand.later;
}

/// One heading and the reminders sitting under it.
class ReminderRun<T> {
  final ReminderBand band;
  final List<T> items;

  const ReminderRun({required this.band, required this.items});
}

/// Splits an already-ordered list of reminders into banded runs.
///
/// **Order is the caller's business**, exactly as in [groupByDate]: this walks
/// the list once and opens a new run whenever the band changes. The bloc hands
/// reminders over soonest-first, which puts the missed ones — the earliest
/// moments there are — at the front on their own, with no sort needed here.
///
/// A band therefore appears at most once as long as the input is ordered, and
/// an unordered input produces repeated headings rather than a silent
/// re-sort. That is the honest failure: it is visible, and it points at the
/// caller that caused it.
List<ReminderRun<T>> groupBySchedule<T>(
  List<T> items, {
  required DateTime Function(T item) dueAt,
  required DateTime now,
}) {
  final List<ReminderRun<T>> runs = <ReminderRun<T>>[];

  for (final T item in items) {
    final ReminderBand band = reminderBandFor(dueAt(item), now: now);
    if (runs.isNotEmpty && runs.last.band == band) {
      runs.last.items.add(item);
      continue;
    }
    runs.add(ReminderRun<T>(band: band, items: <T>[item]));
  }

  return runs;
}

/// Whole calendar days from [from] to [to]; negative when [to] is earlier.
///
/// Both ends are flattened to midnight before subtracting, which is what makes
/// this a question about dates rather than about elapsed time. `difference` on
/// the raw moments would answer 0 for "23:50 tonight to 00:10 tomorrow" — twenty
/// minutes apart, and a different day by the only measure a heading cares about.
///
/// `inDays` on the flattened pair is safe across a daylight-saving change in a
/// way it is not on the raw one: the two midnights are 23 or 25 hours apart on
/// the shift day, and `inDays` truncates 23 hours to 0. So the subtraction is
/// nudged by half a day before truncating, which lands on the right integer
/// either way.
int _daysBetween(DateTime from, DateTime to) {
  final DateTime a = DateTime(from.year, from.month, from.day);
  final DateTime b = DateTime(to.year, to.month, to.day);
  return (b.difference(a).inHours / 24).round();
}
