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

  static final RegExp _qrSsid = RegExp(
    r'S:((?:\\.|[^;\\])*)',
    caseSensitive: true,
  );
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
    // German / Dutch — "WLAN" is what German routers and cafés print, and
    // "draadloos" is the Dutch word a network card uses.
    r'wlan|drahtlos|netzwerkname|draadloos|netwerknaam|'
    // Italian / Portuguese / Spanish / French
    r'rete\s?wireless|nome\s?rete|nome\s?da\s?rede|nome\s?de\s?la\s?red|'
    r'r(?:é|e)seau\s?sans\s?fil|nom\s?du\s?r(?:é|e)seau',
    caseSensitive: false,
  );

  static const String _gap = '[ \t ]*';

  /// A password label, its separator, and the token after it.
  ///
  /// The value is a run of non-space characters, which is what a key looks
  /// like when it is printed. A key containing a space cannot be recovered
  /// from OCR anyway — there is nothing in the text that says where it ends.
  /// **Two tiers, and the split is a left word boundary.**
  ///
  /// A blanket boundary would be wrong here, because German and Dutch build
  /// the compound around the head word: *Gastpasswort*, *WLAN-Kennwort*,
  /// *Netzwerksleutel* all end in the label and all mean exactly what the
  /// label says. Matching inside a longer word is the *feature* for those.
  ///
  /// It is a bug for the short ones, which is not a theory — `pass` matched
  /// inside **By**`pass`**:** and `key` inside **Mon**`key`**:**, and each
  /// handed the user an invented network password. `Bypass:` and
  /// `Gastpasswort:` are the same shape; only specificity tells them apart,
  /// so specificity is what the tiers encode.
  ///
  /// The rule: six letters or more may sit inside a compound, five or fewer
  /// must start a word. Anything short enough to be a syllable is guarded.
  static final RegExp _passwordLabel = RegExp(
    '(?:wi[\\s\\-]?fi$_gap)?'
    '(?:'
    // Long enough to mean only one thing, so a compound may carry them.
    'password|passcode|'
    // German
    'passwort|kennwort|netzwerkschl(?:ü|u)ssel|schl(?:ü|u)ssel|zugangsdaten|'
    // Dutch
    'wachtwoord|netwerksleutel|sleutel|toegangscode|'
    // Italian
    'password$_gap di$_gap rete|chiave|'
    // Portuguese
    'palavra$_gap passe|palavra-passe|'
    // Spanish / French
    'mot de passe|contrase(?:ñ|n)a'
    // Short and generic — these must begin a word. `senha` sits in the
    // Portuguese *resenha*, `clave` in *enclave*, `cle` in *article*.
    '|(?<![A-Za-z])(?:pass|pwd|key|senha|clave|cl(?:é|e))'
    ')'
    '$_gap[:：=]$_gap'
    r'(\S{6,63})',
    caseSensitive: false,
  );

  /// The network's own name, which is nice to have and never required — a
  /// café card that only prints the key is still worth a Copy button.
  /// Same two tiers as [_passwordLabel], and this one is where the language
  /// swap actually drew blood: `red` is Spanish for network, and it also ends
  /// **Sha**`red`**:**, *Hundred:*, *Required:* and *Entered:*. A screenshot
  /// with Wi-Fi on it and the word "Shared:" anywhere was reporting whatever
  /// followed as the network's name.
  ///
  /// A wrong name here costs a wrong subtitle rather than a wrong password,
  /// which is why bare `netzwerk` and `netwerk` stay unguarded — German and
  /// Dutch compound them (*Gastnetzwerk*) and they are long enough to be safe.
  static final RegExp _networkLabel = RegExp(
    '(?:'
    'wi[\\s\\-]?fi$_gap(?:name)?|network${_gap}name|network|'
    // German / Dutch. Longest first, so the bare forms never claim a compound
    // label's opening letters.
    'wlan${_gap}name|netzwerkname|netzwerk|netwerknaam|netwerk|'
    // Italian / Portuguese / Spanish / French
    'nome${_gap}rete|nome${_gap}da${_gap}rede|'
    'nombre${_gap}de${_gap}la${_gap}red|'
    'nom${_gap}du${_gap}r(?:é|e)seau|r(?:é|e)seau'
    // Four letters or fewer: must begin a word.
    '|(?<![A-Za-z])(?:ssid|wlan|rete|rede|red)'
    ')'
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
    'required',
    'incorrect',
    'invalid',
    'changed',
    'updated',
    'forgotten',
    'protected',
    'hidden',
    'saved',
    'settings',
    'manager',
    // The same words on a screen that is refusing a password rather than
    // printing one.
    //
    // **Plain strings, compared with `==` after lower-casing** — this is a
    // `Set`, not a list of patterns, so every spelling that needs to be caught
    // is written out in full. An entry like `ge(?:ä|a)ndert` would compile,
    // ship, and never equal anything.
    'erforderlich',
    'falsch',
    'geändert',
    'geandert',
    'gespeichert',
    'vergessen',
    'vereist',
    'onjuist',
    'opgeslagen',
    'vergeten',
    'richiesta',
    'errata',
    'salvata',
    'dimenticata',
    'obrigatória',
    'obrigatoria',
    'incorrecta',
    'guardada',
    'esquecida',
    'requerida',
    'olvidada',
    'requis',
    'oublié',
    'oublie',
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
