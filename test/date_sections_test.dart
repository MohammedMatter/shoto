import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/date_sections.dart';

/// Fixed "now" for every test here: the boundaries are the whole point, and a
/// test that asked the real clock would pass or fail depending on what time it
/// was run — the exact bug this file exists to prevent.
final DateTime _now = DateTime(2026, 8, 4, 15, 30);

DateSectionKind _kindOf(DateTime date) => sectionFor(date, now: _now).kind;

void main() {
  group('which heading a date falls under', () {
    test('today, whatever the hour', () {
      expect(_kindOf(DateTime(2026, 8, 4, 15, 29)), DateSectionKind.today);
      // Same calendar day, hours earlier — not "yesterday" just because more
      // than 24 hours of wall clock have not passed.
      expect(_kindOf(DateTime(2026, 8, 4, 0, 1)), DateSectionKind.today);
    });

    test('a capture ten minutes before midnight is yesterday at 15:30', () {
      // The reason buckets compare calendar days rather than elapsed time.
      expect(_kindOf(DateTime(2026, 8, 3, 23, 50)), DateSectionKind.yesterday);
    });

    test('the week, month and older bands', () {
      expect(_kindOf(DateTime(2026, 8, 2)), DateSectionKind.thisWeek);
      // 29 July is six days before 4 August, so it is still the week — the
      // seventh day back is where the month band starts.
      expect(_kindOf(DateTime(2026, 7, 29)), DateSectionKind.thisWeek);
      expect(_kindOf(DateTime(2026, 7, 28)), DateSectionKind.thisMonth);
      expect(_kindOf(DateTime(2026, 7, 7)), DateSectionKind.thisMonth);
      expect(_kindOf(DateTime(2026, 7, 5)), DateSectionKind.month);
    });

    test('the exact boundaries', () {
      // 6 days ago is still the week; 7 is not. 29 is still the month; 30 is
      // not. Off-by-one here is invisible in use and wrong every day.
      expect(_kindOf(_now.subtract(const Duration(days: 6))),
          DateSectionKind.thisWeek);
      expect(_kindOf(_now.subtract(const Duration(days: 7))),
          DateSectionKind.thisMonth);
      expect(_kindOf(_now.subtract(const Duration(days: 29))),
          DateSectionKind.thisMonth);
      expect(_kindOf(_now.subtract(const Duration(days: 30))),
          DateSectionKind.month);
    });

    test('a date in the future is filed under today, not its own section', () {
      // Happens on restored files and phones whose clock was wrong. A
      // "tomorrow" heading would be a bug made visible to the user.
      expect(_kindOf(DateTime(2026, 12, 25)), DateSectionKind.today);
    });

    test('old months are addressed by their own month', () {
      final DateSection march = sectionFor(DateTime(2026, 3, 14), now: _now);
      expect(march.kind, DateSectionKind.month);
      expect(march.month, DateTime(2026, 3));
    });

    test('the same month in different years is not the same section', () {
      final DateSection a = sectionFor(DateTime(2026, 3, 1), now: _now);
      final DateSection b = sectionFor(DateTime(2025, 3, 1), now: _now);
      expect(a == b, isFalse);
      expect(a.id, isNot(b.id));
    });
  });

  group('grouping a list', () {
    List<DatedGroup<DateTime>> group(List<DateTime> dates) =>
        groupByDate<DateTime>(dates, dateOf: (d) => d, now: _now);

    test('runs of the same bucket collapse into one heading', () {
      final groups = group(<DateTime>[
        DateTime(2026, 8, 4, 9),
        DateTime(2026, 8, 4, 8),
        DateTime(2026, 8, 3, 9),
        DateTime(2026, 3, 2),
        DateTime(2026, 3, 1),
      ]);

      expect(groups.map((g) => g.section.kind), <DateSectionKind>[
        DateSectionKind.today,
        DateSectionKind.yesterday,
        DateSectionKind.month,
      ]);
      expect(groups.map((g) => g.items.length), <int>[2, 1, 2]);
    });

    test('the caller\'s order is preserved, never re-sorted', () {
      // Oldest-first has to come back oldest-first. Sorting in here would
      // quietly override the order the user picked in the header.
      final groups = group(<DateTime>[
        DateTime(2026, 3, 1),
        DateTime(2026, 8, 3),
        DateTime(2026, 8, 4),
      ]);

      expect(groups.map((g) => g.section.kind), <DateSectionKind>[
        DateSectionKind.month,
        DateSectionKind.yesterday,
        DateSectionKind.today,
      ]);
    });

    test('every item lands in exactly one group', () {
      final List<DateTime> dates = <DateTime>[
        for (int i = 0; i < 60; i++) _now.subtract(Duration(days: i)),
      ];
      final groups = group(dates);
      expect(
        groups.fold<int>(0, (sum, g) => sum + g.items.length),
        dates.length,
      );
    });

    test('an empty list produces no headings', () {
      expect(group(<DateTime>[]), isEmpty);
    });

    test('a bucket revisited later starts a new group', () {
      // Only consecutive runs merge. An unsorted list must not silently
      // gather far-apart items under one heading, because the grid would then
      // show them in an order the headings do not explain.
      final groups = group(<DateTime>[
        DateTime(2026, 8, 4),
        DateTime(2026, 8, 3),
        DateTime(2026, 8, 4),
      ]);
      expect(groups, hasLength(3));
    });
  });
}
