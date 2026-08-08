/// The structured part of a detection, for the kinds that need more than a
/// string to be acted on.
///
/// A phone number is its own instruction: `tel:` plus the digits and there is
/// nothing left to decide. An *event* is not — a calendar needs a title, a
/// start, an end and a place, and none of those can be recovered from a
/// display string once the extractor has thrown its work away.
///
/// So the intent detectors keep what they parsed. [DetectedAction.details]
/// stays null for the five original kinds, which is why nothing about them had
/// to change.
sealed class ActionDetails {
  const ActionDetails();
}

/// Something happening at a known time, which is the whole reason to offer a
/// calendar button.
///
/// [start] is a *floating* local time — the wall-clock the screenshot showed,
/// with no zone attached. That is deliberate. A screenshot of an invitation
/// says "3:00 PM" and means three in the afternoon wherever the reader is
/// standing; inventing a UTC offset for it would move the appointment by
/// however many hours the phone happens to be from the event.
class EventDetails extends ActionDetails {
  /// What the screenshot seemed to call this. Null when nothing on the screen
  /// could plausibly be a title — the UI supplies a translated placeholder
  /// rather than the data layer inventing English.
  final String? title;

  final DateTime start;

  /// Null when the screenshot gave a start and no finish. The calendar link
  /// then falls back to a one-hour block, which is what every calendar app
  /// does with a bare start time anyway.
  final DateTime? end;

  /// True when only a date was recognised, never a clock time.
  final bool allDay;

  /// A venue line, only when the screenshot labelled one.
  final String? location;

  /// The lines the event was read out of, carried into the calendar's notes
  /// field so nothing the user could see is lost on the way across.
  final String? notes;

  const EventDetails({
    required this.title,
    required this.start,
    this.end,
    this.allDay = false,
    this.location,
    this.notes,
  });
}

/// Somewhere on a map.
class PlaceDetails extends ActionDetails {
  /// What gets handed to the maps app — a street line, or `lat,lng`.
  final String query;

  /// True when [query] is a coordinate pair rather than prose.
  ///
  /// Worth knowing because coordinates are exact: the maps app will drop a pin
  /// on the spot instead of running a fuzzy search that may land in the wrong
  /// city.
  final bool isCoordinates;

  const PlaceDetails({required this.query, this.isCoordinates = false});
}

/// A network name and the password to get onto it.
class WifiDetails extends ActionDetails {
  /// Null when the screenshot showed a password under a Wi-Fi heading without
  /// ever naming the network — a café card that just says "WiFi password:".
  final String? network;

  final String password;

  const WifiDetails({required this.network, required this.password});
}

/// A parcel someone is waiting for.
class TrackingDetails extends ActionDetails {
  /// Null when the number is clearly a tracking number but nothing said whose.
  /// The UI drops the Track button in that case rather than guessing a
  /// carrier and sending the user to a site that has never heard of it.
  final ShipmentCarrier? carrier;

  final String number;

  const TrackingDetails({required this.carrier, required this.number});
}

/// The carriers SHOTO can send a tracking number to.
///
/// Brand names, so they are not translated — "Aramex" is "Aramex" in every
/// language the app speaks, and a localised spelling would only make the row
/// harder to recognise.
///
/// The list follows the shipped languages: the four global integrators, the
/// carriers that actually deliver in Germany, the Netherlands, Italy, Portugal,
/// Spain and France, the Gulf and Egyptian carriers this app was first written
/// for, and the national post as a catch-all.
///
/// **The Gulf carriers stayed when Arabic went.** A brand name is Latin on
/// every shipping notification — *Aramex*, *SMSA*, *Bosta* — so the recogniser
/// can still read them, and a user in Riyadh running the app in English is
/// still served. What went with the language were the transliterations
/// (`ارامكس`, `سمسا`) in the alias table, which no recogniser this app bundles
/// could ever produce. See `docs/decisions/shipped-languages.md`.
///
/// **The URLs are the one thing here that no test can check.** A pattern that
/// misreads a number fails a unit test; a tracking link with the wrong query
/// parameter passes every test in the suite and takes the user to a carrier's
/// "not found" page — the exact failure `TrackingExtractor` refuses to risk
/// when it declines to offer a Track button without a carrier. Each of these
/// must be confirmed against a real notification before release.
enum ShipmentCarrier {
  aramex('aramex', 'Aramex', 'https://www.aramex.com/track/results?ShipmentNumber='),
  dhl('dhl', 'DHL', 'https://www.dhl.com/en/express/tracking.html?AWB='),
  fedex('fedex', 'FedEx', 'https://www.fedex.com/fedextrack/?trknbr='),
  ups('ups', 'UPS', 'https://www.ups.com/track?tracknum='),
  usps('usps', 'USPS', 'https://tools.usps.com/go/TrackConfirmAction?tLabels='),
  dpd('dpd', 'DPD', 'https://tracking.dpd.de/status/en_US/parcel/'),
  gls('gls', 'GLS', 'https://gls-group.eu/EU/en/parcel-tracking?match='),
  hermes('hermes', 'Hermes', 'https://www.myhermes.de/empfangen/sendungsverfolgung/sendungsinformation/#'),
  postnl('postnl', 'PostNL', 'https://postnl.nl/tracktrace/?B='),
  ctt('ctt', 'CTT', 'https://www.ctt.pt/feapl_2/app/open/objectSearch/objectSearch.jspx?objects='),
  poste('poste', 'Poste Italiane', 'https://www.poste.it/cerca/index.html#/risultati-spedizioni/'),
  correos('correos', 'Correos', 'https://www.correos.es/es/es/herramientas/localizador/envios/detalle?tracking-number='),
  colissimo('colissimo', 'Colissimo', 'https://www.laposte.fr/outils/suivre-vos-envois?code='),
  smsa('smsa', 'SMSA', 'https://www.smsaexpress.com/ar/trackingdetails?tracknumbers='),
  jt('jt', 'J&T Express', 'https://www.jtexpress.sa/index/query/gzquery.html?bills='),
  bosta('bosta', 'Bosta', 'https://bosta.co/tracking-shipment/?id='),

  /// Universal postal mail — an S10 barcode (`RA123456789JO`) is unmistakably
  /// a postal item, but the code says only which country it *left*, never
  /// which postal service is currently holding it.
  ///
  /// So this one resolves to an aggregator rather than to a carrier. It is the
  /// single place in this feature that hands a value to a third party, and it
  /// is worth it: the alternative is recognising the number perfectly and then
  /// having nothing to offer the user but Copy.
  post('post', 'Post', 'https://t.17track.net/en#nums=');

  const ShipmentCarrier(this.id, this.label, this._urlPrefix);

  final String id;
  final String label;
  final String _urlPrefix;

  Uri trackingUrl(String number) =>
      Uri.parse('$_urlPrefix${Uri.encodeComponent(number)}');
}
