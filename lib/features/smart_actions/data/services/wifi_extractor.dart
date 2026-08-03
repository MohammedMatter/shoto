import 'package:shoto/features/smart_actions/data/services/extraction.dart';
import 'package:shoto/features/smart_actions/domain/entities/action_details.dart';
import 'package:shoto/features/smart_actions/domain/entities/detected_action.dart';

/// Finds the network name and password on a screenshot of a Wi-Fi card.
///
/// This one is almost entirely about *not* firing. "Password: hunter2" is on
/// half the screenshots anybody takes, and offering to copy an email login as
/// though it were a network key is worse than offering nothing — it teaches
/// the user the feature guesses.
///
/// So two conditions have to hold together, and either one alone is not
/// enough:
///
/// 1. Something on the screen says Wi-Fi. Not "password", not "network
///    error" — one of the words in [_wifiCue], which name wireless access and
///    nothing else.
/// 2. The password label is followed by a real separator — a colon, an equals
///    sign. This is the expensive rule, because a printed café card sometimes
///    lays the value out in a second column with no punctuation at all and
///    those are given up. It buys the certainty that the next token really is
///    the value and not the next word of a sentence ("password required to
///    join"), and that trade is the right way round when the alternative is
///    handing somebody the word "required" to type into their router.
abstract class WifiExtractor {
  WifiExtractor._();

  static List<Extraction> findIn(String text) {
    if (text.length < 8) return const [];

    // The QR spelling proves itself and needs no cue — nothing but a Wi-Fi
    // join code is written `WIFI:S:...;P:...;;`.
    final Extraction? encoded = _fromQrPayload(text);
    if (encoded != null) return <Extraction>[encoded];

    if (!_wifiCue.hasMatch(text)) return const [];

    final RegExpMatch? password = _passwordLabel.firstMatch(text);
    if (password == null) return const [];

    final String secret = _clean(password.group(1)!);
    if (!_isPlausibleKey(secret)) return const [];

    final String? network = _networkNear(text);
    // A card that reads "Network: guest / Password: guest" has been misread —
    // the same token cannot be both.
    final String? ssid = network == secret ? null : network;

    return <Extraction>[
      Extraction(
        _action(network: ssid, password: secret),
        password.end - password.group(1)!.length,
        password.end,
      ),
    ];
  }

  static DetectedAction _action({
    required String? network,
    required String password,
  }) {
    return DetectedAction(
      kind: DetectedActionKind.wifi,
      // The password is the identity: two cards for the same network with
      // different keys are two different things to copy.
      value: password,
      display: password,
      details: WifiDetails(network: network, password: password),
    );
  }

  // -------------------------------------------------------------------
  // The QR spelling
  // -------------------------------------------------------------------

  /// `WIFI:S:MyCafe;T:WPA;P:latte123;;` — the payload every Wi-Fi QR code
  /// carries. It turns up in OCR whenever a card prints the string underneath
  /// the code, which plenty of them do.
  ///
  /// The fields are order-independent in the spec, so they are read
  /// separately rather than as one shaped pattern.
  static final RegExp _qrPayload = RegExp(
    r'WIFI:[^\n]{0,200}?;;',
    caseSensitive: false,
  );

  static final RegExp _qrSsid = RegExp(r'S:((?:\\.|[^;\\])*)', caseSensitive: true);
  static final RegExp _qrPassword = RegExp(
    r'P:((?:\\.|[^;\\])*)',
    caseSensitive: true,
  );

  static Extraction? _fromQrPayload(String text) {
    final RegExpMatch? payload = _qrPayload.firstMatch(text);
    if (payload == null) return null;

    final String body = payload.group(0)!;
    final String? secret = _qrPassword.firstMatch(body)?.group(1);
    if (secret == null) return null;

    final String password = _unescapeQr(secret);
    if (password.isEmpty) return null;

    final String? ssid = _qrSsid.firstMatch(body)?.group(1);
    return Extraction(
      _action(
        network: ssid == null || ssid.isEmpty ? null : _unescapeQr(ssid),
        password: password,
      ),
      payload.start,
      payload.end,
    );
  }

  /// The payload escapes `\ ; , : "` with a backslash, so a password
  /// containing a semicolon survives the format.
  static String _unescapeQr(String raw) =>
      raw.replaceAllMapped(RegExp(r'\\(.)'), (Match m) => m.group(1)!);

  // -------------------------------------------------------------------
  // The written spelling
  // -------------------------------------------------------------------

  /// Words that name wireless access and nothing else. "Network" alone is
  /// missing on purpose — "network error" is on every failed request.
  static final RegExp _wifiCue = RegExp(
    r'wi[\s\-]?fi|wireless|hotspot|ssid|network[\s\-]?name|'
    r'واي[\s\-]?فاي|الواي[\s\-]?فاي|شبكة لاسلكية|اسم الشبكة|هوت سبوت',
    caseSensitive: false,
  );

  static const String _gap = '[ \t ]*';

  /// A password label, its separator, and the token after it.
  ///
  /// The value is a run of non-space characters, which is what a key looks
  /// like when it is printed. A key containing a space cannot be recovered
  /// from OCR anyway — there is nothing in the text that says where it ends.
  static final RegExp _passwordLabel = RegExp(
    '(?:wi[\\s\\-]?fi$_gap)?'
    '(?:password|passcode|pass|pwd|key|'
    'كلمة السر|كلمة المرور|كلمه السر|رمز الشبكة|الباسورد|باسورد|الرمز|'
    'mot de passe|contraseña|clave)'
    '$_gap[:：=]$_gap'
    r'(\S{6,63})',
    caseSensitive: false,
  );

  /// The network's own name, which is nice to have and never required — a
  /// café card that only prints the key is still worth a Copy button.
  static final RegExp _networkLabel = RegExp(
    '(?:wi[\\s\\-]?fi$_gap(?:name)?|ssid|network${_gap}name|network|'
    'اسم الشبكة|الشبكة|شبكة|واي فاي|الواي فاي)'
    '$_gap[:：=]$_gap'
    r'([^\n]{1,32})',
    caseSensitive: false,
  );

  static String? _networkNear(String text) {
    final RegExpMatch? m = _networkLabel.firstMatch(text);
    if (m == null) return null;
    final String name = _clean(m.group(1)!);
    return name.isEmpty ? null : name;
  }

  /// Strips the punctuation a printed card wraps its values in, and the
  /// straight and curly quotes OCR adds around anything in a box.
  static final RegExp _edgeNoise = RegExp(
    '^[\\s"\'“”‘’«»]+|[\\s"\'“”‘’«».,،;:]+\$',
  );

  static String _clean(String raw) => raw.replaceAll(_edgeNoise, '');

  /// Words that sit after "password:" on a screen that is not handing one out.
  static const Set<String> _notAKey = <String>{
    'required', 'incorrect', 'invalid', 'changed', 'updated', 'forgotten',
    'protected', 'hidden', 'saved', 'settings', 'manager', 'مطلوبة', 'خاطئة',
    'محفوظة', 'مطلوب',
  };

  /// A key is at least six characters, is not one of the words above, and is
  /// not a sentence that lost its spaces to a strict `\S` capture.
  static bool _isPlausibleKey(String value) {
    if (value.length < 6 || value.length > 63) return false;
    if (_notAKey.contains(value.toLowerCase())) return false;
    // Anything with a run of punctuation in the middle is layout, not a key.
    return !RegExp(r'[,;|]{1}').hasMatch(value);
  }
}
