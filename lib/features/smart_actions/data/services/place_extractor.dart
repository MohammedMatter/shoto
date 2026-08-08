import 'package:shoto/features/smart_actions/data/services/extraction.dart';
import 'package:shoto/features/smart_actions/domain/entities/action_details.dart';
import 'package:shoto/features/smart_actions/domain/entities/detected_action.dart';

/// Finds somewhere on a map.
///
/// The patterns are close cousins of the ones in `SensitiveData`, and it is
/// worth being explicit about why the same text is treated so differently in
/// the two places. Safe-share is looking at a screenshot the user is about to
/// *send*, so an address there is a leak to be covered. Smart actions is
/// looking at a screenshot the user is standing in front of, so an address
/// here is a place they are trying to get to. Same characters, opposite jobs;
/// neither file should be made to serve the other.
///
/// The order below is strictly by how sure the match is. A coordinate pair is
/// exact and drops a pin on the spot. A labelled address is what the
/// screenshot said it was. An unlabelled street line is a shape, and it comes
/// last because a shape is the only one of the three that can be wrong.
abstract class PlaceExtractor {
  PlaceExtractor._();

  /// Two destinations off one screenshot is a delivery confirmation with a
  /// pickup and a drop-off. More than three is a list of branches, and a list
  /// is not an action.
  static const int _maxPlaces = 3;

  static List<Extraction> findIn(String text) {
    if (text.length < 8) return const [];

    final List<Extraction> found = <Extraction>[];
    _claimCoordinates(text, found);
    _claimLabelled(text, _strongLabel, found);
    _claimLabelled(text, _weakLabel, found);
    _claimStreets(text, found);

    found.sort((Extraction a, Extraction b) => a.start.compareTo(b.start));
    return found.length <= _maxPlaces ? found : found.sublist(0, _maxPlaces);
  }

  // -------------------------------------------------------------------
  // Coordinates
  // -------------------------------------------------------------------

  /// `24.7743, 46.7386`. Four decimal places is the gate: fewer than that and
  /// the pair is a pair of prices, a version range, or a score.
  static final RegExp _coordinates = RegExp(
    r'(-?[0-9]{1,3}\.[0-9]{4,})[ \t ]*,[ \t ]*(-?[0-9]{1,3}\.[0-9]{4,})',
  );

  static void _claimCoordinates(String text, List<Extraction> found) {
    for (final RegExpMatch m in _coordinates.allMatches(text)) {
      final double? lat = double.tryParse(m.group(1)!);
      final double? lng = double.tryParse(m.group(2)!);
      if (lat == null || lng == null) continue;
      // Off the planet. Two long decimals in a row is also what a pair of
      // sensor readings looks like.
      if (lat.abs() > 90 || lng.abs() > 180) continue;

      final String query = '$lat,$lng';
      _add(
        found,
        m.start,
        m.end,
        query: query,
        display: m.group(0)!,
        isCoordinates: true,
      );
    }
  }

  // -------------------------------------------------------------------
  // Labelled addresses
  // -------------------------------------------------------------------

  static const String _gap = '[ \t ]*';
  static const String _colon = '[:：∶]';

  /// Labels that mean an address on their own — every one of them names the
  /// address in the label itself, so there is nothing left to be ambiguous
  /// about.
  static final RegExp _strongLabel = RegExp(
    '(?:shipping${_gap}address|billing${_gap}address|delivery${_gap}address|'
    'home${_gap}address|deliver${_gap}to|ship${_gap}to|pick${_gap}up${_gap}at|'
    // German
    'lieferadresse|rechnungsadresse|versandadresse|anschrift|abholung${_gap}bei|'
    // Dutch
    'bezorgadres|afleveradres|factuuradres|verzendadres|afhalen${_gap}bij|'
    // Italian
    'indirizzo${_gap}di$_gap(?:spedizione|consegna|fatturazione)|'
    'ritiro${_gap}presso|'
    // Portuguese
    'morada${_gap}de${_gap}entrega|endere(?:ç|c)o${_gap}de${_gap}entrega|'
    // Spanish / French
    'adresse de livraison|dirección de envío|'
    'direcci(?:ó|o)n${_gap}de${_gap}entrega|'
    'adresse${_gap}de${_gap}r(?:é|e)cup(?:é|e)ration)'
    '$_gap$_colon?$_gap'
    r'([^\n]{6,90})',
    caseSensitive: false,
  );

  /// Bare "address" or "location" needs the colon. "Location services" is a
  /// settings row and "address book" is a menu; "Location: Gate 4" is a place.
  static final RegExp _weakLabel = RegExp(
    '(?<![A-Za-z])(?:address|location|venue|'
    // German / Dutch. "Adresse" is spelled with one `d` and is *not* reached
    // by the English `address`; each spelling is listed.
    'adresse|standort|veranstaltungsort|treffpunkt|'
    'adres|locatie|plaats|'
    // Italian
    'indirizzo|posizione|luogo|sede|'
    // Portuguese / Spanish — the accent-optional spellings cover both the
    // properly accented text and what OCR returns when it drops the mark.
    'endere(?:ç|c)o|morada|local|direcci(?:ó|o)n|ubicaci(?:ó|o)n|lugar|'
    // French
    'emplacement|lieu)'
    '$_gap$_colon$_gap'
    r'([^\n]{6,90})',
    caseSensitive: false,
  );

  static void _claimLabelled(
    String text,
    RegExp pattern,
    List<Extraction> found,
  ) {
    for (final RegExpMatch m in pattern.allMatches(text)) {
      final String? captured = m.group(1);
      if (captured == null) continue;
      final int start = m.end - captured.length;
      final String value = _trim(captured);
      if (value.length < 6) continue;
      // A label followed by a URL is a link, and the link extractor will make
      // a better job of it than a maps search would.
      if (_looksLikeUrl(value)) continue;
      _add(found, start, start + value.length, query: value, display: value);
    }
  }

  // -------------------------------------------------------------------
  // Unlabelled street lines
  // -------------------------------------------------------------------

  /// A house number, at least one word, then a word that only ever ends a
  /// street name. The word in between is required — without it "1 st" is a
  /// street.
  static final RegExp _streetLine = RegExp(
    r'\b[0-9]{1,5}[ ,]+(?:[A-Za-z0-9.À-ɏ\-]+[ ]+){1,4}'
    r'(?:street|st|avenue|ave|road|rd|boulevard|blvd|lane|ln|drive|dr|'
    r'court|ct|way|square|sq|highway|hwy)\b\.?',
    caseSensitive: false,
  );

  /// German and Dutch: the street type is welded onto the name and the house
  /// number follows — *Hauptstraße 12*, *Kerkstraat 5a*.
  ///
  /// **Kept character-for-character identical to `SensitiveData`'s copy.** The
  /// two files answer different questions — this one offers a map, that one
  /// offers to cover the line — but they must agree on what a street *is*, or
  /// a screenshot gets a Directions button for an address Safe Share will not
  /// hide. If either changes, change both.
  static final RegExp _streetLineSuffixed = RegExp(
    r'\b[A-Za-zÀ-ɏ][A-Za-zÀ-ɏ.\-]{1,30}'
    r'(?:stra(?:ß|ss)e|str\.|weg|platz|allee|gasse|ring|damm|ufer|'
    r'straat|laan|plein|kade|singel|dijk|gracht|hof)'
    r'[ ]+[0-9]{1,4}[ ]?[a-zA-Z]?\b',
    caseSensitive: false,
  );

  /// Italian, Portuguese, Spanish and French: the street type leads and the
  /// house number ends the line — *Via Roma 12*, *Rua Augusta 24*.
  ///
  /// The number is required. Without it *"Il corso di italiano inizia lunedì"*
  /// is an address, and so is any French sentence containing "place".
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

  static void _claimStreets(String text, List<Extraction> found) {
    for (final RegExp pattern in <RegExp>[_streetLine, _streetLineSuffixed, _streetLinePrefixed]) {
      for (final RegExpMatch m in pattern.allMatches(text)) {
        final String value = _trim(m.group(0)!);
        if (value.length < 6) continue;
        _add(
          found,
          m.start,
          m.start + value.length,
          query: value,
          display: value,
        );
      }
    }
  }

  // -------------------------------------------------------------------
  // Bookkeeping
  // -------------------------------------------------------------------

  static void _add(
    List<Extraction> found,
    int start,
    int end, {
    required String query,
    required String display,
    bool isCoordinates = false,
  }) {
    if (start >= end) return;
    for (final Extraction existing in found) {
      if (start < existing.end && existing.start < end) return;
    }
    found.add(
      Extraction(
        DetectedAction(
          kind: DetectedActionKind.place,
          // Case-folded so a street written twice on the same receipt — once
          // in a heading and once in the body — collapses to one row.
          value: query.toLowerCase(),
          display: display,
          details: PlaceDetails(query: query, isCoordinates: isCoordinates),
        ),
        start,
        end,
      ),
    );
  }

  static final RegExp _edgeNoise = RegExp(r'^[\s,،.:\-]+|[\s,،.:\-]+$');

  static String _trim(String raw) => raw.replaceAll(_edgeNoise, '');

  static final RegExp _url = RegExp(
    r'^(?:https?://|www\.)|\.(?:com|net|org|io|co)\b',
    caseSensitive: false,
  );

  static bool _looksLikeUrl(String value) => _url.hasMatch(value);
}
