/// Two spellings of one word, reduced to what the user means by both.
///
/// **Case was the only half of this that was ever done.** Folder search and the
/// folder grid's A–Z order both ran on `toLowerCase()`, and both of their doc
/// comments claimed more than that bought: the search called itself
/// "case- and diacritic-insensitive enough", and the sort gave locale-blind
/// collation as the whole reason it happens in Dart rather than in SQL —
/// `COLLATE NOCASE` "would put 'École' after 'Zoo' on a French phone".
/// `String.compareTo` orders by UTF-16 code unit and does exactly the same
/// thing: é is U+00E9, which is past z. Both claims were false in the same way.
///
/// So the fold is written down once, here, and used by both.
///
/// **Every language Shoto ships is Latin and six of the seven have accents** —
/// German umlauts and eszett, Spanish tildes, French everything, Italian
/// grave and acute, Portuguese nasals and cedilla, Dutch diaereses. A folder
/// called "Café" that cannot be found by typing "cafe" is not an edge case on
/// those phones; it is the ordinary way somebody types on a keyboard that
/// makes an accent cost two presses.
///
/// **A table, not a normalizer.** Dart has no Unicode NFD in its core library,
/// and a decomposition pass would be a package dependency and a great deal of
/// machinery for a folder list. The table covers Latin-1 Supplement — which is
/// all seven shipped languages — plus the Latin Extended-A letters a user's own
/// folder names are most likely to carry (Polish, Czech, Turkish, the Nordic
/// set), because the *names* are the user's own words and they are not
/// restricted to the language the interface is in.
///
/// Combining marks are dropped rather than mapped, so text that arrives
/// already decomposed — "e" followed by U+0301 rather than a single "é",
/// which is what several keyboards and a paste from macOS produce — folds to
/// the same string as the composed form.
///
/// The multi-letter expansions are the ones the languages themselves make:
/// German sorts "Straße" with "Strasse", and "œuf" is looked for as "oeuf".
String foldForMatching(String input) {
  final StringBuffer buffer = StringBuffer();

  for (final int rune in input.toLowerCase().runes) {
    // Combining diacritical marks (U+0300–U+036F).
    if (rune >= 0x0300 && rune <= 0x036F) continue;

    final String? folded = _folded[rune];
    if (folded == null) {
      buffer.writeCharCode(rune);
    } else {
      buffer.write(folded);
    }
  }

  return buffer.toString();
}

/// Lower case only, because [foldForMatching] lower-cases before it looks
/// anything up — every capital in Latin-1 and Latin Extended-A maps to the
/// lower-case letter directly above its own entry here.
const Map<int, String> _folded = <int, String>{
  // Latin-1 Supplement.
  0xE0: 'a', 0xE1: 'a', 0xE2: 'a', 0xE3: 'a', 0xE4: 'a', 0xE5: 'a',
  0xE6: 'ae',
  0xE7: 'c',
  0xE8: 'e', 0xE9: 'e', 0xEA: 'e', 0xEB: 'e',
  0xEC: 'i', 0xED: 'i', 0xEE: 'i', 0xEF: 'i',
  0xF0: 'd', 0xF1: 'n',
  0xF2: 'o', 0xF3: 'o', 0xF4: 'o', 0xF5: 'o', 0xF6: 'o', 0xF8: 'o',
  0xF9: 'u', 0xFA: 'u', 0xFB: 'u', 0xFC: 'u',
  0xFD: 'y', 0xFF: 'y',
  0xFE: 'th',
  0xDF: 'ss',

  // Latin Extended-A.
  0x101: 'a', 0x103: 'a', 0x105: 'a',
  0x107: 'c', 0x109: 'c', 0x10B: 'c', 0x10D: 'c',
  0x10F: 'd', 0x111: 'd',
  0x113: 'e', 0x115: 'e', 0x117: 'e', 0x119: 'e', 0x11B: 'e',
  0x11D: 'g', 0x11F: 'g', 0x121: 'g', 0x123: 'g',
  0x125: 'h', 0x127: 'h',
  0x129: 'i', 0x12B: 'i', 0x12D: 'i', 0x12F: 'i', 0x131: 'i',
  0x135: 'j',
  0x137: 'k',
  0x13A: 'l', 0x13C: 'l', 0x13E: 'l', 0x142: 'l',
  0x144: 'n', 0x146: 'n', 0x148: 'n',
  0x14D: 'o', 0x14F: 'o', 0x151: 'o', 0x153: 'oe',
  0x155: 'r', 0x157: 'r', 0x159: 'r',
  0x15B: 's', 0x15D: 's', 0x15F: 's', 0x161: 's',
  0x163: 't', 0x165: 't', 0x167: 't',
  0x169: 'u', 0x16B: 'u', 0x16D: 'u', 0x16F: 'u', 0x171: 'u', 0x173: 'u',
  0x175: 'w',
  0x177: 'y',
  0x17A: 'z', 0x17C: 'z', 0x17E: 'z',
};
