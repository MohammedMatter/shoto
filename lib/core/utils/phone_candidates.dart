/// Runs of digits that *could* be somebody's number, for callers that will
/// then go and prove it.
///
/// **This is not a phone detector, and nothing here may become a button.**
/// The distinction is the whole reason this file exists apart from
/// `ActionExtractor`, which used to own this pattern and offered Call,
/// WhatsApp and Message on whatever it returned. On a screenshot of a table of
/// IBANs that meant three invitations to dial an account number. The pattern
/// was not the bug — no pattern over OCR text can be, because a bare run of
/// digits carries nothing that separates a phone number from an account
/// number — so the rule was deleted from the actions sheet rather than
/// tightened again. See `docs/decisions/smart-actions-precision.md`.
///
/// What survives is the *candidate* half, kept because one caller has the
/// missing evidence. [ContentTraits] only accepts a candidate that carries a
/// country code or has a word like "mobile" beside it, and what it produces is
/// a filter chip rather than a dialler. A wrong chip narrows a list; a wrong
/// dialler calls a stranger.
///
/// **A new caller is a decision, not an import.** Anything reaching for this
/// owes the same standard: evidence outside the digits, and a consequence the
/// user can see is wrong before it costs them anything.
abstract class PhoneCandidates {
  PhoneCandidates._();

  /// A run of digits with optional separators. Deliberately loose — the
  /// filtering that matters happens in [findIn] and again in the caller.
  ///
  /// **Separators are spaces, not whitespace.** `\s` includes the newline, so
  /// this used to reach across a line break and weld the tail of one line to
  /// the head of the next — on a real screenshot of a numbers table it
  /// produced "76350000\n159759". Worse than the bogus match itself is that
  /// the greedy span then swallowed a genuine number sitting alone on one of
  /// those lines.
  ///
  /// **Letters on either end disqualify it.** Without the boundaries this
  /// pattern happily started inside a word: an IBAN printed as
  /// `ABNA0417164300` on a reference page produced `0417164300`. Nothing
  /// writes a phone number welded to letters, so demanding a clear edge costs
  /// nothing and removes a whole class of account and reference numbers.
  static final RegExp _pattern = RegExp(
    r'(?<![0-9A-Za-z])\+?[0-9][0-9 \-().]{5,20}[0-9](?![0-9A-Za-z])',
  );

  /// Rejects date-shaped runs the loose pattern would otherwise swallow —
  /// "12/05/2024" and "12-05-2024" are eight digits with separators.
  static final RegExp _datePattern = RegExp(
    r'^\s*[0-9]{1,4}\s*[-/.]\s*[0-9]{1,2}\s*[-/.]\s*[0-9]{2,4}\s*$',
  );

  /// Every candidate in [text], as it appeared.
  ///
  /// The caller gets the text it can search for, not a cleaned value: locating
  /// the match is how it finds the words around it, and a normalised string
  /// would no longer be findable in the original.
  static List<String> findIn(String text) {
    final List<String> found = <String>[];
    for (final RegExpMatch match in _pattern.allMatches(text)) {
      final String raw = match[0]!;
      if (_datePattern.hasMatch(raw)) continue;

      final String digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length < 7 || digits.length > 15) continue;

      // **Twelve or more digits without a country code is not a phone
      // number.** E.164 allows up to fifteen, but a number that long is by
      // definition international, and an international number written for a
      // human carries its `+` (or a `00` prefix, which says the same thing in
      // different characters). What actually turns up at twelve-plus bare
      // digits is reference numbers, account numbers and meter readings.
      final String trimmed = raw.trim();
      final bool international =
          trimmed.startsWith('+') || trimmed.startsWith('00');
      if (!international && digits.length >= 12) continue;

      // A number wrapped in brackets that never close, or littered with more
      // punctuation than digits, is layout noise.
      if (raw.length - digits.length > digits.length) continue;

      found.add(trimmed);
    }
    return found;
  }

  /// Whether [candidate] names its own country, which is evidence no
  /// surrounding word has to supply.
  static bool isInternational(String candidate) =>
      candidate.startsWith('+') || candidate.startsWith('00');
}
