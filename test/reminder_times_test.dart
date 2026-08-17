import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/reminder_times.dart';

/// Every rule here has an edge an hour wide, so each one is asked from both
/// sides of it. A reminder that resolves into the past either fires the
/// instant it is set or never fires at all — which of the two depends on which
/// layer notices first, and neither is what the user asked for.
void main() {
  group('later today', () {
    test('is three hours on, rounded up to the hour', () {
      expect(
        resolveReminder(
          ReminderPreset.laterToday,
          DateTime(2026, 5, 4, 10, 20),
        ),
        DateTime(2026, 5, 4, 14),
      );
    });

    test('rounds up even from the top of an hour, so it never lands on now', () {
      expect(
        resolveReminder(ReminderPreset.laterToday, DateTime(2026, 5, 4, 10)),
        DateTime(2026, 5, 4, 14),
      );
    });

    test('crosses midnight rather than clamping to today', () {
      expect(
        resolveReminder(
          ReminderPreset.laterToday,
          DateTime(2026, 5, 4, 22, 30),
        ),
        DateTime(2026, 5, 5, 2),
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

    test('the others are always honest, so they are always offered', () {
      final DateTime lateAtNight = DateTime(2026, 5, 4, 23, 50);
      for (final ReminderPreset preset in <ReminderPreset>[
        ReminderPreset.laterToday,
        ReminderPreset.tomorrowMorning,
        ReminderPreset.nextWeek,
      ]) {
        expect(isPresetOffered(preset, lateAtNight), isTrue, reason: '$preset');
      }
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
    expect(
      offeredPresets(DateTime(2026, 5, 4, 9)),
      ReminderPreset.values,
    );
    expect(
      offeredPresets(DateTime(2026, 5, 4, 22)),
      <ReminderPreset>[
        ReminderPreset.laterToday,
        ReminderPreset.tomorrowMorning,
        ReminderPreset.nextWeek,
      ],
    );
  });
}
