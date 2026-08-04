import 'package:shoto/core/utils/sensitive_data.dart';
import 'package:shoto/features/smart_actions/data/services/action_extractor.dart';
import 'package:shoto/features/smart_actions/domain/entities/detected_action.dart';

/// How sure the app is that a screenshot really has the trait, and — more to
/// the point — **why**.
///
/// This exists because the two answers are not the same kind of claim and must
/// not be presented as one. A card number that passes Luhn is arithmetic; a
/// link found in OCR text is a reading of a picture, and a reading can miss.
/// Showing both as a plain chip would let the weaker one borrow the stronger
/// one's authority, which is exactly how the deleted Smart Albums feature lost
/// the user's trust: a guess that never admitted it was guessing.
enum TraitCertainty {
  /// A checksum proved it. Luhn for card numbers, mod-97 for IBANs.
  verified,

  /// Recognised in the text OCR recovered from the picture.
  ///
  /// The pattern itself is exact — this is not a probability. What is
  /// uncertain is the *input*: OCR can fail to read a line, and a trait
  /// nobody read is a trait nobody can filter by. So this bucket
  /// under-reports and never over-reports.
  read,
}

/// A property of a screenshot's *contents*, as opposed to its filing status.
///
/// Deliberately a separate axis from `LibraryFilter`. Status answers "have I
/// dealt with this yet"; a trait answers "what is in it". They are orthogonal
/// — an unsorted screenshot with a link in it is a perfectly coherent thing to
/// ask for, unlike `unsorted && favorites`, which is a contradiction the
/// status enum exists to make unrepresentable.
enum ContentTrait {
  /// A bank card or IBAN, proved by checksum. Ordered first: it is the only
  /// trait somebody might go looking for because it is *dangerous*.
  sensitive,

  link,

  /// A phone number or an email address — one axis, because "how do I reach
  /// this" is one question and splitting it would put two thin chips where
  /// one useful one belongs.
  contact,

  /// A verification code. Requires a cue word nearby, so this is not merely
  /// "four digits" — see [ActionExtractor].
  code,

  /// A date or time the user is expected to show up for.
  event;

  TraitCertainty get certainty => this == ContentTrait.sensitive
      ? TraitCertainty.verified
      : TraitCertainty.read;
}

/// Derives [ContentTrait]s from text a screenshot was already read for.
///
/// **Reads nothing and recognises nothing itself.** Every trait comes from
/// text some other feature already paid to extract and cache — search, the
/// smart actions sheet, the rules engine. That is the entire reason this can
/// be a filter over the whole library rather than a scan the user waits on.
///
/// The corollary is the honest limitation: a screenshot whose text was never
/// cached has no traits *yet*, not "no traits". Callers must tell those two
/// apart — see the unread count the library header shows.
abstract class ContentTraits {
  ContentTraits._();

  /// Text shorter than this cannot carry any trait worth filtering by, and
  /// running two full extractors over every such string across a whole library
  /// is measurably slower than skipping it.
  static const int _minimumUsefulLength = 4;

  /// Words that make a bare run of digits credible as somebody's number.
  ///
  /// Not an exhaustive vocabulary and does not need to be: a number carrying
  /// its `+` is already accepted without one of these, and the failure mode
  /// here is a screenshot going uncounted rather than a wrong claim — which is
  /// the direction this trait is deliberately biased in.
  ///
  /// Deliberately excludes the bare word for "number" (`رقم`, `no.`): it
  /// prefixes order numbers, invoice numbers and reference numbers far more
  /// often than it prefixes a phone.
  static const List<String> _phoneCues = <String>[
    'phone',
    'tel',
    'mobile',
    'cell',
    'whatsapp',
    'call',
    'contact',
    'جوال',
    'هاتف',
    'موبايل',
    'تلفون',
    'اتصل',
    'واتساب',
    'محمول',
    'teléfono',
    'telefono',
    'móvil',
    'movil',
    'llamar',
    'téléphone',
    'telephone',
    'portable',
    'appeler',
    'फ़ोन',
    'फोन',
    'मोबाइल',
    'فون',
    'موبائل',
    'رابطہ',
  ];

  /// How far either side of the number a cue word still counts.
  ///
  /// The cue has to be *near* the number, not merely somewhere on the same
  /// screen. Searching the whole text meant one "contact us" in a page footer
  /// vouched for every unrelated reference number above it — which is the
  /// exact over-reach this trait was tightened to remove. Same window and same
  /// reasoning as [ActionExtractor]'s verification-code rule.
  static const int _cueWindow = 40;

  /// Any letter or digit, in any script.
  ///
  /// `\b` cannot do this job. Dart's word class is ASCII-only, so `\bجوال\b`
  /// sits between two non-word characters and never matches at all — the
  /// Arabic, Hindi and Urdu cues would silently stop working the moment a word
  /// boundary was demanded of them.
  static final RegExp _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

  /// Whether [cue] appears in [context] as a **whole word**.
  ///
  /// Substring matching is what let this trait be wrong on the test device: a
  /// screenshot of an IBAN reference page carried the byline "Mobilefish.com",
  /// the cue `mobile` matched inside it, and an account-number fragment
  /// alongside was certified as somebody's phone number. `tel` inside "hotel"
  /// and `call` inside "recall" are the same bug waiting elsewhere.
  static bool _hasCueWord(String context, String cue) {
    int from = 0;
    while (true) {
      final int at = context.indexOf(cue, from);
      if (at < 0) return false;

      final bool openLeft =
          at == 0 || !_letterOrDigit.hasMatch(context[at - 1]);
      final int after = at + cue.length;
      final bool openRight =
          after >= context.length || !_letterOrDigit.hasMatch(context[after]);

      if (openLeft && openRight) return true;
      from = at + 1;
    }
  }

  /// Every trait present in [text].
  ///
  /// Returns an empty set for text that is absent or too short, which is the
  /// same answer as "read it, found nothing" on purpose: both mean this
  /// screenshot matches no trait filter. "Never read" is a different question
  /// and is answered by whether a cache entry exists at all, not by this.
  static Set<ContentTrait> of(String? text) {
    if (text == null) return const <ContentTrait>{};
    if (text.trim().length < _minimumUsefulLength) {
      return const <ContentTrait>{};
    }

    final Set<ContentTrait> traits = <ContentTrait>{};

    // Only checksum-backed kinds count. `SensitiveData` deliberately
    // over-flags — a missed card number is a leak, so it takes borderline
    // cases — and that bias is right for the redaction screen, where every
    // detection is reviewed by eye before anything is shared. It is wrong
    // here: nobody reviews a filter, they just believe it. Taking only
    // `isCertain` inverts the bias for this one caller without weakening
    // Safe Share.
    for (final SensitiveMatch match in SensitiveData.findIn(text)) {
      if (match.kind.isCertain) {
        traits.add(ContentTrait.sensitive);
        break;
      }
    }

    // Lowercased once rather than per phone match; scanning two dozen cue
    // words is not free when this runs over a whole library.
    String? lowered;

    /// Whether a cue word sits within [_cueWindow] characters of this match.
    ///
    /// Located by searching for the text as it was originally displayed, which
    /// is the only handle a [DetectedAction] gives onto its own position. A
    /// number the search cannot find is treated as uncorroborated rather than
    /// as corroborated — the trait's whole bias is that a miss beats a wrong
    /// claim.
    bool cuedNear(String display) {
      lowered ??= text.toLowerCase();
      final int at = text.indexOf(display);
      if (at < 0) return false;
      final int from = (at - _cueWindow).clamp(0, lowered!.length);
      final int to = (at + display.length + _cueWindow).clamp(
        0,
        lowered!.length,
      );
      final String context = lowered!.substring(from, to);
      return _phoneCues.any((String cue) => _hasCueWord(context, cue));
    }

    for (final DetectedAction action in ActionExtractor.extract(text)) {
      switch (action.kind) {
        case DetectedActionKind.link:
          traits.add(ContentTrait.link);

        // **A phone needs a reason to be a phone here, unlike in the actions
        // sheet.** The two use the same detection at deliberately different
        // bars, because being wrong costs different things. The sheet offers a
        // pre-filled dialler you can see before you tap — a wrong number is a
        // visible dead end. This chip makes a *claim about content*: it tells
        // you a screenshot holds somebody's number, and nobody re-reads the
        // screenshot to check. So the claim has to be evidenced.
        //
        // Evidence is a country code, or a word nearby saying what the number
        // is. Without either, seven to eleven bare digits is indistinguishable
        // from an order reference, and `SensitiveData` reached this same
        // conclusion already — see its `number` kind, added precisely because
        // every unlabelled digit run had been getting called a phone.
        case DetectedActionKind.phone:
          if (action.value.startsWith('+') || cuedNear(action.display)) {
            traits.add(ContentTrait.contact);
          }

        // An email needs no such test. `@` plus a real TLD is not a shape
        // anything else shares.
        case DetectedActionKind.email:
          traits.add(ContentTrait.contact);
        case DetectedActionKind.code:
          traits.add(ContentTrait.code);
        case DetectedActionKind.event:
          traits.add(ContentTrait.event);
        // An IBAN reaching here was already counted as sensitive above, and
        // the rest describe an action to take rather than a property worth
        // filtering a library by.
        case DetectedActionKind.iban:
        case DetectedActionKind.place:
        case DetectedActionKind.wifi:
        case DetectedActionKind.tracking:
          break;
      }
    }

    return traits;
  }
}
