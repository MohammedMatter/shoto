import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/text_folding.dart';

/// [foldForMatching] is what the folder grid searches and sorts on, so an
/// error in the table is a folder somebody cannot find by its own name.
void main() {
  group('case', () {
    test('is folded, which is the half that always worked', () {
      expect(foldForMatching('Recipes'), 'recipes');
      expect(foldForMatching('RECIPES'), foldForMatching('recipes'));
    });

    test('leaves plain text alone otherwise', () {
      // Spaces, digits and punctuation are part of a folder's name and are
      // not the fold's business — "Bank statements 2026" must not become
      // "bankstatements2026", or a search for "statements 2026" misses it.
      expect(foldForMatching('Bank statements 2026'), 'bank statements 2026');
      expect(foldForMatching("Mum's recipes"), "mum's recipes");
    });
  });

  group('the accents the shipped languages use', () {
    test('French', () {
      expect(foldForMatching('École'), 'ecole');
      expect(foldForMatching('Château'), 'chateau');
      expect(foldForMatching('Reçu'), 'recu');
      expect(foldForMatching('œuf'), 'oeuf');
    });

    test('German', () {
      expect(foldForMatching('Grüße'), 'grusse');
      expect(foldForMatching('Bücher'), 'bucher');
      // The eszett folds to "ss", which is how German itself spells it when
      // the letter is unavailable.
      expect(foldForMatching('Straße'), foldForMatching('Strasse'));
    });

    test('Spanish and Portuguese', () {
      expect(foldForMatching('Año'), 'ano');
      expect(foldForMatching('Bebé'), 'bebe');
      expect(foldForMatching('Coração'), 'coracao');
      expect(foldForMatching('Avô'), 'avo');
    });

    test('Italian and Dutch', () {
      expect(foldForMatching('Città'), 'citta'); // "città"
      expect(foldForMatching('Perché'), 'perche');
      expect(foldForMatching('Coördinatie'), 'coordinatie');
    });
  });

  group('names the user types that the interface never does', () {
    test('the Nordic and Eastern European letters fold too', () {
      // The interface is in one of seven languages; the folder names are the
      // user's own words and are not.
      expect(foldForMatching('Smørrebrød'), 'smorrebrod');
      expect(foldForMatching('Łódź'), 'lodz');
      expect(foldForMatching('Čeština'), 'cestina');
      expect(foldForMatching('İstanbul'), contains('stanbul'));
    });

    test('a script with no fold of its own passes through untouched', () {
      // Nothing in the table touches these, and nothing should — folding is
      // about Latin accents, and a language written in another script must
      // come out of here exactly as it went in.
      expect(foldForMatching('ملاحظات'), 'ملاحظات');
      expect(foldForMatching('レシピ'), 'レシピ');
      expect(foldForMatching('✈️ Trips'), '✈️ trips');
    });
  });

  test('a decomposed accent folds the same as a composed one', () {
    // "é" arrives either as one code point or as "e" plus a combining acute,
    // depending on the keyboard and on where the text was pasted from. Both
    // are the same word to the person who typed them.
    // Spelled with escapes rather than with the characters themselves: the
    // difference between these two is invisible in an editor, and a source
    // file that gets normalised on its way through one would quietly turn
    // this test into a comparison of a string with itself.
    const String composed = 'Café';
    const String decomposed = 'Café';
    expect(composed == decomposed, isFalse, reason: 'the premise of this test');
    expect(foldForMatching(composed), 'cafe');
    expect(foldForMatching(decomposed), 'cafe');
  });

  test('an empty string folds to an empty string', () {
    // The search field's "nothing typed yet" path depends on this.
    expect(foldForMatching(''), '');
    expect(foldForMatching('   '), '   ');
  });

  test('folding is idempotent', () {
    // Folded text is stored in a comparison key and compared against another
    // folded string; a second pass must not change it again.
    for (final String name in <String>['École', 'Straße', 'Łódź', 'Recipes']) {
      final String once = foldForMatching(name);
      expect(foldForMatching(once), once, reason: name);
    }
  });
}
