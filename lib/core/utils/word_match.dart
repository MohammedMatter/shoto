import 'package:shoto/core/utils/visual_vocabulary.dart';

/// Finds a word inside recognised text the way a person means it, not the way
/// `String.contains` does.
///
/// A filing rule that says "file anything containing *code*" was matching
/// **bar**code, **de**code and Uni**code**; one that said *total* matched
/// *totally*. Every one of those is a screenshot filed into the wrong folder
/// for a reason the user cannot see on screen — which is precisely the failure
/// that got automatic albums deleted, arriving through the back door of a
/// substring test.
///
/// So a needle has to sit on word boundaries. That alone would be wrong for
/// Arabic, though, and wrong in a way that looks like the feature ignoring the
/// language: Arabic writes its article and conjunctions **attached** to the
/// word, so a rule written `فاتورة` would stop firing on `الفاتورة`,
/// `والفاتورة` and `بالفاتورة` — the forms it actually appears in. Requiring a
/// hard boundary there does not make matching stricter, it makes it broken.
///
/// Hence two named, closed allowances on top of whole-word matching:
///
/// * [_prefixes] — the Arabic clitics that attach to the front of a word.
/// * [_suffixes] — the short endings that do not change which word it is:
///   English plurals, Arabic plurals and pronoun endings.
///
/// Both are **explicit lists**, not "any short run of letters". `totally` is
/// only two characters longer than `total`, so a length rule would have let
/// exactly the bug this class exists to fix straight back in.
///
/// Pure Dart, no Flutter imports, so all of it is unit-testable — the same
/// split used by [VisualVocabulary], [PerceptualHash] and [ScrollStitcher].
class WordMatch {
  const WordMatch._();

  /// Whether [text] contains [needle] as a word.
  ///
  /// Both sides go through [VisualVocabulary.normalize], so a rule written
  /// `فاتورة` still fires on OCR that read `فاتوره`, and case never matters.
  static bool contains(String text, String needle) {
    final String haystack = VisualVocabulary.normalize(text);
    final String target = VisualVocabulary.normalize(needle);

    // A needle with no word characters in it — punctuation, or the whitespace
    // left by a half-typed condition — must never match, or a rule swallows
    // the library the moment it is saved.
    if (target.isEmpty || !target.runes.any((r) => !_isSeparator(r))) {
      return false;
    }
    if (haystack.isEmpty) return false;

    int from = 0;
    while (true) {
      final int start = haystack.indexOf(target, from);
      if (start < 0) return false;

      final int end = start + target.length;
      if (_startsCleanly(haystack, start) && _endsCleanly(haystack, end)) {
        return true;
      }

      // Keep looking rather than giving up on the first occurrence: "code"
      // appearing inside "barcode" earlier in the text must not hide the
      // standalone "code" further down.
      from = start + 1;
    }
  }

  static bool _startsCleanly(String haystack, int start) {
    if (start == 0) return true;
    if (_isSeparator(haystack.codeUnitAt(start - 1))) return true;
    return _prefixes.contains(_wordRunBefore(haystack, start));
  }

  static bool _endsCleanly(String haystack, int end) {
    if (end == haystack.length) return true;
    if (_isSeparator(haystack.codeUnitAt(end))) return true;
    return _suffixes.contains(_wordRunAfter(haystack, end));
  }

  /// The letters attached to the front of the match, back to the last
  /// separator.
  static String _wordRunBefore(String haystack, int index) {
    int start = index;
    while (start > 0 && !_isSeparator(haystack.codeUnitAt(start - 1))) {
      start--;
    }
    return haystack.substring(start, index);
  }

  /// The letters attached to the end of the match, up to the next separator.
  static String _wordRunAfter(String haystack, int index) {
    int end = index;
    while (end < haystack.length && !_isSeparator(haystack.codeUnitAt(end))) {
      end++;
    }
    return haystack.substring(index, end);
  }

  /// Arabic clitics, generated rather than listed so the combinations cannot
  /// be half-written.
  ///
  /// Over-listing is free here for the same reason it is in
  /// [VisualVocabulary]: a combination nobody writes (`لال`) simply never
  /// appears in front of a match, so it costs nothing. A combination left
  /// *out* costs a rule that silently stops working.
  static final Set<String> _prefixes = {
    for (final String conjunction in const ['', 'و', 'ف'])
      for (final String particle in const ['', 'ب', 'ك', 'ل'])
        for (final String article in const ['', 'ال'])
          '$conjunction$particle$article',
    // ل + ال contracts to لل rather than لال, and the contracted form is the
    // one people actually write, so the loop above cannot produce it.
    'لل', 'ولل', 'فلل',
  }..remove('');

  /// Endings that leave the word the same word.
  ///
  /// Deliberately short. Arabic broken plurals (`فاتورة` → `فواتير`) are not
  /// here and cannot be: there is no rule for them a user could predict, and
  /// an unpredictable match is worse than a miss — the miss is visible in the
  /// preview count, the false match is not.
  static const Set<String> _suffixes = {
    's', 'es', // invoice → invoices
    'ات', 'ين', 'ون', // فاتورة → فاتورات
    'ها', 'هم', 'هن', 'كم', 'ه', 'ك', 'ي', // attached pronouns
  };

  /// Whether this character ends a word.
  ///
  /// Written as "what separates" rather than "what is a letter", so a script
  /// nobody here anticipated defaults to being part of a word instead of
  /// being chopped in half.
  static bool _isSeparator(int rune) {
    if (rune <= 0x2F) return true; // space and !"#$%&'()*+,-./
    if (rune >= 0x3A && rune <= 0x40) return true; // :;<=>?@
    if (rune >= 0x5B && rune <= 0x60) return true; // [\]^_`
    if (rune >= 0x7B && rune <= 0x7E) return true; // {|}~
    if (rune >= 0x2000 && rune <= 0x206F) return true; // – — “ ” …
    if (rune >= 0x3000 && rune <= 0x303F) return true; // CJK punctuation

    return switch (rune) {
      0x00A0 || 0x00AB || 0x00BB => true, // nbsp, « »
      0x060C || 0x061B || 0x061F || 0x06D4 => true, // ، ؛ ؟ ۔
      _ => false,
    };
  }
}
