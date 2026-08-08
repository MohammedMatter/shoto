import 'package:shoto/core/utils/sensitive_data.dart';
import 'package:shoto/core/utils/text_cues.dart';
import 'package:shoto/features/smart_actions/data/services/event_extractor.dart';
import 'package:shoto/features/smart_actions/data/services/extraction.dart';
import 'package:shoto/features/smart_actions/data/services/place_extractor.dart';
import 'package:shoto/features/smart_actions/data/services/tracking_extractor.dart';
import 'package:shoto/features/smart_actions/data/services/wifi_extractor.dart';
import 'package:shoto/features/smart_actions/domain/entities/detected_action.dart';

/// Pulls actionable items out of the text OCR already recovered from a
/// screenshot — and, since the intent extractors were added, out of what that
/// text *means*.
///
/// The entity detectors answer "what is on this screen": a link to open, an
/// address to write to, a code to copy. The four intent detectors answer the
/// more useful question, "what is the user about to have to do": be somewhere
/// at three on Thursday, get to an address, join a network, find out where a
/// parcel is. Each of those replaces four taps and a retyped value, which is
/// the only reason any of this is worth the recognition pass.
///
/// Two ideas shape the whole design:
///
/// **Precision beats recall, and a rule that cannot reach it does not ship.**
/// A missed detection costs the user a long press and a manual copy. A wrong
/// one costs them their trust in every other row on the sheet. Every pattern
/// here is therefore tightened until it only fires on things that really are
/// what they claim to be — IBANs are checksum-verified rather than merely
/// shaped right, and a bare number is only treated as a verification code
/// when nearby words say so.
///
/// **There is deliberately no phone rule**, and it is the clearest thing this
/// file has to say about that principle. One lived here for a long time,
/// wrapped in guard after guard — no letters on either end, no date shapes,
/// seven to fifteen digits, twelve-plus only with a country code. It still
/// read a screenshot of a table of IBANs as three numbers to dial, and the
/// sheet offered Call, WhatsApp and Message on every one of them. The failure
/// is not in the guards; it is that a bare run of digits *has no feature that
/// distinguishes a phone number from an account number*, and no regex over
/// OCR text can invent one. Recognising a thing wrongly is worse than not
/// recognising it, because the user cannot tell which rows to check. If this
/// is ever re-proposed it needs a source of truth that is not the digits —
/// a `tel:` link, a contact card, a labelled field — not another guard.
/// See `docs/decisions/smart-actions-precision.md`.
///
/// **Matches must not overlap.** An email address contains something that
/// looks exactly like a web domain; a URL is full of digits that look like a
/// verification code. Patterns are applied in a fixed order and each one skips
/// any span already claimed, so a single piece of text can only ever produce
/// one action.
abstract class ActionExtractor {
  ActionExtractor._();

  /// Ceiling on results. Past a dozen the list stops being a shortcut and
  /// starts being another thing to read.
  static const int maxActions = 12;

  /// [now] and [dayFirst] only exist so the event rules can be tested without
  /// a clock or a device region; the app never passes them.
  static List<DetectedAction> extract(
    String rawText, {
    DateTime? now,
    bool? dayFirst,
  }) {
    if (rawText.trim().length < 4) return const [];

    final String text = normalizeDigits(rawText);
    final List<_Span> claimed = [];
    final List<DetectedAction> found = [];

    // Order matters: each pass may only claim text the earlier, more
    // specific passes left alone.
    //
    // The intent passes go first, and every one of them is there because it
    // reads a span some later pass would otherwise misread:
    //
    // - A Wi-Fi key is four to eight characters next to the word "password",
    //   which is the verification-code rule's exact definition of a code.
    // - A tracking number and a code are the same digits; only the label
    //   beside them tells them apart.
    // - A street line contains a house number the code rule would read as a
    //   code of its own.
    //
    // In every case the intent reading is both more specific and more useful,
    // so it claims the text first and the entity passes see what is left.
    _adopt(WifiExtractor.findIn(text), claimed, found);
    _adopt(
      EventExtractor.findIn(text, now: now, dayFirst: dayFirst),
      claimed,
      found,
    );
    _adopt(TrackingExtractor.findIn(text), claimed, found);
    _adopt(PlaceExtractor.findIn(text), claimed, found);

    _collect(text, _emailPattern, claimed, found, _buildEmail);
    _collect(text, _urlPattern, claimed, found, _buildLink);
    _collect(text, _ibanPattern, claimed, found, _buildIban);

    // **One source of truth for what is private.**
    //
    // Safe Share and this file used to answer the same question separately,
    // and on one screenshot they answered it opposite ways: a page of IBANs
    // where Safe Share offered to cover the account numbers while this sheet
    // offered to *call* three fragments of them. Two features, one image, two
    // contradictory verdicts — and a user who sees that stops believing
    // either.
    //
    // So the private spans are read from `SensitiveData` and claimed here,
    // which makes "what counts as private" a thing this file asks rather than
    // a thing it re-derives. It also deletes the two card patterns that used
    // to live here carrying a comment promising they matched
    // `SensitiveData`'s — a promise nothing enforced.
    _claimSensitive(text, claimed);
    _claimGroupedRuns(text, claimed);

    _collectCodes(text, claimed, found);

    // Sorting by kind rather than by position groups the chips into
    // something scannable, and keeps the most immediately useful ones first.
    found.sort((a, b) => a.kind.index.compareTo(b.kind.index));

    final List<DetectedAction> unique = [];
    for (final DetectedAction action in found) {
      if (unique.contains(action)) continue;
      unique.add(action);
      if (unique.length == maxActions) break;
    }
    return unique;
  }

  /// Rewrites Arabic-Indic and Persian digits as ASCII.
  ///
  /// Screenshots taken on an Arabic UI come back with ٠١٢٣٤٥٦٧٨٩, which no
  /// amount of `\d` will match. The mapping is character-for-character so
  /// every match offset still points at the right place in the original.
  static String normalizeDigits(String input) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in input.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(rune - 0x0660 + 0x30); // ٠-٩
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(rune - 0x06F0 + 0x30); // ۰-۹ (Persian/Urdu)
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  // -------------------------------------------------------------------
  // Patterns
  // -------------------------------------------------------------------

  /// **Spaces around the `@` are tolerated, because OCR puts them there.**
  ///
  /// A real screenshot of a sign-in screen came back as
  /// `wikihowseth @gmail.com` — the recogniser reads the isolated glyph with
  /// gaps either side often enough that refusing it loses ordinary addresses.
  /// The space is dropped from the value in [_buildEmail], so what the app
  /// acts on is still a valid address.
  ///
  /// Bounded to spaces and tabs rather than `\s`: crossing a newline would
  /// weld a word at the end of one line to a domain at the start of the next,
  /// which is exactly the mistake the phone pattern was making.
  static final RegExp _emailPattern = RegExp(
    r'[a-z0-9._%+\-]+[ \t]{0,2}@[ \t]{0,2}[a-z0-9.\-]+\.[a-z]{2,}',
    caseSensitive: false,
  );

  /// A local part has to contain a letter.
  ///
  /// Without it the relaxed spacing turns "see page 3 @ site.com" into an
  /// address belonging to "3". Every real local part has a letter in it.
  static final RegExp _emailLocalHasLetter = RegExp(
    r'[a-z]',
    caseSensitive: false,
  );

  /// Shortest local part accepted **when the match contains a space**.
  ///
  /// `a@b.com` is a legal address and is accepted written normally. Allowing
  /// the same two characters either side of a *spaced* `@` is what turns
  /// "meet me @ home.com" into somebody's address — so the relaxed form, which
  /// exists only to survive OCR, asks for a little more evidence that it is
  /// reading an address at all.
  static const int _minSpacedLocalPart = 3;

  /// Explicit URLs, plus bare domains restricted to a known TLD list.
  ///
  /// The TLD list is the whole reason this is safe: without it, "version
  /// 2.5.reboot" or an abbreviation with a full stop reads as a domain.
  /// Anything with a scheme or a `www.` prefix is unambiguous and doesn't
  /// need the list.
  static final RegExp _urlPattern = RegExp(
    r'(https?://[^\s<>"'
    "'"
    r']+)'
    r'|(www\.[^\s<>"'
    "'"
    r']+)'
    r'|([a-z0-9][a-z0-9\-]*(\.[a-z0-9\-]+)*\.'
    // The country entries were Gulf-and-Levant plus tr/uk/de, which quietly
    // meant a bare domain only resolved for two of the app's six languages —
    // ejemplo.es, exemple.fr, udaharan.in and misal.pk all read as plain text.
    // Anything carrying a scheme or www. was always fine; this list only
    // governs bare domains.
    r'(com|net|org|io|co|me|app|dev|sa|ae|jo|eg|ps|qa|kw|bh|om|tr|uk|de'
    r'|es|fr|in|pk|it|nl|pt|be|ch|se|br|mx|ar|ma|dz|tn|lb|iq|ly|ye|sd|sy'
    // Measured rather than guessed: a spread of forty real bare domains
    // only resolved for twenty-five, and every miss was a country or a
    // modern gTLD absent from this list. It is the one part of link
    // detection that fails by omission, so it is worth being generous —
    // the list exists to stop \"version 2.5.reboot\" reading as a domain,
    // and none of these collide with that.
    r'|ru|cn|jp|kr|au|ca|pl|gr|il|ir|ng|ke|za|ua|cz|ro|hu|at|dk|fi|no'
    r'|ie|nz|sg|my|id|th|vn|ph|cl|pe|ve|uy|ec|bo|py|do|gt|cr|pa'
    r'|news|blog|tech|life|world|space|club|live|studio|design|agency'
    r'|gov|edu|info|store|shop|online|site|link|xyz|tv|ai|cloud)'
    r'(/[^\s<>"'
    "'"
    r']*)?)',
    caseSensitive: false,
  );

  /// IBAN shape only — [_buildIban] does the real validation.
  ///
  /// Two spellings, because both are normal: run together on a statement, or
  /// spaced into groups of four the way banks print them. The spaced branch
  /// insists on exact four-character groups rather than "letters and spaces"
  /// — a loose quantifier would greedily eat the words following the IBAN,
  /// and since validity is checked afterwards in Dart the regex would never
  /// backtrack to the correct, shorter match.
  static final RegExp _ibanPattern = RegExp(
    r'\b[a-z]{2}[0-9]{2}'
    r'(?:[a-z0-9]{11,30}'
    r'|(?:\s[a-z0-9]{4}){2,7}(?:\s[a-z0-9]{1,3})?)\b',
    caseSensitive: false,
  );

  static final RegExp _standaloneNumber = RegExp(r'\b[0-9]{4,8}\b');

  /// Words that turn a bare number into a verification code. Without one of
  /// these nearby, four to eight digits is just a number.
  ///
  /// Matched as whole words via [TextCues] — `code` inside "barcode" and `pin`
  /// inside "shipping" were both turning ordinary numbers into codes, the
  /// former on a real screenshot from the test device.
  /// **One entry per shipped language, and no entry for a script the
  /// recogniser cannot read.**
  ///
  /// This list held Arabic, Hindi and Urdu cues for a long time and not one of
  /// them could ever match: `TextRecognitionScript.latin` is the only model
  /// bundled, so those characters never appear in the text this rule searches.
  /// They were careful, translated, and dead — which is the exact trap that
  /// decided the shipped language set (see
  /// `docs/decisions/shipped-languages.md`). The rule now is simple: a cue
  /// belongs here only if the recogniser can produce it.
  ///
  /// French needs no entry of its own beyond the accented spelling: "code" is
  /// the same word.
  static const List<String> _codeCues = [
    'code',
    'otp',
    'pin',
    'verification',
    'verify',
    'password',
    'passcode',
    // Spanish
    'código',
    'codigo',
    'verificación',
    'verificacion',
    'contraseña',
    // French
    'vérification',
    // German. "Code" is shared, but the compounds are what actually appear on
    // a German one-time-password screen, and TextCues matches whole words —
    // so "Bestätigungscode" needs to be listed, not inferred from "code".
    'bestätigungscode',
    'bestatigungscode',
    'sicherheitscode',
    'verifizierungscode',
    'kennwort',
    'passwort',
    // Italian
    'codice',
    'verifica',
    'parola',
    // Portuguese
    'código de verificação',
    'verificação',
    'verificacao',
    'senha',
    // Dutch
    'verificatiecode',
    'bevestigingscode',
    'wachtwoord',
    'toegangscode',
  ];

  /// How far either side of a number the cue may sit.
  static const int _cueWindow = 40;

  /// Line breaks allowed between a code and the word naming it.
  ///
  /// One, not zero: "Your verification code is" followed by the digits on the
  /// next line is how most one-time-password messages are laid out.
  static const int _maxCodeLineGap = 1;

  // -------------------------------------------------------------------
  // Builders — each returns null to reject a shaped-but-invalid match
  // -------------------------------------------------------------------

  static DetectedAction? _buildEmail(String match) {
    final String cleaned = match.replaceAll(RegExp(r'[ 	]'), '');
    final int at = cleaned.indexOf('@');
    if (at <= 0) return null;

    final String local = cleaned.substring(0, at);
    if (!_emailLocalHasLetter.hasMatch(local)) return null;
    if (cleaned.length != match.trim().length &&
        local.length < _minSpacedLocalPart) {
      return null;
    }

    return DetectedAction(
      kind: DetectedActionKind.email,
      value: cleaned.toLowerCase(),
      // The original spelling, so the sheet shows what is on the screenshot
      // rather than a tidied version the user cannot find by looking.
      display: match.trim(),
    );
  }

  static DetectedAction? _buildLink(String match) {
    // OCR frequently picks up the punctuation that ends the sentence a link
    // sits in; no real URL ends in one.
    final String trimmed = match.replaceAll(RegExp(r'[.,;:!?)\]]+$'), '');
    if (trimmed.isEmpty) return null;

    final String value =
        trimmed.startsWith(RegExp('https?://', caseSensitive: false))
        ? trimmed
        : 'https://$trimmed';

    return DetectedAction(
      kind: DetectedActionKind.link,
      value: value,
      display: trimmed,
    );
  }

  /// Accepts only checksum-valid IBANs.
  ///
  /// The shape alone (two letters, two digits, then alphanumerics) matches
  /// plenty of ordinary reference numbers and tracking codes. The ISO 7064
  /// mod-97 check is what makes this trustworthy enough to hand someone a
  /// button that copies bank details.
  static DetectedAction? _buildIban(String match) {
    final String candidate = match.toUpperCase().replaceAll(' ', '');
    if (candidate.length < 15 || candidate.length > 34) return null;

    // Move the first four characters to the end, then read letters as
    // two-digit numbers (A=10 … Z=35) and take the whole thing mod 97.
    final String rearranged =
        candidate.substring(4) + candidate.substring(0, 4);

    int remainder = 0;
    for (final int unit in rearranged.codeUnits) {
      final int digitValue;
      if (unit >= 0x30 && unit <= 0x39) {
        digitValue = unit - 0x30;
      } else if (unit >= 0x41 && unit <= 0x5A) {
        digitValue = unit - 0x41 + 10;
      } else {
        return null;
      }
      // Fold in one digit at a time: a 34-character IBAN is far too large
      // to hold in an int before taking the modulus.
      remainder = digitValue < 10
          ? (remainder * 10 + digitValue) % 97
          : (remainder * 100 + digitValue) % 97;
    }
    if (remainder != 1) return null;

    return DetectedAction(
      kind: DetectedActionKind.iban,
      value: candidate,
      display: _groupIban(candidate),
    );
  }

  static String _groupIban(String iban) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < iban.length; i += 4) {
      if (i > 0) buffer.write(' ');
      buffer.write(iban.substring(i, (i + 4).clamp(0, iban.length)));
    }
    return buffer.toString();
  }

  // -------------------------------------------------------------------
  // Scanning
  // -------------------------------------------------------------------

  static void _collect(
    String text,
    RegExp pattern,
    List<_Span> claimed,
    List<DetectedAction> found,
    DetectedAction? Function(String match) build,
  ) {
    for (final RegExpMatch match in pattern.allMatches(text)) {
      if (_overlaps(claimed, match.start, match.end)) continue;
      final DetectedAction? action = build(match.group(0)!);
      if (action == null) continue;
      claimed.add(_Span(match.start, match.end));
      found.add(action);
    }
  }

  /// Folds an intent extractor's results into the shared claim list.
  ///
  /// Skipping an already-claimed span matters between the intent passes too,
  /// not just against the entity ones: a Wi-Fi card that prints its network
  /// name as a street-like string, or an event whose venue line is also a
  /// postal address, would otherwise be listed twice under two headings.
  static void _adopt(
    List<Extraction> results,
    List<_Span> claimed,
    List<DetectedAction> found,
  ) {
    for (final Extraction result in results) {
      if (_overlaps(claimed, result.start, result.end)) continue;
      claimed.add(_Span(result.start, result.end));
      found.add(result.action);
    }
  }

  /// Verification codes need context, so they can't be expressed as one
  /// regex: the number is found first, then the surrounding words decide
  /// whether it means anything.
  /// Three or more groups of digits joined by single separators — the shape of
  /// an identifier somebody typed out to be read back.
  ///
  /// Claimed and never offered, exactly like a card. **A four-digit group
  /// inside a longer grouped run is part of a reference, not a verification
  /// code**, and nothing downstream can tell the difference once the run has
  /// been cut up: `\b[0-9]{4,8}\b` sees `8629` and `9487` in
  /// `GBFD 8629-9487-4145` as two perfectly ordinary standalone numbers.
  ///
  /// Found on the device, on the same IBAN reference page that cost the actions
  /// sheet its phone rule. With that rule gone the page came back offering four
  /// *verification codes* instead — chopped out of the account numbers, and
  /// vouched for by the words "country code" and "2 digit checksum" sitting a
  /// few characters away. The cue was doing its job; there was simply nothing
  /// left to cue about, because the number had already been broken into
  /// pieces that looked like codes.
  ///
  /// [_claimCards] does not cover this: it takes 12-19 digit runs that pass
  /// Luhn, and roughly nine in ten reference numbers fail Luhn — which is what
  /// makes claiming cards safe and what leaves this gap open.
  ///
  /// A real verification code is one group. Requiring three keeps every one of
  /// them reachable.
  static final RegExp _groupedRun = RegExp(
    r'(?<![0-9A-Za-z])[0-9]{3,6}(?:[ \-][0-9]{2,6}){2,}(?![0-9A-Za-z])',
  );

  static void _claimGroupedRuns(String text, List<_Span> claimed) {
    for (final RegExpMatch match in _groupedRun.allMatches(text)) {
      if (_overlaps(claimed, match.start, match.end)) continue;
      claimed.add(_Span(match.start, match.end));
    }
  }

  static void _collectCodes(
    String text,
    List<_Span> claimed,
    List<DetectedAction> found,
  ) {
    final String haystack = text.toLowerCase();

    for (final RegExpMatch match in _standaloneNumber.allMatches(text)) {
      if (_overlaps(claimed, match.start, match.end)) continue;

      if (!TextCues.anyNear(
        haystack,
        match.start,
        match.end,
        _cueWindow,
        _codeCues,
        // A code and the word announcing it are written together — same line,
        // or the line straight after when the sender breaks it. Anything
        // further apart is a heading that happens to be nearby, which is what
        // a page about barcode formats is made of.
        maxLineGap: _maxCodeLineGap,
      )) {
        continue;
      }

      final String digits = match.group(0)!;
      claimed.add(_Span(match.start, match.end));
      found.add(
        DetectedAction(
          kind: DetectedActionKind.code,
          value: digits,
          display: digits,
        ),
      );
    }
  }

  /// The kinds Safe Share covers that this sheet must not offer anything on.
  ///
  /// **Sensitive and actionable are not opposites**, which is why this is a
  /// list and not "everything `SensitiveData` found". Three kinds are both at
  /// once, and all three are the product:
  ///
  /// - an **email** is private, and writing to it is the whole point;
  /// - an **IBAN** is private, and copying it is why people screenshot one;
  /// - a **code** is private, and copying it before it expires is the single
  ///   most-used action in the app.
  ///
  /// Covering those before *sharing a picture* and acting on them *yourself*
  /// are different questions with different right answers, and collapsing
  /// them would delete the feature in the name of protecting it.
  ///
  /// What is left is the set with no answer to "and then what?" — a card
  /// number, a national ID, an order reference, a home address, somebody's
  /// name, or a run of digits that refuses to say what it is. There is
  /// nothing to offer on any of them, and every one of them is a shape some
  /// later rule here would otherwise misread.
  static const Set<SensitiveKind> _neverActionable = <SensitiveKind>{
    SensitiveKind.card,
    SensitiveKind.nationalId,
    SensitiveKind.orderNumber,
    SensitiveKind.postalAddress,
    SensitiveKind.personName,
    SensitiveKind.phone,
    SensitiveKind.number,
  };

  /// Claims every private span that has no action worth offering.
  ///
  /// Runs *after* the intent passes and before the entity ones. The order is
  /// the point: a tracking number is an order reference by another name, and
  /// `SensitiveData` calls "Order number 4567890" an order number — so
  /// running this first would silently delete the tracking action on every
  /// delivery notification the app was built to read. The intent passes have
  /// a label from the screenshot; this pass has a shape. A label wins.
  ///
  /// One extra scan of the text, on a sheet the user opened deliberately.
  /// The alternative is two detectors that agree by inspection until one of
  /// them is edited.
  static void _claimSensitive(String text, List<_Span> claimed) {
    for (final SensitiveMatch match in SensitiveData.findIn(text)) {
      if (!_neverActionable.contains(match.kind)) continue;
      if (_overlaps(claimed, match.start, match.end)) continue;
      claimed.add(_Span(match.start, match.end));
    }
  }

  static bool _overlaps(List<_Span> claimed, int start, int end) {
    for (final _Span span in claimed) {
      if (start < span.end && end > span.start) return true;
    }
    return false;
  }
}

class _Span {
  final int start;
  final int end;
  const _Span(this.start, this.end);
}
