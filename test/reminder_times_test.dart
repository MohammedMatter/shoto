import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/reminder_times.dart';

/// Every rule here has an edge an hour wide, so each one is asked from both
/// sides of it. A reminder that resolves into the past either fires the
/// instant it is set or never fires at all — which of the two depends on which
/// layer notices first, and neither is what the user asked for.
void main() {
  group('later today', () {
    // The reported bug, pinned: asked at 16:22 this used to answer 20:00 —
    // three hours and thirty-eight minutes, because it rounded up to the next
    // whole hour. Thirty-eight minutes the user did not ask for, under a
    // button that only implies one number.
    test('is exactly three hours on, to the minute', () {
      expect(
        resolveReminder(
          ReminderPreset.laterToday,
          DateTime(2026, 5, 4, 16, 22),
        ),
        DateTime(2026, 5, 4, 19, 22),
      );
      expect(
        resolveReminder(
          ReminderPreset.laterToday,
          DateTime(2026, 5, 4, 10, 20),
        ),
        DateTime(2026, 5, 4, 13, 20),
      );
    });

    test('does not round even when it would be tidy to', () {
      expect(
        resolveReminder(
          ReminderPreset.laterToday,
          DateTime(2026, 5, 4, 10, 59),
        ),
        DateTime(2026, 5, 4, 13, 59),
      );
    });

    test('and never lands on a time another preset already offers', () {
      // Rounding *down* was the other way to make it tidy, and at 16:22 it
      // would have produced 19:00 — the moment "this evening" is offering two
      // rows below.
      final DateTime now = DateTime(2026, 5, 4, 16, 22);
      expect(
        resolveReminder(ReminderPreset.laterToday, now),
        isNot(resolveReminder(ReminderPreset.thisEvening, now)),
      );
    });

    test('is not offered once three hours is no longer today', () {
      // 22:30 + 3h is half past one the next morning: a correct offset under a
      // label that is plainly false.
      expect(
        isPresetOffered(
          ReminderPreset.laterToday,
          DateTime(2026, 5, 4, 22, 30),
        ),
        isFalse,
      );
      expect(
        isPresetOffered(ReminderPreset.laterToday, DateTime(2026, 5, 4, 21)),
        isFalse,
        reason: '21:00 + 3h is midnight, which is already tomorrow',
      );
      expect(
        isPresetOffered(
          ReminderPreset.laterToday,
          DateTime(2026, 5, 4, 20, 59),
        ),
        isTrue,
        reason: '23:59 is the last minute that is still today',
      );
    });
  });

  group('this evening', () {
    test('is seven, when seven is still ahead', () {
      expect(
        resolveReminder(ReminderPreset.thisEvening, DateTime(2026, 5, 4, 9)),
        DateTime(2026, 5, 4, 19),
      );
    });

    test('rolls to tomorrow once it has passed', () {
      expect(
        resolveReminder(
          ReminderPreset.thisEvening,
          DateTime(2026, 5, 4, 21, 30),
        ),
        DateTime(2026, 5, 5, 19),
      );
    });

    test('is not offered late in the day, when the words stop being true', () {
      // Resolving still works and rolls forward; the point is that the button
      // saying "this evening" comes off the sheet rather than quietly meaning
      // tomorrow.
      expect(
        isPresetOffered(ReminderPreset.thisEvening, DateTime(2026, 5, 4, 21)),
        isFalse,
      );
      expect(
        isPresetOffered(ReminderPreset.thisEvening, DateTime(2026, 5, 4, 18)),
        isFalse,
        reason: 'an hour before is too close to be worth naming',
      );
      expect(
        isPresetOffered(ReminderPreset.thisEvening, DateTime(2026, 5, 4, 17)),
        isTrue,
      );
    });

    test('the two that name their day are always offered', () {
      final DateTime lateAtNight = DateTime(2026, 5, 4, 23, 50);
      for (final ReminderPreset preset in <ReminderPreset>[
        ReminderPreset.tomorrowMorning,
        ReminderPreset.nextWeek,
      ]) {
        expect(isPresetOffered(preset, lateAtNight), isTrue, reason: '$preset');
      }
    });

    test('late at night, only those two are left', () {
      // Both relative presets have stopped being true by now, and neither is
      // shown saying something it does not mean.
      expect(offeredPresets(DateTime(2026, 5, 4, 23, 50)), <ReminderPreset>[
        ReminderPreset.tomorrowMorning,
        ReminderPreset.nextWeek,
      ]);
    });
  });

  group('tomorrow and next week', () {
    test('land on nine in the morning', () {
      expect(
        resolveReminder(
          ReminderPreset.tomorrowMorning,
          DateTime(2026, 5, 4, 15, 12),
        ),
        DateTime(2026, 5, 5, 9),
      );
      expect(
        resolveReminder(ReminderPreset.nextWeek, DateTime(2026, 5, 4, 15, 12)),
        DateTime(2026, 5, 11, 9),
      );
    });

    test('roll over a month end', () {
      expect(
        resolveReminder(
          ReminderPreset.tomorrowMorning,
          DateTime(2026, 5, 31, 23, 30),
        ),
        DateTime(2026, 6, 1, 9),
      );
    });

    test('and over a leap day', () {
      expect(
        resolveReminder(
          ReminderPreset.tomorrowMorning,
          DateTime(2028, 2, 28, 12),
        ),
        DateTime(2028, 2, 29, 9),
      );
    });
  });

  test('every preset, asked at any hour, resolves into the future', () {
    // The one property that matters more than any individual answer.
    for (int hour = 0; hour < 24; hour++) {
      for (int minute in <int>[0, 1, 30, 59]) {
        final DateTime now = DateTime(2026, 5, 4, hour, minute);
        for (final ReminderPreset preset in ReminderPreset.values) {
          expect(
            resolveReminder(preset, now).isAfter(now),
            isTrue,
            reason: '$preset at $hour:$minute resolved into the past',
          );
        }
      }
    }
  });

  group('what the custom picker opens on', () {
    // The reported bug: "it won't make a reminder for today, five minutes from
    // now." The dial opened on a flat 09:00, so choosing today and moving only
    // the minutes composed 09:05 — already gone — and the save was then
    // refused in silence.
    test('today opens five minutes from now, not nine in the morning', () {
      final DateTime now = DateTime(2026, 5, 4, 16, 51);
      expect(
        pickerOpensAt(DateTime(2026, 5, 4), now),
        DateTime(2026, 5, 4, 16, 56),
      );
    });

    test('and what it opens on is always still ahead', () {
      for (int hour = 0; hour < 24; hour++) {
        final DateTime now = DateTime(2026, 5, 4, hour, 30);
        expect(
          pickerOpensAt(DateTime(2026, 5, 4), now).isAfter(now),
          isTrue,
          reason: 'at $hour:30',
        );
      }
    });

    test('a later date opens on nine, where nine is a sensible guess', () {
      expect(
        pickerOpensAt(DateTime(2026, 5, 9), DateTime(2026, 5, 4, 16, 51)),
        DateTime(2026, 5, 9, 9),
      );
    });

    test('late at night, today rolls the opening time into tomorrow', () {
      // 23:58 + 5 minutes is 00:03. The picker takes only the *time* off this,
      // so it opens on 00:03 — and the composed moment is then in the past for
      // today, which is exactly the case the message now explains rather than
      // swallowing.
      expect(
        pickerOpensAt(DateTime(2026, 5, 4), DateTime(2026, 5, 4, 23, 58)),
        DateTime(2026, 5, 5, 0, 3),
      );
    });
  });

  test('offered presets keep their declared order', () {
    // The sheet draws them in this order and the order is a judgement about
    // which answer is most likely, so a filter must not reshuffle it.
    expect(offeredPresets(DateTime(2026, 5, 4, 9)), ReminderPreset.values);
    expect(
      offeredPresets(DateTime(2026, 5, 4, 19, 30)),
      <ReminderPreset>[
        ReminderPreset.laterToday,
        ReminderPreset.tomorrowMorning,
        ReminderPreset.nextWeek,
      ],
      reason: 'the evening has gone; three hours on is still today',
    );
  });

  // The rules the drum picker is built on. All three of its parts — the dimmed
  // rows, the snap-back when a finger lets go past them, and the day strip
  // dropping a day it cannot land inside — read `earliestChoiceOn` and nothing
  // else, so these are the tests that decide whether an impossible reminder
  // can be composed at all.
  group('the floor under the wheels', () {
    test('today cannot be set inside the minute it already is', () {
      // 10:30:45 is most of the way through 10:30. Answering 10:30 would hand
      // back a reminder the user watches fire before the sheet has closed.
      expect(
        earliestChoiceOn(DateTime(2026, 5, 4), DateTime(2026, 5, 4, 10, 30, 45)),
        DateTime(2026, 5, 4, 10, 31),
      );
    });

    test('and the seconds are dropped, not carried', () {
      final DateTime floor = earliestChoiceOn(
        DateTime(2026, 5, 4),
        DateTime(2026, 5, 4, 10, 30, 45),
      );
      expect(floor.second, 0);
      expect(floor.millisecond, 0);
    });

    // This is what makes every call site branch-free: an hour is allowed when
    // it is at or after the floor's hour, and on a future day that reads
    // `hour >= 0`. No `if (isToday)` anywhere in the widget.
    test('any other day starts at midnight, so nothing is disabled', () {
      expect(
        earliestChoiceOn(DateTime(2026, 5, 9), DateTime(2026, 5, 4, 16, 51)),
        DateTime(2026, 5, 9),
      );
    });

    test('the last minute of the day is still choosable', () {
      expect(
        dayHasChoices(DateTime(2026, 5, 4), DateTime(2026, 5, 4, 23, 58)),
        isTrue,
      );
    });

    test('but once it is spent, today has nothing left to offer', () {
      // 23:59 + a minute is tomorrow, so the floor no longer lands on today —
      // and a chip for a day with no choosable minute is a chip that answers
      // nothing.
      expect(
        dayHasChoices(DateTime(2026, 5, 4), DateTime(2026, 5, 4, 23, 59, 10)),
        isFalse,
      );
    });

    test('yesterday is never offered, whatever the clock says', () {
      expect(
        dayHasChoices(DateTime(2026, 5, 3), DateTime(2026, 5, 4, 9)),
        isFalse,
      );
    });
  });

  group('the days on the strip', () {
    test('start with today and run a fortnight', () {
      final List<DateTime> days = reminderDays(DateTime(2026, 5, 4, 9));
      expect(days.length, 14);
      expect(days.first, DateTime(2026, 5, 4));
      expect(days.last, DateTime(2026, 5, 17));
    });

    test('are dates, so they cross a month end without arithmetic', () {
      final List<DateTime> days = reminderDays(DateTime(2026, 5, 28, 9));
      expect(days[3], DateTime(2026, 5, 31));
      expect(days[4], DateTime(2026, 6));
    });

    test('are all midnight, so a chip cannot carry a time with it', () {
      for (final DateTime day in reminderDays(DateTime(2026, 5, 4, 16, 22))) {
        expect(day.hour, 0);
        expect(day.minute, 0);
      }
    });

    // The strip is a list of days somebody can choose, so a day nobody can
    // choose is not on it — and the first chip is therefore not always today,
    // which is why the label is decided by the date and never by the index.
    test('drop today once the last minute of it is gone', () {
      final List<DateTime> days = reminderDays(DateTime(2026, 5, 4, 23, 59, 30));
      expect(days.first, DateTime(2026, 5, 5));
      expect(days.length, 13, reason: 'the span is a fortnight of dates');
    });
  });

  group('where the wheels open', () {
    test('on today, five minutes ahead — the request this exists to serve', () {
      expect(
        openingChoice(DateTime(2026, 5, 4), DateTime(2026, 5, 4, 16, 51)),
        DateTime(2026, 5, 4, 16, 56),
      );
    });

    test('on any other day, nine in the morning', () {
      expect(
        openingChoice(DateTime(2026, 5, 9), DateTime(2026, 5, 4, 16, 51)),
        DateTime(2026, 5, 9, 9),
      );
    });

    // `pickerOpensAt` answers 00:03 *tomorrow* here, which was correct for a
    // dialog that took only the time off it and then refused the result. A
    // wheel cannot open on a moment it would immediately slide away from.
    test('never past the day the wheels belong to', () {
      expect(
        openingChoice(DateTime(2026, 5, 4), DateTime(2026, 5, 4, 23, 58)),
        DateTime(2026, 5, 4, 23, 59),
      );
    });

    test('and never before the earliest allowed minute, at any hour', () {
      for (int hour = 0; hour < 24; hour++) {
        for (final int minute in <int>[0, 29, 55, 59]) {
          final DateTime now = DateTime(2026, 5, 4, hour, minute);
          final DateTime day = DateTime(2026, 5, 4);
          if (!dayHasChoices(day, now)) continue;

          final DateTime opening = openingChoice(day, now);
          expect(
            opening.isBefore(earliestChoiceOn(day, now)),
            isFalse,
            reason: 'opened on $opening at $hour:$minute',
          );
          expect(
            isSameDay(opening, day),
            isTrue,
            reason: 'opened on another day at $hour:$minute',
          );
        }
      }
    });
  });
}
