/// Which dated heading a screenshot belongs under.
///
/// Named buckets near the present and calendar months further back, because
/// that is how people actually address their own recent past: "yesterday" is
/// a real location in memory and "4 August" is not, right up until the point
/// where it is the only handle left.
enum DateSectionKind {
  today,
  yesterday,

  /// Within the last seven days, but not today or yesterday.
  thisWeek,

  /// Within the last thirty days, and not covered above.
  thisMonth,

  /// Anything older, addressed by the month it happened in.
  month,
}

/// A heading and the range it covers.
///
/// [month] carries the first day of its month so the label can be formatted in
/// the user's locale by the widget that draws it — building a localised string
/// here would drag `BuildContext` into a pure function and freeze the label at
/// whatever language was current when the list was grouped.
class DateSection {
  final DateSectionKind kind;

  /// Set only when [kind] is [DateSectionKind.month].
  final DateTime? month;

  const DateSection(this.kind, {this.month});

  /// Stable across rebuilds, so a sliver's key survives one arriving above it.
  String get id => switch (kind) {
    DateSectionKind.month =>
      'month-${month!.year}-${month!.month.toString().padLeft(2, '0')}',
    _ => kind.name,
  };

  @override
  bool operator ==(Object other) =>
      other is DateSection && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// One heading and the items sitting under it.
class DatedGroup<T> {
  final DateSection section;
  final List<T> items;
  const DatedGroup({required this.section, required this.items});
}

/// Splits an already-ordered list into dated runs.
///
/// **Order is the caller's business, not this function's.** It walks the list
/// once and starts a new group whenever the bucket changes, which means a list
/// sorted oldest-first comes back oldest-first with its headings in the same
/// order. Sorting here would silently override the sort the user picked.
///
/// [now] is a parameter rather than a `DateTime.now()` call so the boundaries
/// are testable — "today" is the one thing in this file that cannot be checked
/// against a fixed expectation otherwise.
List<DatedGroup<T>> groupByDate<T>(
  List<T> items, {
  required DateTime Function(T item) dateOf,
  required DateTime now,
}) {
  final List<DatedGroup<T>> groups = <DatedGroup<T>>[];

  for (final T item in items) {
    final DateSection section = sectionFor(dateOf(item), now: now);
    if (groups.isNotEmpty && groups.last.section == section) {
      groups.last.items.add(item);
      continue;
    }
    groups.add(DatedGroup<T>(section: section, items: <T>[item]));
  }

  return groups;
}

/// Which bucket [date] falls in, relative to [now].
///
/// Compared by calendar day rather than by elapsed hours: something captured
/// at 23:50 last night is "yesterday" at 00:10 even though it is twenty
/// minutes old, because that is what the user would call it.
DateSection sectionFor(DateTime date, {required DateTime now}) {
  final DateTime day = DateTime(date.year, date.month, date.day);
  final DateTime today = DateTime(now.year, now.month, now.day);
  final int daysAgo = today.difference(day).inDays;

  // A clock that has gone backwards, or an asset dated in the future — which
  // happens on restored files and on phones whose time was wrong. Filed under
  // today rather than given a heading of its own: the alternative is a
  // "tomorrow" section that exists because of a bug somewhere else.
  if (daysAgo <= 0) return const DateSection(DateSectionKind.today);
  if (daysAgo == 1) return const DateSection(DateSectionKind.yesterday);
  if (daysAgo < 7) return const DateSection(DateSectionKind.thisWeek);
  if (daysAgo < 30) return const DateSection(DateSectionKind.thisMonth);
  return DateSection(
    DateSectionKind.month,
    month: DateTime(date.year, date.month),
  );
}
