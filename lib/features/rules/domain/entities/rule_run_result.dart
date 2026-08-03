/// What a pass of the rules over the library actually did.
///
/// Reports [examined] alongside [filed] because "0 filed" has two very
/// different meanings — nothing matched, or there was nothing left to look
/// at — and a screen that can't tell them apart looks broken in the second
/// case.
///
/// [unread] is the third meaning, and the one that used to be hidden. A pass
/// will only read so many never-before-seen screenshots before it stops, so
/// on a library that has never been indexed most of the "examined" ones were
/// matched against nothing at all. Reporting that as a clean "filed 3 of 200"
/// is not a small imprecision — it tells the user their rules do not work,
/// when what actually happened is that the run has not finished yet and
/// tapping again continues it.
class RuleRunResult {
  final int examined;
  final int filed;

  /// How many of [examined] SHOTO had nothing on file for and ran out of
  /// budget to read. Another pass picks up where this one stopped.
  final int unread;

  const RuleRunResult({
    required this.examined,
    required this.filed,
    this.unread = 0,
  });

  static const RuleRunResult none = RuleRunResult(examined: 0, filed: 0);

  /// Whether another pass would get further than this one did.
  bool get hasMoreToRead => unread > 0;
}
