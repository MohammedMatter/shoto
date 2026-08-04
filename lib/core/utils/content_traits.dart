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

    for (final DetectedAction action in ActionExtractor.extract(text)) {
      switch (action.kind) {
        case DetectedActionKind.link:
          traits.add(ContentTrait.link);
        case DetectedActionKind.phone:
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
