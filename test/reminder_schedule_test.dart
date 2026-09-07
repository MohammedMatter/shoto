import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/reminder_schedule.dart';

/// The boundaries between the bands on the reminders screen.
///
/// Every one of them is a line an instant or a midnight wide, and the whole
/// value of keeping this logic free of Flutter is being able to stand on both
/// sides of each line against a clock that does not move. Asked at whatever
/// time the suite happens to run, half of these would be vacuously true.
void main() {
  // A Tuesday, mid-afternoon, with plenty of the day left.
  final DateTime now = DateTime(2026, 8, 18, 14, 30);

  ReminderBand bandOf(DateTime at) => reminderBandFor(at, now: now);

  group('the missed line', () {
    test('a moment one minute gone is missed', () {
      expect(bandOf(DateTime(2026, 8, 18, 14, 29)), ReminderBand.missed);
    });

    test('a moment one minute ahead is not', () {
      expect(bandOf(DateTime(2026, 8, 18, 14, 31)), ReminderBand.today);
    });

    // The exact instant belongs to the past. A reminder due *now* has fired,
    // and calling it "coming up" is the one thing this screen must not say.
    test('the exact moment counts as missed', () {
      expect(bandOf(now), ReminderBand.missed);
    });

    test('yesterday is missed, not filed under a day of its own', () {
      expect(bandOf(DateTime(2026, 8, 17, 9)), ReminderBand.missed);
    });

    test('last month is still just missed', () {
      expect(bandOf(DateTime(2026, 7, 2, 9)), ReminderBand.missed);
    });
  });

  group('today and tomorrow', () {
    test('later this afternoon is today', () {
      expect(bandOf(DateTime(2026, 8, 18, 19)), ReminderBand.today);
    });

    test('the last minute of tonight is still today', () {
      expect(bandOf(DateTime(2026, 8, 18, 23, 59)), ReminderBand.today);
    });

    // Ten minutes later on the clock, and a different heading — which is the
    // point of grouping by date rather than by elapsed hours.
    test('the first minute of tomorrow is tomorrow', () {
      expect(bandOf(DateTime(2026, 8, 19, 0, 1)), ReminderBand.tomorrow);
    });

    test('tomorrow night is still tomorrow', () {
      expect(bandOf(DateTime(2026, 8, 19, 23, 59)), ReminderBand.tomorrow);
    });
  });

  group('this week and beyond', () {
    test('the day after tomorrow is this week', () {
      expect(bandOf(DateTime(2026, 8, 20, 9)), ReminderBand.thisWeek);
    });

    test('six days out is the last day of this week', () {
      expect(bandOf(DateTime(2026, 8, 24, 9)), ReminderBand.thisWeek);
    });

    test('seven days out has fallen into later', () {
      expect(bandOf(DateTime(2026, 8, 25, 9)), ReminderBand.later);
    });

    test('next month is later', () {
      expect(bandOf(DateTime(2026, 9, 25, 9)), ReminderBand.later);
    });
  });

  group('grouping', () {
    List<DateTime> at(List<DateTime> moments) => moments;

    test('walks an ordered list into one run per band', () {
      final List<ReminderRun<DateTime>> runs = groupBySchedule<DateTime>(
        at(<DateTime>[
          DateTime(2026, 8, 16, 9), // missed
          DateTime(2026, 8, 18, 10), // missed
          DateTime(2026, 8, 18, 20), // today
          DateTime(2026, 8, 19, 9), // tomorrow
          DateTime(2026, 8, 21, 9), // this week
          DateTime(2026, 9, 1, 9), // later
        ]),
        dueAt: (DateTime d) => d,
        now: now,
      );

      expect(runs.map((ReminderRun<DateTime> r) => r.band), <ReminderBand>[
        ReminderBand.missed,
        ReminderBand.today,
        ReminderBand.tomorrow,
        ReminderBand.thisWeek,
        ReminderBand.later,
      ]);
      expect(runs.first.items, hasLength(2));
    });

    test('an empty list produces no headings', () {
      expect(
        groupBySchedule<DateTime>(
          const <DateTime>[],
          dueAt: (DateTime d) => d,
          now: now,
        ),
        isEmpty,
      );
    });

    test('a band with nothing in it is never drawn', () {
      // Nothing missed and nothing today: the list must open on "tomorrow"
      // rather than on two empty headings.
      final List<ReminderRun<DateTime>> runs = groupBySchedule<DateTime>(
        at(<DateTime>[DateTime(2026, 8, 19, 9), DateTime(2026, 9, 1, 9)]),
        dueAt: (DateTime d) => d,
        now: now,
      );

      expect(runs.map((ReminderRun<DateTime> r) => r.band), <ReminderBand>[
        ReminderBand.tomorrow,
        ReminderBand.later,
      ]);
    });
  });

  group('daylight saving', () {
    // Europe springs forward on the last Sunday of March. The two midnights
    // either side of it are 23 hours apart, and truncating that to whole days
    // answers 0 — which would file tomorrow under today.
    test('a 23-hour day still counts as one day', () {
      final DateTime beforeShift = DateTime(2026, 3, 28, 20);
      expect(
        reminderBandFor(DateTime(2026, 3, 29, 10), now: beforeShift),
        ReminderBand.tomorrow,
      );
    });

    test('a 25-hour day still counts as one day', () {
      final DateTime beforeShift = DateTime(2026, 10, 24, 20);
      expect(
        reminderBandFor(DateTime(2026, 10, 25, 10), now: beforeShift),
        ReminderBand.tomorrow,
      );
    });
  });
}
