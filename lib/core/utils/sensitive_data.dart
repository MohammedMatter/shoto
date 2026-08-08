import 'package:flutter/widgets.dart';
import 'package:shoto/core/localization/l10n.dart';

/// The kinds of private detail Shoto knows how to find in a screenshot.
///
/// Ordered by how badly it hurts to leak one, because that's the order the
/// review list is shown in — the card number has to be the first thing the
/// user sees, not the last.
///
/// Adding constants is free and so is reordering them — nothing persists
/// these, so a rename costs only the code that reads it.
enum SensitiveKind {
  card,
  iban,
  nationalId,
  code,
  postalAddress,
  personName,
  phone,
  email,
  orderNumber,

  /// A run of digits that is clearly private but refuses to say what it is.
  ///
  /// This exists because the alternative was lying. Every unlabelled seven to
  /// fifteen digit run used to be called a phone number, so an account
  /// balance, a room number, a meter reading and a policy number were all
  /// listed to the user as "Phone number" — and a review list whose labels are
  /// wrong is a review list nobody reads. Covering it is still right; naming
  /// it is what the app has no basis for.
  ///
  /// Last in the enum on purpose: it is the least damaging thing found, so it
  /// sits at the bottom of the review list.
  number;

  /// The name shown on the review list, in the app's language.
  ///
  /// This used to be a `final String label` set from an English literal in the
  /// enum declaration — so the safe-share screen listed "Card number" and
  /// "Bank account" in English no matter what the rest of the app was
  /// speaking. An enum constant cannot hold a translation, because there is no
  /// locale at the moment the constant is created; it can only hold a way to
  /// find one.
  String label(BuildContext context) => switch (this) {
    SensitiveKind.card => context.l10n.sensitiveCard,
    SensitiveKind.iban => context.l10n.sensitiveIban,
    SensitiveKind.nationalId => context.l10n.sensitiveNationalId,
    SensitiveKind.code => context.l10n.sensitiveCode,
    SensitiveKind.postalAddress => context.l10n.sensitiveAddress,
    SensitiveKind.personName => context.l10n.sensitiveName,
    SensitiveKind.phone => context.l10n.sensitivePhone,
    SensitiveKind.email => context.l10n.sensitiveEmail,
    SensitiveKind.orderNumber => context.l10n.sensitiveOrderNumber,
    SensitiveKind.number => context.l10n.sensitiveNumber,
  };

  /// Whether a checksum proved this, rather than a pattern suggesting it.
  bool get isCertain =>
      this == SensitiveKind.card || this == SensitiveKind.iban;
}

/// One private detail, and **exactly which characters of the text it is**.
///
/// The span is what makes substitution possible at all. Knowing that a line
/// holds a card number is enough to paint a black box over the whole line;
/// replacing the number with a believable one while leaving the words
/// "Card ending" in front of it untouched needs the offsets.
class SensitiveMatch {
  final SensitiveKind kind;

  /// Offsets into the string that was handed to [SensitiveData.findIn], not
  /// into any normalised copy of it.
  final int start;
  final int end;

  /// The original substring, exactly as it was recognised.
  final String value;

  const SensitiveMatch({
    required this.kind,
    required this.start,
    required this.end,
    required this.value,
  });

  int get length => end - start;

  @override
  String toString() => 'SensitiveMatch($kind, $start..$end, "$value")';
}

/// Finds private details in a piece of recognised text.
///
/// Every rule here errs the same way and it is the *opposite* of a
/// classifier's: a missed card number is a leak, so borderline cases are
/// flagged. The cost of over-flagging is one tap to switch a substitution
/// off; the cost of under-flagging is somebody's card number in a group chat.
///
/// Two rules nonetheless refuse to guess, because a checksum makes certainty
/// free: card numbers are Luhn-verified and IBANs are mod-97 verified. Those
/// two are the only detections shown as *certain*, and they are also the two
/// worth being certain about.
///
/// **Nothing here guesses at a name.** A capitalised pair of words is a
/// person in a chat and a button label everywhere else, and an app that
/// rewrites "Order Details" into "James Miller" is worse than one that misses
/// a name — a wrong cover is visible, a wrong *substitution* is not. So
/// names, addresses and order numbers are recognised in only two situations:
/// the screenshot says what the value is (a label in front of it), or the app
/// already knows the value because the user signed in with it. Both are
/// facts, neither is an inference.
abstract class SensitiveData {
  SensitiveData._();

  /// Every private detail in [text], in reading order, never overlapping.
  ///
  /// [ownerNames] is the signed-in user's own name and its parts, from
  /// [namesFrom]. It is the one piece of context that turns name detection
  /// from a guess into a lookup.
  static List<SensitiveMatch> findIn(
    String text, {
    Set<String> ownerNames = const {},
  }) {
    if (text.isEmpty) return const [];

    // Index-preserving: every rune is written back as a rune, so an offset
    // into this string is an offset into `text`. Nothing else in this file is
    // allowed to change the length either — every other normalisation carries
    // an index map instead (see [_MappedText]).
    final String source = _normalizeDigits(text);
    final List<SensitiveMatch> found = [];

    // Fixed order, each detector skipping what an earlier one claimed. An
    // email contains a domain, a delivery address contains a phone number, a
    // card number is sixteen digits and so is many an order reference — one
    // piece of text must only ever be one thing, and the strongest evidence
    // goes first. Same non-overlap rule the smart-actions extractor follows.
    //
    // The order encodes two rules learned the hard way:
    //
    // 1. A checksum or a distinctive shape beats a label. Coordinates are
    //    two decimals and a comma and nothing else looks like that, so they
    //    are claimed before the phone pattern eats "24.774265" as an eight
    //    digit number. IBANs come before cards for the same reason and it is
    //    not theoretical: a 24-character IBAN contains eighteen-digit runs,
    //    roughly one in ten of which passes Luhn by chance, and the card
    //    detector was quietly relabelling those bank accounts as cards.
    //    An IBAN proves itself twice over — a country prefix *and* its own
    //    checksum — so it goes first.
    // 2. **A label beats a shape.** "Order number 4567890" is seven digits,
    //    which is also a phone number — but the screenshot said what it was,
    //    and a caption is stronger evidence than a length. Every labelled
    //    detector therefore runs before the free-standing phone pattern.
    // 3. **A number nobody can name is still covered.** [_claimNumber] runs
    //    immediately after the phone rule and sweeps up every long digit run
    //    the named detectors passed over. It is last among the numeric rules
    //    so that anything with a name keeps it.
    //
    // Addresses go last on purpose. Their capture is one long run of text
    // that routinely swallows a phone number, and running them last plus
    // clipping (see [_addClipped]) is what keeps that phone listed as a
    // phone instead of disappearing into "Address".
    _claimCoordinates(source, found);
    _claimIban(source, found);
    _claimCard(source, found);
    _claimLabelledNumber(
      source,
      _nationalIdLabelled,
      SensitiveKind.nationalId,
      found,
    );
    _claimCode(source, found);
    _claimOrderNumber(source, found);
    _claimEmail(source, found);
    _claimPhone(source, found);
    _claimNumber(source, found);
    _claimOwnerName(source, ownerNames, found);
    _claimName(source, found);
    _claimAddress(source, found);

    found.sort(
      (SensitiveMatch a, SensitiveMatch b) => a.start.compareTo(b.start),
    );

    // Everything above matched against the digit-normalised copy, so every
    // `value` is currently spelled in ASCII numerals. The caller needs the
    // characters that are actually in their screenshot — an Arabic card
    // number has to come back as ٤١١١, both to be shown in the review list
    // and so the replacement can be rendered in the same numerals.
    if (source == text) return found;
    return <SensitiveMatch>[
      for (final SensitiveMatch m in found)
        SensitiveMatch(
          kind: m.kind,
          start: m.start,
          end: m.end,
          value: text.substring(m.start, m.end),
        ),
    ];
  }

  /// Every kind found in [text]. A single line can carry more than one.
  ///
  /// Answers *whether* a screenshot holds a card number, never where — the
  /// question worth asking when the positions are not going to be used.
  static Set<SensitiveKind> kindsIn(String text) =>
      findIn(text).map((SensitiveMatch m) => m.kind).toSet();

  /// The searchable forms of a person's full name: the whole thing, plus each
  /// part long enough not to collide with an ordinary word.
  ///
  /// Parts under three letters are dropped deliberately. "Al" or "Bo" sits
  /// inside half the words on a screen, and a name detector firing on a
  /// fragment would rewrite the interface around it.
  static Set<String> namesFrom(String? fullName) {
    if (fullName == null) return const {};
    final String clean = fullName.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length < 3) return const {};

    final Set<String> names = <String>{clean};
    for (final String part in clean.split(' ')) {
      if (part.length >= 3) names.add(part);
    }
    return names;
  }

  /// Arabic-Indic and Persian digits rewritten as ASCII, character for
  /// character. Without this a screenshot from an Arabic banking app hides
  /// its card number in plain sight.
  ///
  /// Rune-for-rune on purpose: the result has the same length as the input,
  /// so every offset found in it is also an offset into the caller's string.
  static String _normalizeDigits(String input) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in input.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(rune - 0x0660 + 0x30);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(rune - 0x06F0 + 0x30);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// True when [text] was written with Arabic-Indic numerals, so a
  /// replacement can be rendered in the numerals the screenshot already uses.
  /// A Latin `4532` dropped into an Arabic banking app is the one detail that
  /// gives an edit away.
  static bool usesArabicDigits(String text) {
    for (final int rune in text.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) return true;
      if (rune >= 0x06F0 && rune <= 0x06F9) return true;
    }
    return false;
  }

  // -------------------------------------------------------------------
  // Claim bookkeeping
  // -------------------------------------------------------------------

  static bool _free(List<SensitiveMatch> found, int start, int end) {
    for (final SensitiveMatch m in found) {
      if (start < m.end && m.start < end) return false;
    }
    return true;
  }

  static void _add(
    List<SensitiveMatch> found,
    SensitiveKind kind,
    String source,
    int start,
    int end,
  ) {
    if (start < 0 || end > source.length || start >= end) return;
    if (!_free(found, start, end)) return;
    found.add(
      SensitiveMatch(
        kind: kind,
        start: start,
        end: end,
        value: source.substring(start, end),
      ),
    );
  }

  /// Adds whatever part of [start]..[end] nobody has claimed, instead of
  /// dropping the whole thing on the first overlap.
  ///
  /// Only addresses need this, and they need it badly: a delivery address is
  /// one long run of text that routinely contains a phone number, and the
  /// phone detector runs first. Rejecting the address outright because four
  /// characters of it were already spoken for would leave the street showing
  /// — the exact failure this feature exists to prevent.
  static void _addClipped(
    List<SensitiveMatch> found,
    SensitiveKind kind,
    String source,
    int start,
    int end,
    int minimumLength,
  ) {
    final List<SensitiveMatch> blocking =
        found
            .where((SensitiveMatch m) => start < m.end && m.start < end)
            .toList()
          ..sort(
            (SensitiveMatch a, SensitiveMatch b) => a.start.compareTo(b.start),
          );

    int cursor = start;
    for (final SensitiveMatch m in blocking) {
      if (m.start > cursor) {
        final int stop = _trimEnd(source, cursor, m.start);
        if (stop - cursor >= minimumLength) {
          _add(found, kind, source, _trimStart(source, cursor, stop), stop);
        }
      }
      if (m.end > cursor) cursor = m.end;
    }
    if (end > cursor) {
      final int stop = _trimEnd(source, cursor, end);
      if (stop - cursor >= minimumLength) {
        _add(found, kind, source, _trimStart(source, cursor, stop), stop);
      }
    }
  }

  // -------------------------------------------------------------------
  // Checksum-backed detections
  // -------------------------------------------------------------------

  /// **A run following a `+` is a phone number, never a card.**
  ///
  /// Luhn passes about one run in ten by chance, and international numbers sit
  /// squarely in the 13-19 digit band a card occupies — `+49 151 12345678` is
  /// thirteen digits and does pass. It was being claimed as a card, which both
  /// lost the phone number and put a false detection into the one trait whose
  /// whole claim is that it is certain. No card is ever written with a leading
  /// plus, so refusing that one character costs nothing and closes the hole.
  static final RegExp _cardCandidate = RegExp(
    r'(?<![0-9+])(?:[0-9][ -]?){12,19}(?![0-9])',
  );

  /// A card printed as four groups of four, wrapped onto a second line.
  ///
  /// Narrow-field forms and receipts wrap, and OCR reports the wrap as a
  /// newline — `4539 1488\n0343 6467` was going unrecognised, which for the
  /// redaction screen means an unredacted card number in a shared image.
  ///
  /// **Every group must be exactly four digits, and that is what makes the
  /// newline safe.** Allowing a line break as a general separator would let
  /// this weld the tail of one line to the head of the next, and a run that
  /// long passes Luhn by chance about one time in ten — turning the only
  /// checksum-certain trait in the app into a guessing one. Card grouping is
  /// 4-4-4-4; the account numbers and reference runs that sit on adjacent
  /// lines in a real screenshot are not.
  static final RegExp _wrappedCardCandidate = RegExp(
    r'(?<![0-9+])[0-9]{4}(?:[ \-\n\r]{1,2}[0-9]{4}){3}(?![0-9])',
  );

  /// A 13-19 digit run that passes the Luhn checksum.
  ///
  /// Luhn is what separates a real card number from an order reference of the
  /// same length: roughly nine in ten random runs fail it, so flagging one
  /// that passes is a near-certainty rather than a guess.
  static void _claimCard(String source, List<SensitiveMatch> found) {
    for (final RegExpMatch match in <RegExpMatch>[
      ..._cardCandidate.allMatches(source),
      ..._wrappedCardCandidate.allMatches(source),
    ]) {
      final String raw = match.group(0)!;
      final String digits = raw.replaceAll(_nonDigit, '');
      if (digits.length < 13 || digits.length > 19) continue;
      if (!passesLuhn(digits)) continue;

      // The candidate pattern allows a trailing separator, which would
      // otherwise be swallowed into the replaced span and delete a space that
      // belonged to the sentence around it.
      int end = match.end;
      while (end > match.start && !_isDigit(source.codeUnitAt(end - 1))) {
        end--;
      }
      _add(found, SensitiveKind.card, source, match.start, end);
    }
  }

  static final RegExp _nonDigit = RegExp(r'[^0-9]');

  static bool _isDigit(int unit) => unit >= 0x30 && unit <= 0x39;

  /// The card checksum, shared rather than reimplemented.
  ///
  /// Public because [ActionExtractor] needs the same test: a Luhn-valid run
  /// must be claimed before its phone rule sees it, or a screenshot of card
  /// numbers is reported as a screen full of phone numbers to dial. A checksum
  /// copied into two files is a checksum that will eventually differ in one.
  static bool passesLuhn(String digits) {
    int sum = 0;
    bool doubleIt = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int value = digits.codeUnitAt(i) - 0x30;
      if (doubleIt) {
        value *= 2;
        if (value > 9) value -= 9;
      }
      sum += value;
      doubleIt = !doubleIt;
    }
    return sum % 10 == 0;
  }

  static final RegExp _ibanCandidate = RegExp(
    r'\b[a-z]{2}[0-9]{2}(?:[a-z0-9]{11,30}|(?:\s[a-z0-9]{4}){2,7}(?:\s[a-z0-9]{1,3})?)\b',
    caseSensitive: false,
  );

  static void _claimIban(String source, List<SensitiveMatch> found) {
    for (final RegExpMatch match in _ibanCandidate.allMatches(source)) {
      final String raw = match.group(0)!;
      if (_passesMod97(raw.toUpperCase().replaceAll(' ', ''))) {
        _add(found, SensitiveKind.iban, source, match.start, match.end);
      }
    }
  }

  static bool _passesMod97(String iban) {
    if (iban.length < 15 || iban.length > 34) return false;
    final String rearranged = iban.substring(4) + iban.substring(0, 4);

    int remainder = 0;
    for (final int unit in rearranged.codeUnits) {
      final int value;
      if (unit >= 0x30 && unit <= 0x39) {
        value = unit - 0x30;
      } else if (unit >= 0x41 && unit <= 0x5A) {
        value = unit - 0x41 + 10;
      } else {
        return false;
      }
      // One digit at a time — a 34-character IBAN is far larger than an int.
      remainder = value < 10
          ? (remainder * 10 + value) % 97
          : (remainder * 100 + value) % 97;
    }
    return remainder == 1;
  }

  // -------------------------------------------------------------------
  // Shared pattern pieces
  // -------------------------------------------------------------------

  /// Every letter this app expects a name or a street to be written in:
  /// ASCII, the accented Latin ranges, and Arabic.
  ///
  /// Spelled as explicit ranges rather than `\p{L}`, which would make each of
  /// these patterns depend on the Unicode flag being set correctly.
  static const String _letter = 'A-Za-zÀ-ɏ؀-ۿ';

  /// What sits between a label and its value. Horizontal space only —
  /// `\s` would let a label at the end of one line capture the next one.
  static const String _gap = '[ \t ]*';

  /// A colon-ish character, which is what makes a weak label safe to use.
  static const String _colon = '[:：∶]';

  /// The separator between a *numeric* field label and its value. A full stop
  /// counts here ("Invoice no. 55231") and deliberately does not count for
  /// word labels — after a number label a period is punctuation, after a word
  /// label it usually ends a sentence, and "Location. It was fine" is not an
  /// address.
  static const String _numberSep = ':：∶#№.';

  // -------------------------------------------------------------------
  // Verification codes and ID numbers
  // -------------------------------------------------------------------

  /// National / civil ID numbers run 9-11 digits and are nearly always
  /// labelled. The label is required — an unlabelled 10-digit run is far more
  /// often an order number.
  ///
  /// **One label per shipped country, chosen by digit count.** The list is not
  /// every identity document that exists; it is the ones whose *number* falls
  /// in this range, because a label whose value can never match is a label
  /// that does nothing. Spain's DNI is eight digits and a letter, and Italy's
  /// codice fiscale is sixteen alphanumerics — neither is here, and both would
  /// need their own pattern rather than a word in this one.
  static final RegExp _nationalIdLabelled = RegExp(
    '(?:national${_gap}id|civil${_gap}id|id$_gap(?:number|no)|identity|'
    'iqama|passport|'
    // German: Steuer-ID is 11 digits, Sozialversicherungsnummer 12 (so the
    // label is here for the ones that fit, and over-flagging is the right
    // bias for this file).
    'steuer$_gap-?${_gap}id|steueridentifikationsnummer|steuernummer|'
    'personalausweis|ausweisnummer|reisepass|'
    // Dutch: BSN is 9 digits.
    'burgerservicenummer|bsn|identiteitskaart|paspoort|'
    // Portuguese: NIF 9, CPF 11, cartão de cidadão 9.
    'cart(?:ã|a)o$_gap de$_gap cidad(?:ã|a)o|bilhete$_gap de$_gap identidade|'
    'n(?:º|o|umero)?$_gap de$_gap contribuinte|nif|cpf|passaporte|'
    // Italian / Spanish / French passport-and-document wording.
    'passaporto|pasaporte|passeport|documento$_gap de$_gap identidad|'
    'num(?:é|e)ro$_gap fiscal)'
    '$_gap(?:[$_numberSep]$_gap)*'
    r'([0-9]{9,11})',
    caseSensitive: false,
  );

  static void _claimLabelledNumber(
    String source,
    RegExp pattern,
    SensitiveKind kind,
    List<SensitiveMatch> found,
  ) {
    for (final RegExpMatch match in pattern.allMatches(source)) {
      final (int, int)? span = _tailGroup(match);
      if (span != null) _add(found, kind, source, span.$1, span.$2);
    }
  }

  /// Where the captured value sits, in the subject string's own coordinates.
  ///
  /// Dart's [Match] reports offsets for the whole match only — there is no
  /// per-group `start`. So **every labelled pattern in this file ends with
  /// its capture group**, which makes the value's span derivable from the
  /// match's end. Keep it that way: a pattern that puts anything after the
  /// group still compiles and still matches, and silently substitutes the
  /// wrong characters.
  static (int, int)? _tailGroup(RegExpMatch match) {
    final String? value = match.group(1);
    if (value == null || value.isEmpty) return null;
    return (match.end - value.length, match.end);
  }

  /// The mirror of [_tailGroup], for the one pattern whose value comes before
  /// its label ("482913 is your code").
  static (int, int)? _headGroup(RegExpMatch match) {
    final String? value = match.group(1);
    if (value == null || value.isEmpty) return null;
    return (match.start, match.start + value.length);
  }

  /// A short number sitting next to a word that says what it is. Unlike the
  /// checksum rules this needs the context, because four digits on their own
  /// are just a number.
  ///
  /// **`code` is a substring match here, and that is deliberate.** It is what
  /// already covers *Bestätigungscode*, *Sicherheitscode*, *verificatiecode*
  /// and *bevestigingscode* without listing them — German and Dutch build the
  /// compound around the same four letters. This file over-flags on purpose
  /// (see [SensitiveKind.isCertain]): every finding here is reviewed by eye
  /// before anything is shared, so a spurious match costs a glance and a
  /// missed one costs a leak. Do not tighten this to whole words to match
  /// `ActionExtractor`; the two have opposite biases for good reasons.
  ///
  /// What has to be spelled out is everything the substring cannot reach: the
  /// accented spellings, and the words that are not built on "code" at all.
  static final RegExp _codeAfterLabel = RegExp(
    '(?:code|otp|pin|passcode|password|verification|'
    // Spanish / Portuguese — the accent puts these out of reach of `code`.
    'c(?:ó|o)digo|verificaci(?:ó|o)n|verifica(?:ç|c)(?:ã|a)o|contrase(?:ñ|n)a|'
    'senha|'
    // French
    'v(?:é|e)rification|'
    // Italian
    'codice|verifica|'
    // German — Kennwort and Passwort share no stem with any of the above.
    'kennwort|passwort|'
    // Dutch
    'wachtwoord|toegangscode|verificatie)'
    r'\D{0,20}([0-9]{4,8})',
    caseSensitive: false,
  );

  static final RegExp _codeBeforeLabel = RegExp(
    r'([0-9]{4,8})\D{0,20}'
    '(?:code|otp|verification|c(?:ó|o)digo|verificaci(?:ó|o)n|'
    'verifica(?:ç|c)(?:ã|a)o|v(?:é|e)rification|codice|verifica|verificatie)',
    caseSensitive: false,
  );

  static void _claimCode(String source, List<SensitiveMatch> found) {
    for (final RegExpMatch match in _codeAfterLabel.allMatches(source)) {
      final (int, int)? span = _tailGroup(match);
      if (span != null) {
        _add(found, SensitiveKind.code, source, span.$1, span.$2);
      }
    }
    for (final RegExpMatch match in _codeBeforeLabel.allMatches(source)) {
      final (int, int)? span = _headGroup(match);
      if (span != null) {
        _add(found, SensitiveKind.code, source, span.$1, span.$2);
      }
    }
  }

  // -------------------------------------------------------------------
  // Contact details
  // -------------------------------------------------------------------

  static final RegExp _emailPattern = RegExp(
    r'[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}',
    caseSensitive: false,
  );

  static void _claimEmail(String source, List<SensitiveMatch> found) {
    final _MappedText view = _emailView(source);
    for (final RegExpMatch match in _emailPattern.allMatches(view.text)) {
      _add(
        found,
        SensitiveKind.email,
        source,
        view.sourceStart(match.start),
        view.sourceEnd(match.end),
      );
    }
  }

  /// Repairs the damage OCR does to an address before matching it.
  ///
  /// A user reported four email addresses in one screenshot and only three
  /// covered. The pattern above is correct; what reaches it is not. Text
  /// recognition routinely pads punctuation with spaces (`ali @ gmail.com`),
  /// reads a comma for a full stop (`ali@gmail,com`), and mistakes `@` for
  /// `©` — and any one of those turns a perfectly ordinary address into
  /// something no strict pattern will ever match.
  ///
  /// Being generous here is the right trade **for this feature specifically**.
  /// A missed address is a leak the user cannot undo once the screenshot is
  /// sent; an over-eager match is a substitution they can see in the preview
  /// and switch off in a second.
  ///
  /// The repair deletes characters, so the result carries an index map back
  /// to the original. A span found in the repaired copy's coordinates would
  /// land somewhere else entirely in the real one.
  static _MappedText _emailView(String input) {
    final StringBuffer out = StringBuffer();
    final List<int> starts = <int>[];
    final List<int> ends = <int>[];

    void emit(String char, int from, int to) {
      out.write(char);
      starts.add(from);
      ends.add(to);
    }

    int i = 0;
    while (i < input.length) {
      int j = i;
      while (j < input.length && _isSpace(input.codeUnitAt(j))) {
        j++;
      }

      // A glue character, with any surrounding space, collapses to itself —
      // and the whole run maps back to the source span it came from.
      if (j < input.length && _isGlue(input[j])) {
        int k = j + 1;
        while (k < input.length && _isSpace(input.codeUnitAt(k))) {
          k++;
        }
        emit(_glueOf(input[j]), i, k);
        i = k;
        continue;
      }

      if (j > i) {
        for (int s = i; s < j; s++) {
          emit(input[s], s, s + 1);
        }
        i = j;
        continue;
      }

      emit(input[i], i, i + 1);
      i++;
    }

    return _MappedText(out.toString(), starts, ends, input.length);
  }

  static bool _isSpace(int unit) =>
      unit == 0x20 || unit == 0x09 || unit == 0x00A0;

  static bool _isGlue(String char) =>
      char == '@' ||
      char == '.' ||
      char == ',' ||
      char == '＠' || // fullwidth @
      char == '©' ||
      char == '®';

  static String _glueOf(String char) => switch (char) {
    ',' => '.',
    '.' => '.',
    _ => '@',
  };

  /// Any run of digits long enough to be worth hiding, punctuation and all.
  ///
  /// This finds *numbers*, not phone numbers — which is the whole distinction
  /// this pair of detectors exists to draw. [_claimPhone] runs first and takes
  /// the runs that can prove what they are; [_claimNumber] takes what is left
  /// and says only what it knows.
  static final RegExp _numberCandidate = RegExp(
    r'\+?[0-9][0-9\s\-().]{5,30}[0-9]',
  );

  /// Rejects date-shaped runs, which have the same length and punctuation as
  /// a phone number and would otherwise be rewritten on every receipt.
  static final RegExp _datePattern = RegExp(
    r'^\s*[0-9]{1,4}\s*[-/.]\s*[0-9]{1,2}\s*[-/.]\s*[0-9]{2,4}\s*$',
  );

  /// Words that mean the number beside them is a phone number.
  ///
  /// `tel` leads the German, Italian, Spanish and French entries by prefix —
  /// *Telefon*, *telefono*, *teléfono*, *téléphone* all start with it and the
  /// alternation is a substring match — but the words that do not share that
  /// stem have to be listed: *Handy*, *Rufnummer*, *cellulare*, *telemóvel*,
  /// *GSM*.
  static final RegExp _phoneLabelled = RegExp(
    '(?:phone$_gap(?:number|no)?|mobile$_gap(?:number|no)?|cell|'
    'tel|telephone|whatsapp|fax|contact$_gap(?:number|no)|'
    // German
    'handy|rufnummer|mobilnummer|telefonnummer|'
    // Dutch
    'telefoonnummer|mobiel|gsm|'
    // Italian
    'cellulare|recapito|'
    // Portuguese / Spanish
    'telem(?:ó|o)vel|celular|m(?:ó|o)vil|'
    // French
    'portable)'
    '$_gap(?:[$_numberSep]$_gap)*'
    r'(\+?[0-9][0-9\s\-().]{5,20}[0-9])',
    caseSensitive: false,
  );

  /// A number is only called a phone number when it can show why.
  ///
  /// Three kinds of evidence, and nothing else counts:
  ///
  /// 1. A label in front of it. The screenshot said so.
  /// 2. A leading `+`. Nothing but a phone number is written with a country
  ///    code.
  /// 3. A leading zero with nine to eleven digits — the shape every mobile
  ///    number in the region is written in (`059…`, `05…`, `07…`, `01…`).
  ///
  /// Everything else is a number, and [_claimNumber] picks it up a moment
  /// later. That split costs nothing in safety, because both kinds are covered
  /// identically — the only thing that changes is what the review list claims,
  /// and it now only claims what it can support.
  static void _claimPhone(String source, List<SensitiveMatch> found) {
    for (final RegExpMatch match in _phoneLabelled.allMatches(source)) {
      final (int, int)? span = _tailGroup(match);
      if (span == null) continue;
      _add(found, SensitiveKind.phone, source, span.$1, span.$2);
    }

    for (final RegExpMatch match in _numberCandidate.allMatches(source)) {
      final String raw = match.group(0)!;
      if (_datePattern.hasMatch(raw)) continue;
      final int digits = raw.replaceAll(_nonDigit, '').length;
      if (digits < 7 || digits > 15) continue;

      final bool international = raw.startsWith('+');
      final bool localMobile =
          raw.startsWith('0') && digits >= 9 && digits <= 11;
      if (!international && !localMobile) continue;

      _add(found, SensitiveKind.phone, source, match.start, match.end);
    }
  }

  /// Every remaining long digit run, covered but not named.
  ///
  /// The upper bound is deliberately generous — twenty-four digits, well past
  /// a card number. A nineteen-digit account reference that fails Luhn used to
  /// fall through every detector here and out of the scan entirely: too long
  /// for the old phone rule, not a card because the checksum said so, not an
  /// order number because nothing labelled it. It was left showing in the
  /// shared copy. A number that long on a screen a user is about to send is
  /// worth a block whether or not the app can say what it is.
  static void _claimNumber(String source, List<SensitiveMatch> found) {
    for (final RegExpMatch match in _numberCandidate.allMatches(source)) {
      final String raw = match.group(0)!;
      if (_datePattern.hasMatch(raw)) continue;
      final int digits = raw.replaceAll(_nonDigit, '').length;
      if (digits < 7 || digits > 24) continue;
      _add(found, SensitiveKind.number, source, match.start, match.end);
    }
  }

  // -------------------------------------------------------------------
  // Names
  // -------------------------------------------------------------------

  /// Labels that name a person on their own, so the colon is optional.
  static final RegExp _nameStrongLabel = RegExp(
    '(?:full${_gap}name|account${_gap}holder|card${_gap}holder|cardholder|'
    'beneficiary|recipient|passenger|customer${_gap}name|'
    // German
    'kontoinhaber|karteninhaber|vollst(?:ä|a)ndiger${_gap}name|'
    'name$_gap des$_gap kontoinhabers|empf(?:ä|a)nger|zahlungsempf(?:ä|a)nger|'
    // Dutch
    'rekeninghouder|kaarthouder|volledige${_gap}naam|begunstigde|ontvanger|'
    // Italian / Portuguese — "nome completo" is the same phrase in both.
    'intestatario|titolare|beneficiario|nome$_gap completo|'
    'titular|benefici(?:á|a)rio|'
    // Spanish / French
    'titular$_gap de$_gap la$_gap cuenta|nombre$_gap completo|'
    'titulaire$_gap du$_gap compte|nom$_gap complet|b(?:é|e)n(?:é|e)ficiaire)'
    '$_gap$_colon?$_gap'
    '($_namePhrase)',
    caseSensitive: false,
  );

  /// Labels that only mean a person when a colon says so. Bare "name" is
  /// inside "filename" and "name your folder"; "Name:" is a field.
  ///
  /// **The lookbehind is what keeps these safe, and it is ASCII-only.** That
  /// is correct for every entry here: all of them are Latin, so `filename`,
  /// `voornaam` and `cognome` cannot smuggle in `name`, `naam` or `nome`.
  static final RegExp _nameWeakLabel = RegExp(
    '(?<![A-Za-z])'
    '(?:name|from|to|sender|'
    // German: "Name" is spelled identically; "Von"/"An" are the from/to pair.
    'von|an|absender|'
    // Dutch
    'naam|voornaam|achternaam|afzender|van|aan|'
    // Italian
    'nome|cognome|mittente|da|a|'
    // Portuguese / Spanish
    'apelido|apellidos|remetente|remitente|de|para|'
    // French
    'nom|pr(?:é|e)nom|exp(?:é|e)diteur|(?:à|a))'
    '$_gap$_colon$_gap'
    '($_namePhrase)',
    caseSensitive: false,
  );

  /// One to four words of letters — long enough for "Mohammed Abo Matter",
  /// short enough that it cannot run away with the rest of a sentence.
  static const String _namePhrase =
      '[$_letter][$_letter\'’.\\-]*'
      '(?:[  ]+[$_letter][$_letter\'’.\\-]*){0,3}';

  static void _claimName(String source, List<SensitiveMatch> found) {
    for (final RegExp pattern in <RegExp>[_nameStrongLabel, _nameWeakLabel]) {
      for (final RegExpMatch match in pattern.allMatches(source)) {
        final (int, int)? span = _tailGroup(match);
        if (span == null) continue;
        final int end = _trimEnd(source, span.$1, span.$2);
        if (end - span.$1 < 2) continue;
        _add(found, SensitiveKind.personName, source, span.$1, end);
      }
    }
  }

  /// Finds the signed-in user's own name wherever it appears.
  ///
  /// This is the one name detection that needs no label and still isn't a
  /// guess: Google or Apple told the app this name at sign-in, so finding it
  /// in a screenshot is a lookup. It is also the case the feature exists for
  /// — the name at the top of a chat, on a boarding pass, in an order
  /// confirmation, none of which are labelled "Name:".
  static void _claimOwnerName(
    String source,
    Set<String> names,
    List<SensitiveMatch> found,
  ) {
    if (names.isEmpty) return;

    final _MappedText view = _foldForNames(source);
    // Longest first, so "Mohammed Ahmed" is claimed as one name rather than
    // leaving "Ahmed" to be found on its own straight afterwards.
    final List<String> ordered = names.toList()
      ..sort((String a, String b) => b.length.compareTo(a.length));

    for (final String name in ordered) {
      final String needle = _foldForNames(name).text;
      if (needle.trim().length < 3) continue;

      int from = 0;
      while (true) {
        final int at = view.text.indexOf(needle, from);
        if (at < 0) break;
        from = at + 1;

        final int after = at + needle.length;
        if (_isWordChar(view.text, at - 1)) continue;
        if (_isWordChar(view.text, after)) continue;

        _add(
          found,
          SensitiveKind.personName,
          source,
          view.sourceStart(at),
          view.sourceEnd(after),
        );
      }
    }
  }

  static bool _isWordChar(String text, int index) {
    if (index < 0 || index >= text.length) return false;
    final int unit = text.codeUnitAt(index);
    if (unit >= 0x30 && unit <= 0x39) return true;
    if (unit >= 0x41 && unit <= 0x5A) return true;
    if (unit >= 0x61 && unit <= 0x7A) return true;
    if (unit >= 0x00C0 && unit <= 0x024F) return true;
    if (unit >= 0x0620 && unit <= 0x06FF) return true;
    return false;
  }

  /// Case-folded, Arabic-normalised, whitespace-collapsed — carrying an index
  /// map home, because every one of those steps can delete characters.
  ///
  /// The Arabic rules are the ones the search vocabulary already uses, for the
  /// same reason: a name written with a hamza in one place and without it in
  /// another is one name, and ta-marbuta is the rule everybody forgets.
  static _MappedText _foldForNames(String input) {
    final StringBuffer out = StringBuffer();
    final List<int> starts = <int>[];
    final List<int> ends = <int>[];

    int i = 0;
    int? spaceFrom;
    while (i < input.length) {
      final int unit = input.codeUnitAt(i);

      // Harakat and tatweel carry no identity and are dropped outright.
      if ((unit >= 0x064B && unit <= 0x0652) || unit == 0x0640) {
        i++;
        continue;
      }

      if (_isSpace(unit) || unit == 0x0A || unit == 0x0D) {
        spaceFrom ??= i;
        i++;
        continue;
      }

      if (spaceFrom != null) {
        if (out.isNotEmpty) {
          out.write(' ');
          starts.add(spaceFrom);
          ends.add(i);
        }
        spaceFrom = null;
      }

      final String folded = switch (unit) {
        0x0623 || 0x0625 || 0x0622 || 0x0671 => 'ا',
        0x0649 => 'ي',
        0x0629 => 'ه',
        _ => String.fromCharCode(unit).toLowerCase(),
      };

      // toLowerCase can widen a character (U+0130 becomes two). Emitting one
      // map entry per output unit keeps the mapping exact whatever it does.
      for (int k = 0; k < folded.length; k++) {
        out.write(folded[k]);
        starts.add(i);
        ends.add(i + 1);
      }
      i++;
    }

    return _MappedText(out.toString(), starts, ends, input.length);
  }

  // -------------------------------------------------------------------
  // Addresses
  // -------------------------------------------------------------------

  /// Labels that mean an address on their own.
  static final RegExp _addressStrongLabel = RegExp(
    '(?:shipping${_gap}address|billing${_gap}address|delivery${_gap}address|'
    'home${_gap}address|deliver${_gap}to|ship${_gap}to|'
    // German
    'lieferadresse|rechnungsadresse|versandadresse|privatadresse|anschrift|'
    // Dutch
    'bezorgadres|afleveradres|factuuradres|verzendadres|woonadres|'
    // Italian
    'indirizzo$_gap di$_gap(?:spedizione|consegna|fatturazione)|'
    // Portuguese
    'morada$_gap de$_gap entrega|endere(?:ç|c)o$_gap de$_gap'
    '(?:entrega|factura(?:ç|c)(?:ã|a)o|fatura(?:ç|c)(?:ã|a)o)|'
    // Spanish / French
    'direcci(?:ó|o)n$_gap de$_gap(?:env(?:í|i)o|entrega|facturaci(?:ó|o)n)|'
    'adresse$_gap de$_gap(?:livraison|facturation))'
    '$_gap$_colon?$_gap'
    r'([^\n]{6,90})',
    caseSensitive: false,
  );

  /// Bare "address" or "location" needs the colon: "location services" and
  /// "address book" are not addresses.
  ///
  /// German *Adresse* and French *adresse* are reached by the English
  /// `address`? **No** — and this is the trap worth naming. The lookbehind
  /// forbids a letter before the match, but nothing forbids letters *inside*
  /// the alternation's own reach: `address` cannot match `adresse`, which is
  /// spelled with one `d`. Each spelling is listed.
  static final RegExp _addressWeakLabel = RegExp(
    '(?<![A-Za-z])'
    '(?:address|location|'
    // German / French — one `d`, and German capitalises but the match is
    // case-insensitive.
    'adresse|standort|'
    // Dutch
    'adres|locatie|woonplaats|'
    // Italian
    'indirizzo|posizione|'
    // Portuguese / Spanish
    'endere(?:ç|c)o|morada|direcci(?:ó|o)n|ubicaci(?:ó|o)n|localiza(?:ç|c)(?:ã|a)o)'
    '$_gap$_colon$_gap'
    r'([^\n]{6,90})',
    caseSensitive: false,
  );

  /// A street line that says what it is without being labelled: a house
  /// number, at least one word, then a word that only ever ends a street
  /// name. The intervening word is required — without it "1 st" matches.
  ///
  /// **This is the English word order and only that.** The number leads. Every
  /// other shipped language writes it last, which no amount of vocabulary
  /// added here can express — see [_streetLineSuffixed] and
  /// [_streetLinePrefixed].
  static final RegExp _streetLine = RegExp(
    r'\b[0-9]{1,5}[ ,]+(?:[A-Za-z0-9.À-ɏ\-]+[ ]+){1,4}'
    r'(?:street|st|avenue|ave|road|rd|boulevard|blvd|lane|ln|drive|dr|'
    r'court|ct|way|square|sq|highway|hwy)\b\.?',
    caseSensitive: false,
  );

  /// German and Dutch: the street type is welded onto the name and the house
  /// number follows — *Hauptstraße 12*, *Kerkstraat 5a*.
  ///
  /// **The house number is required, and it is doing the same job as the
  /// intervening word in [_streetLine].** Without it, `Weg` and `Ring` are
  /// ordinary German nouns and `hof` and `kade` ordinary Dutch ones; a number
  /// after them is what makes the line an address rather than a sentence.
  ///
  /// A trailing letter is allowed (`5a`, `12b`) — standard in both countries
  /// and absent from the English form.
  static final RegExp _streetLineSuffixed = RegExp(
    r'\b[A-Za-zÀ-ɏ][A-Za-zÀ-ɏ.\-]{1,30}'
    r'(?:stra(?:ß|ss)e|str\.|weg|platz|allee|gasse|ring|damm|ufer|'
    r'straat|laan|plein|kade|singel|dijk|gracht|hof)'
    r'[ ]+[0-9]{1,4}[ ]?[a-zA-Z]?\b',
    caseSensitive: false,
  );

  /// Italian, Portuguese, Spanish and French: the street type leads, the name
  /// follows, the house number ends it — *Via Roma 12*, *Rua Augusta 24*.
  ///
  /// **The number is required, and the first draft of this pattern proved
  /// why.** It was shaped after the Arabic rule it replaces — lead word, then
  /// the rest of the line — and *"Il corso di italiano inizia lunedì"* came
  /// back as somebody's home address. `corso` is a street in Milan and a
  /// course of study everywhere else; so are `largo`, `carrera` and `place`.
  /// The lead word alone is not evidence, which is the same conclusion
  /// [_streetLineSuffixed] reaches from the other direction.
  ///
  /// An unnumbered street written on its own is given up deliberately. The
  /// labelled rules above still catch it whenever the screenshot says
  /// "Lieferadresse:", and a review list that covers a sentence about a
  /// language course is a review list the user stops reading.
  static final RegExp _streetLinePrefixed = RegExp(
    r'(?<![A-Za-zÀ-ɏ])'
    r'(?:via|viale|piazza|corso|vicolo|largo|'
    r'rua|avenida|travessa|pra(?:ç|c)a|alameda|'
    r'calle|plaza|paseo|carrera|'
    r'rue|avenue|boulevard|chemin|impasse|place)'
    r"[ ]+(?:[A-Za-zÀ-ɏ0-9'’.\-]+[ ]+){1,4}"
    r'[0-9]{1,4}[ ]?[a-zA-Z]?\b',
    caseSensitive: false,
  );

  /// A latitude/longitude pair: the most precise location a screenshot can
  /// carry, and the least likely to be recognised as one.
  static final RegExp _coordinates = RegExp(
    r'-?[0-9]{1,3}\.[0-9]{4,}\s*,\s*-?[0-9]{1,3}\.[0-9]{4,}',
  );

  /// Claimed before anything else that reads digits: a latitude/longitude
  /// pair is eight digits and a dot, which the phone pattern is delighted to
  /// take, and losing it means shipping the one detail in a screenshot that
  /// says exactly where somebody was standing.
  static void _claimCoordinates(String source, List<SensitiveMatch> found) {
    for (final RegExpMatch match in _coordinates.allMatches(source)) {
      _add(found, SensitiveKind.postalAddress, source, match.start, match.end);
    }
  }

  static void _claimAddress(String source, List<SensitiveMatch> found) {
    for (final RegExp pattern in <RegExp>[
      _addressStrongLabel,
      _addressWeakLabel,
    ]) {
      for (final RegExpMatch match in pattern.allMatches(source)) {
        final (int, int)? span = _tailGroup(match);
        if (span == null) continue;
        _addClipped(
          found,
          SensitiveKind.postalAddress,
          source,
          span.$1,
          span.$2,
          6,
        );
      }
    }
    for (final RegExp pattern in <RegExp>[_streetLine, _streetLineSuffixed, _streetLinePrefixed]) {
      for (final RegExpMatch match in pattern.allMatches(source)) {
        _addClipped(
          found,
          SensitiveKind.postalAddress,
          source,
          match.start,
          match.end,
          6,
        );
      }
    }
  }

  // -------------------------------------------------------------------
  // Order and reference numbers
  // -------------------------------------------------------------------

  /// Labels that say "a reference number follows" on their own.
  static final RegExp _orderStrongLabel = RegExp(
    '(?<![A-Za-z])'
    '(?:order$_gap(?:number|no|id)|invoice$_gap(?:number|no)|'
    'reference$_gap(?:number|no)|tracking$_gap(?:number|no|id)|'
    'booking$_gap(?:number|no|reference|ref)|'
    'confirmation$_gap(?:number|no|code)|awb|waybill|'
    // German
    'bestellnummer|rechnungsnummer|auftragsnummer|sendungsnummer|'
    'buchungsnummer|kundennummer|vorgangsnummer|referenznummer|'
    // Dutch
    'bestelnummer|factuurnummer|ordernummer|zendingsnummer|track$_gap&$_gap'
    'trace|boekingsnummer|klantnummer|referentienummer|'
    // Italian
    'numero$_gap(?:d(?:i|ell)$_gap ?ordine|fattura|di$_gap prenotazione|'
    'di$_gap spedizione|di$_gap riferimento)|'
    // Portuguese
    'n(?:ú|u)mero$_gap do$_gap(?:pedido|encomenda)|n(?:ú|u)mero$_gap da$_gap'
    '(?:factura|fatura|reserva)|c(?:ó|o)digo$_gap de$_gap rastreio|'
    // Spanish / French
    'n(?:ú|u)mero$_gap de$_gap(?:pedido|factura|reserva|seguimiento)|'
    'num(?:é|e)ro$_gap de$_gap(?:commande|facture|suivi|r(?:é|e)servation))'
    '$_gap(?:[$_numberSep]$_gap)*'
    '($_referenceValue)',
    caseSensitive: false,
  );

  /// Labels that need a colon or a hash to mean a number rather than a word.
  /// "Order Details" is a heading; "Order: A82-4471" is a reference.
  static final RegExp _orderWeakLabel = RegExp(
    '(?<![A-Za-z])'
    '(?:order|invoice|reference|ref|tracking|booking|'
    // German
    'bestellung|rechnung|auftrag|sendung|buchung|referenz|beleg|'
    // Dutch
    'bestelling|factuur|order|zending|boeking|referentie|'
    // Italian
    'ordine|fattura|prenotazione|spedizione|riferimento|ricevuta|'
    // Portuguese / Spanish
    'pedido|encomenda|fatura|factura|reserva|rastreio|seguimiento|'
    // French
    'commande|facture|r(?:é|e)servation|suivi)'
    '$_gap(?:[$_numberSep]$_gap)+'
    '($_referenceValue)',
    caseSensitive: false,
  );

  static const String _referenceValue = r'[A-Za-z0-9][A-Za-z0-9\-/]{4,}';

  /// A reference is only claimed when the screenshot says it is one **and**
  /// the value looks like one.
  ///
  /// The digit requirement is what stops "Order Details" from being rewritten
  /// as a tracking number — the single most likely way this detector could
  /// damage an otherwise ordinary screenshot, and the reason the weak labels
  /// also insist on a colon.
  static void _claimOrderNumber(String source, List<SensitiveMatch> found) {
    for (final RegExp pattern in <RegExp>[_orderStrongLabel, _orderWeakLabel]) {
      for (final RegExpMatch match in pattern.allMatches(source)) {
        final (int, int)? span = _tailGroup(match);
        if (span == null) continue;
        final int start = span.$1;
        final int end = _trimEnd(source, start, span.$2);
        if (end - start < 5) continue;
        if (!source.substring(start, end).contains(_anyDigit)) continue;
        _add(found, SensitiveKind.orderNumber, source, start, end);
      }
    }
  }

  static final RegExp _anyDigit = RegExp(r'[0-9]');

  // -------------------------------------------------------------------
  // Trimming
  // -------------------------------------------------------------------

  static int _trimEnd(String source, int start, int end) {
    int cursor = end.clamp(0, source.length);
    while (cursor > start && _isEdgeNoise(source.codeUnitAt(cursor - 1))) {
      cursor--;
    }
    return cursor;
  }

  static int _trimStart(String source, int start, int end) {
    int cursor = start.clamp(0, source.length);
    while (cursor < end && _isEdgeNoise(source.codeUnitAt(cursor))) {
      cursor++;
    }
    return cursor;
  }

  /// Punctuation and space that belong to the sentence, not to the value.
  /// Leaving them inside the span deletes them from the exported image.
  static bool _isEdgeNoise(int unit) =>
      unit == 0x20 || // space
      unit == 0x09 || // tab
      unit == 0x00A0 || // nbsp
      unit == 0x2E || // .
      unit == 0x2C || // ,
      unit == 0x060C || // ،
      unit == 0x3A || // :
      unit == 0x2D; // -
}

/// A rewritten copy of a string that can still say where each of its
/// characters came from.
///
/// Every normalisation in this file except digit folding deletes or merges
/// characters, and a span found in a normalised copy is worthless unless it
/// can be reported in the caller's coordinates — a substitution drawn from
/// the wrong offsets lands on the wrong words and leaves the real ones
/// showing.
class _MappedText {
  final String text;
  final List<int> _starts;
  final List<int> _ends;
  final int _sourceLength;

  const _MappedText(this.text, this._starts, this._ends, this._sourceLength);

  int sourceStart(int index) {
    if (index < 0) return 0;
    if (index >= _starts.length) return _sourceLength;
    return _starts[index];
  }

  /// [index] is an *exclusive* end in this copy's coordinates.
  int sourceEnd(int index) {
    if (index <= 0) return 0;
    if (index > _ends.length) return _sourceLength;
    return _ends[index - 1];
  }
}
