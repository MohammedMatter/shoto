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
}
