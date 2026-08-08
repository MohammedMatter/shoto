import 'package:shoto/core/utils/phone_candidates.dart';
import 'package:shoto/core/utils/sensitive_data.dart';
import 'package:shoto/core/utils/text_cues.dart';
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
  /// Deliberately excludes the bare word for "number" (`no.`, `Nr.`, `nr`):
  /// it prefixes order numbers, invoice numbers and reference numbers far more
  /// often than it prefixes a phone.
  ///
  /// **Only words the recogniser can produce.** The Arabic, Hindi and Urdu
  /// cues that used to be here could never match — the bundled model reads
  /// Latin script only — and went with the languages that needed them. Same
  /// rule as [ActionExtractor]'s code cues; see
  /// `docs/decisions/shipped-languages.md`.
  static const List<String> _phoneCues = <String>[
    'phone',
    'tel',
    'mobile',
    'cell',
    'whatsapp',
    'call',
    'contact',
    // Spanish
    'teléfono',
    'telefono',
    'móvil',
    'movil',
    'llamar',
    // French
    'téléphone',
    'telephone',
    'portable',
    'appeler',
    // German
    'telefon',
    'handy',
    'mobilnummer',
    'rufnummer',
    'anrufen',
    // Italian
    'cellulare',
    'chiamare',
    'recapito',
    // Portuguese
    'telemóvel',
    'telemovel',
    'celular',
    'ligar',
    'contato',
    'contacto',
    // Dutch
    'telefoonnummer',
    'mobiel',
    'bellen',
    'gsm',
  ];

  /// How far either side of the number a cue word still counts.
  ///
  /// The cue has to be *near* the number, not merely somewhere on the same
  /// screen. Searching the whole text meant one "contact us" in a page footer
  /// vouched for every unrelated reference number above it — which is the
  /// exact over-reach this trait was tightened to remove. Same window and same
  /// reasoning as [ActionExtractor]'s verification-code rule.
  static const int _cueWindow = 40;

  /// Every trait present in [text].
  ///
  /// Returns an empty set for text that is absent or too short, which is the
  /// same answer as "read it, found nothing" on purpose: both mean this
  /// screenshot matches no trait filter. "Never read" is a different question
  /// and is answered by whether a cache entry exists at all, not by this.
  ///
  /// [now] and [dayFirst] only exist so the event trait can be tested without
  /// a clock or a device region; the app never passes them. They are handed
  /// straight to [ActionExtractor.extract], which documents the same pair for
  /// the same reason.
  ///
  /// **A test that omits them cannot be written to last.** [ContentTrait.event]
  /// is the one trait whose answer depends on the day it is asked: the rules
  /// accept a date only inside a window running from thirty days back to three
  /// years ahead, so *no* literal date stays correct forever. A case pinned to
  /// 2026 stops being an event some time in 2026, and — worse, because it fails
  /// silently in the other direction — a "far future, not an event" case
  /// written as 2032 quietly becomes one in 2029.
  static Set<ContentTrait> of(String? text, {DateTime? now, bool? dayFirst}) {
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

    // **Normalised, then lowercased — and the normalisation is not optional.**
    //
    // [PhoneCandidates] runs over the text *after* Arabic-Indic and Persian
    // digits are rewritten as ASCII, so looking a candidate up in the raw
    // string finds nothing whenever the screenshot was taken on an Arabic or
    // Urdu UI: `٠٥٩٩١٢٣٤٥٦` and `0599123456` share no characters. Every such
    // number was silently failing the cue test and being dropped — a
    // whole-language blind spot that looked like the rule simply being strict.
    //
    // Safe because that rewrite is character-for-character, so an offset into
    // the normalised string is an offset into the original.
    final String normalised = ActionExtractor.normalizeDigits(text);
    final String lowered = normalised.toLowerCase();

    // **A phone number has to earn this chip, and it can never earn a
    // button.** The candidates come from [PhoneCandidates] rather than from
    // the actions sheet, which no longer detects phone numbers at all — a bare
    // digit run is indistinguishable from an account number, and the sheet was
    // offering to dial IBANs. What makes the chip safe is the evidence
    // demanded here: a country code, or a word nearby saying what the number
    // is. Without either, this stays silent, because a filter is believed
    // rather than re-checked against the picture.
    for (final String candidate in PhoneCandidates.findIn(normalised)) {
      if (PhoneCandidates.isInternational(candidate)) {
        traits.add(ContentTrait.contact);
        break;
      }
      final int at = lowered.indexOf(candidate.toLowerCase());
      if (at < 0) continue;
      if (TextCues.anyNear(
        lowered,
        at,
        at + candidate.length,
        _cueWindow,
        _phoneCues,
      )) {
        traits.add(ContentTrait.contact);
        break;
      }
    }

    for (final DetectedAction action in ActionExtractor.extract(
      text,
      now: now,
      dayFirst: dayFirst,
    )) {
      switch (action.kind) {
        case DetectedActionKind.link:
          traits.add(ContentTrait.link);

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
