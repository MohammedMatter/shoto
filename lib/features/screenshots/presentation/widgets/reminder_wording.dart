import 'package:flutter/material.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/utils/reminder_schedule.dart';

/// The one sentence two screens say about the next reminder there is.
///
/// **Written down once because it was written down twice.** The Home inbox row
/// and the summary at the top of the reminders screen both answer "when should
/// I expect the next one", and they are the same question about the same
/// moment — but they were two private static methods in two files, which is
/// the arrangement where one of them gets a fix and the other does not. The
/// first version of that fix is already in this function's history: a bare
/// clock time was being printed for every reminder there is, so "Next 9:00 AM"
/// under "3 reminders" read as *this morning* whether the reminder was in two
/// hours or in three weeks.
///
/// So the date comes along whenever the reminder is not today, and only then.
/// One format rather than a band-by-band ladder like the rows use: this is a
/// summary line with a heading's worth of space, and "Aug 25, 9:00 AM" is
/// unambiguous everywhere without needing four cases to be right.
///
/// **Deliberately absolute, including inside the hour**, which is the one place
/// it could have been a countdown and should not be. The row for that reminder
/// is a few pixels below and already says "in 6 min"; a summary repeating the
/// row underneath it word for word is a summary of one thing. The two are
/// complementary as they stand — *how soon* on the row, *when* up here — and
/// "9:14 PM" is the half that survives being read in passing, which is what a
/// summary is for.
String nextReminderWhen(
  BuildContext context,
  DateTime at, {
  required DateTime now,
}) {
  final MaterialLocalizations l = MaterialLocalizations.of(context);
  final String clock = l.formatTimeOfDay(TimeOfDay.fromDateTime(at));
  if (reminderBandFor(at, now: now) == ReminderBand.today) return clock;
  return '${l.formatMediumDate(at)}, $clock';
}

/// [nextReminderWhen], wrapped in the words that introduce it.
///
/// Split from the formatting so a caller that already has its own frame for
/// the moment — a label, a heading, a row of its own — can take the moment
/// without the sentence.
String nextReminderLine(
  BuildContext context,
  DateTime at, {
  required DateTime now,
}) => context.l10n.remindersNextAt(nextReminderWhen(context, at, now: now));
