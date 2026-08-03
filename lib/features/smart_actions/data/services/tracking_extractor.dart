import 'package:shoto/features/smart_actions/data/services/extraction.dart';
import 'package:shoto/features/smart_actions/domain/entities/action_details.dart';
import 'package:shoto/features/smart_actions/domain/entities/detected_action.dart';

/// Finds parcel tracking numbers.
///
/// Two very different kinds of evidence, and they are kept apart on purpose.
///
/// **A shape that could not be anything else.** `1Z` followed by sixteen
/// alphanumerics is a UPS number and there is no second reading of it; two
/// letters, nine digits and a country code is an S10 postal barcode and
/// nothing else uses that layout. These are claimed with no label at all,
/// because none is needed.
///
/// **A label plus a value.** Everything else — Aramex's ten digits, FedEx's
/// twelve — is a run of digits indistinguishable from an order reference or a
/// phone number, so it is only taken when the screenshot says outright what it
/// is. This is also why this extractor runs before the phone rule: a ten-digit
/// Aramex number and a ten-digit mobile number are the same characters, and
/// the one with "Tracking number:" in front of it is not a phone.
///
/// The carrier is then read from the brand name printed somewhere on the
/// screen, which shipping notifications always carry. When no brand is found
/// the number is still shown — it is worth copying — but the Track button is
/// dropped rather than sending the user to a carrier that has never heard of
/// their parcel.
abstract class TrackingExtractor {
  TrackingExtractor._();

  static const int _maxNumbers = 3;

  static List<Extraction> findIn(String text) {
    if (text.length < 8) return const [];

    final ShipmentCarrier? named = _carrierNamedIn(text);
    final List<Extraction> found = <Extraction>[];

    _claimSelfIdentifying(text, named, found);
    _claimLabelled(text, named, found);

    found.sort((Extraction a, Extraction b) => a.start.compareTo(b.start));
    return found.length <= _maxNumbers
        ? found
        : found.sublist(0, _maxNumbers);
  }

  // -------------------------------------------------------------------
  // Shapes that identify themselves
  // -------------------------------------------------------------------

  /// UPS: `1Z` then sixteen characters, the last two a check pair.
  static final RegExp _upsNumber = RegExp(
    r'(?<![A-Za-z0-9])1Z[0-9A-Z]{16}(?![A-Za-z0-9])',
  );

  /// The UPU S10 barcode every national post uses for registered mail:
  /// a two-letter service code, nine digits, and the two-letter code of the
  /// country it was posted in.
  static final RegExp _postalNumber = RegExp(
    r'(?<![A-Za-z0-9])[A-Z]{2}[0-9]{9}[A-Z]{2}(?![A-Za-z0-9])',
  );

  /// DHL eCommerce and Parcel, whose prefixes are theirs alone.
  static final RegExp _dhlNumber = RegExp(
    r'(?<![A-Za-z0-9])(?:JJD|JVGL|JD)[0-9]{10,20}(?![A-Za-z0-9])',
  );

  static void _claimSelfIdentifying(
    String text,
    ShipmentCarrier? named,
    List<Extraction> found,
  ) {
    _claimAll(text, _upsNumber, ShipmentCarrier.ups, found);
    _claimAll(text, _dhlNumber, ShipmentCarrier.dhl, found);
    // The S10 code says which country the item left, never which service is
    // carrying it now — so a brand printed on the same screen wins, and the
    // aggregator is only the fallback.
    _claimAll(text, _postalNumber, named ?? ShipmentCarrier.post, found);
  }

  static void _claimAll(
    String text,
    RegExp pattern,
    ShipmentCarrier carrier,
    List<Extraction> found,
  ) {
    for (final RegExpMatch m in pattern.allMatches(text)) {
      _add(found, m.start, m.end, m.group(0)!, carrier);
    }
  }

  // -------------------------------------------------------------------
  // Label plus value
  // -------------------------------------------------------------------

  static const String _gap = '[ \t ]*';

  static final RegExp _trackingLabel = RegExp(
    '(?<![A-Za-z])'
    '(?:tracking$_gap(?:number|no|id|code)?|track$_gap(?:number|no|id)|'
    'air$_gap?way$_gap?bill|waybill|awb|consignment$_gap(?:number|no)?|'
    'shipment$_gap(?:number|no|id)|parcel$_gap(?:number|no|id)|'
    'رقم التتبع|رقم التتبّع|رقم التتبع|رقم الشحنة|رقم الشحنه|'
    'رقم البوليصة|بوليصة الشحن|رقم الإرسالية|رقم الارسالية|'
    'numéro de suivi|número de seguimiento)'
    '$_gap(?:[:：#№.]$_gap)*'
    r'([A-Za-z0-9][A-Za-z0-9\-]{6,25})',
    caseSensitive: false,
  );

  static void _claimLabelled(
    String text,
    ShipmentCarrier? named,
    List<Extraction> found,
  ) {
    for (final RegExpMatch m in _trackingLabel.allMatches(text)) {
      final String? captured = m.group(1);
      if (captured == null) continue;

      final String number = captured.replaceAll(RegExp(r'[\-]+$'), '');
      if (number.length < 7) continue;
      // A reference with no digits in it is a word the label ran into.
      if (!RegExp('[0-9]').hasMatch(number)) continue;

      _add(
        found,
        m.end - captured.length,
        m.end - captured.length + number.length,
        number,
        named,
      );
    }
  }

  // -------------------------------------------------------------------
  // Carriers
  // -------------------------------------------------------------------

  /// Brand names as they appear on a shipping notification, in Latin and in
  /// Arabic transliteration.
  ///
  /// `ups` is the one that needs care: three letters that sit inside
  /// "backups", "groups" and "startups", so it is matched with boundaries
  /// while everything else can be found anywhere in the text.
  static const Map<ShipmentCarrier, List<String>> _aliases =
      <ShipmentCarrier, List<String>>{
        ShipmentCarrier.aramex: <String>['aramex', 'ارامكس', 'أرامكس'],
        ShipmentCarrier.dhl: <String>['dhl', 'دي اتش ال'],
        ShipmentCarrier.fedex: <String>['fedex', 'fed ex', 'فيدكس', 'فيديكس'],
        ShipmentCarrier.ups: <String>['ups', 'يو بي اس'],
        ShipmentCarrier.usps: <String>['usps', 'united states postal'],
        ShipmentCarrier.smsa: <String>['smsa', 'سمسا'],
        ShipmentCarrier.jt: <String>['j&t', 'jt express', 'جي اند تي'],
        ShipmentCarrier.bosta: <String>['bosta', 'بوسطة', 'بوسطه'],
        ShipmentCarrier.post: <String>[
          'saudi post', 'splonline', 'egypt post', 'jordan post',
          'emirates post', 'البريد السعودي', 'البريد المصري', 'بريد الاردن',
        ],
      };

  static ShipmentCarrier? _carrierNamedIn(String text) {
    final String haystack = text.toLowerCase();
    for (final MapEntry<ShipmentCarrier, List<String>> entry
        in _aliases.entries) {
      for (final String alias in entry.value) {
        if (alias.length <= 3) {
          if (RegExp(
            '(?<![A-Za-z])$alias(?![A-Za-z])',
          ).hasMatch(haystack)) {
            return entry.key;
          }
        } else if (haystack.contains(alias)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  // -------------------------------------------------------------------
  // Bookkeeping
  // -------------------------------------------------------------------

  static void _add(
    List<Extraction> found,
    int start,
    int end,
    String number,
    ShipmentCarrier? carrier,
  ) {
    if (start >= end) return;
    for (final Extraction existing in found) {
      if (start < existing.end && existing.start < end) return;
    }
    found.add(
      Extraction(
        DetectedAction(
          kind: DetectedActionKind.tracking,
          value: number.toUpperCase(),
          display: number,
          details: TrackingDetails(carrier: carrier, number: number),
        ),
        start,
        end,
      ),
    );
  }
}
