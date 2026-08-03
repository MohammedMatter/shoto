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
/// The original five detectors answer "what is on this screen": a number to
/// call, a link to open, a code to copy. The four intent detectors answer the
/// more useful question, "what is the user about to have to do": be somewhere
/// at three on Thursday, get to an address, join a network, find out where a
/// parcel is. Each of those replaces four taps and a retyped value, which is
/// the only reason any of this is worth the recognition pass.
///
/// Two ideas shape the whole design:
///
/// **Precision beats recall.** A missed phone number costs the user a long
/// press and a manual copy. A *wrong* one offers to dial a stranger. Every
/// pattern here is therefore tightened until it only fires on things that
/// really are what they claim to be — IBANs are checksum-verified rather
/// than merely shaped right, and a bare number is only treated as a
/// verification code when nearby words say so.
///
/// **Matches must not overlap.** An email address contains something that
/// looks exactly like a web domain; a URL is full of digits that look like a
/// phone number. Patterns are applied in a fixed order and each one skips
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
    // - An event's "12/05/2026 3:00" is thirteen digits with separators, and
    //   the phone rule is happy to take it.
    // - A ten-digit Aramex number and a ten-digit mobile number are the same
    //   characters; only the label beside them tells them apart.
    // - A street line contains a house number, and coordinates are two long
    //   decimals that the phone pattern reads as one long number.
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
    _collectCodes(text, claimed, found);
    _collect(text, _phonePattern, claimed, found, _buildPhone);

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

  static final RegExp _emailPattern = RegExp(
    r'[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}',
    caseSensitive: false,
  );

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
    r'(com|net|org|io|co|me|app|dev|sa|ae|jo|eg|ps|qa|kw|bh|om|tr|uk|de'
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

  /// A run of digits with optional separators. Deliberately loose, because
  /// [_buildPhone] is where the real filtering happens.
  static final RegExp _phonePattern = RegExp(
    r'\+?[0-9][0-9\s\-().]{5,20}[0-9]',
  );

  static final RegExp _standaloneNumber = RegExp(r'\b[0-9]{4,8}\b');

  /// Rejects date-shaped runs that the loose phone pattern would otherwise
  /// swallow — "12/05/2024" and "12-05-2024" are eight digits with
  /// separators, exactly like a phone number.
  static final RegExp _datePattern = RegExp(
    r'^\s*[0-9]{1,4}\s*[-/.]\s*[0-9]{1,2}\s*[-/.]\s*[0-9]{2,4}\s*$',
  );

  /// Words that turn a bare number into a verification code. Without one of
  /// these nearby, four to eight digits is just a number.
  static const List<String> _codeCues = [
    'code',
    'otp',
    'pin',
    'verification',
    'verify',
    'password',
    'passcode',
    'رمز',
    'كود',
    'التحقق',
    'تحقق',
    'السري',
  ];

  /// How far either side of a number the cue may sit.
  static const int _cueWindow = 40;

  // -------------------------------------------------------------------
  // Builders — each returns null to reject a shaped-but-invalid match
  // -------------------------------------------------------------------

  static DetectedAction? _buildEmail(String match) {
    return DetectedAction(
      kind: DetectedActionKind.email,
      value: match.toLowerCase(),
      display: match,
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

  static DetectedAction? _buildPhone(String match) {
    if (_datePattern.hasMatch(match)) return null;

    final String digits = match.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7 || digits.length > 15) return null;

    // A number wrapped in brackets that never close, or littered with more
    // punctuation than digits, is layout noise rather than a phone number.
    final int separators = match.length - digits.length;
    if (separators > digits.length) return null;

    final String trimmed = match.trim();
    final String value = trimmed.startsWith('+') ? '+$digits' : digits;

    return DetectedAction(
      kind: DetectedActionKind.phone,
      value: value,
      display: trimmed,
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
  static void _collectCodes(
    String text,
    List<_Span> claimed,
    List<DetectedAction> found,
  ) {
    final String haystack = text.toLowerCase();

    for (final RegExpMatch match in _standaloneNumber.allMatches(text)) {
      if (_overlaps(claimed, match.start, match.end)) continue;

      final int from = (match.start - _cueWindow).clamp(0, haystack.length);
      final int to = (match.end + _cueWindow).clamp(0, haystack.length);
      final String context = haystack.substring(from, to);

      if (!_codeCues.any(context.contains)) continue;

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
