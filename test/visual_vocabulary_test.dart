import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/visual_vocabulary.dart';

/// The vocabulary is the whole difference between "the model saw a Cat" and
/// "typing قطة finds my cat", so it is tested on its own — the model itself
/// cannot run in a unit test, and does not need to.
void main() {
  group('Arabic normalization', () {
    test('folds alef, ya and ta marbuta', () {
      expect(
        VisualVocabulary.normalize('قطة'),
        VisualVocabulary.normalize('قطه'),
      );
      expect(
        VisualVocabulary.normalize('أسد'),
        VisualVocabulary.normalize('اسد'),
      );
      expect(
        VisualVocabulary.normalize('إنسان'),
        VisualVocabulary.normalize('انسان'),
      );
      expect(
        VisualVocabulary.normalize('حياة'),
        VisualVocabulary.normalize('حياه'),
      );
      expect(
        VisualVocabulary.normalize('على'),
        VisualVocabulary.normalize('علي'),
      );
    });

    test('strips harakat and tatweel', () {
      expect(
        VisualVocabulary.normalize('قِطَّة'),
        VisualVocabulary.normalize('قطة'),
      );
      expect(
        VisualVocabulary.normalize('كــلب'),
        VisualVocabulary.normalize('كلب'),
      );
    });

    test('lowercases and collapses whitespace', () {
      expect(VisualVocabulary.normalize('  Ice   Cream '), 'ice cream');
    });
  });

  group('finding a specific animal', () {
    test('the English label always works, even spelled differently', () {
      expect(VisualVocabulary.matches(['Cat'], 'cat'), isTrue);
      expect(VisualVocabulary.matches(['Cat'], 'CAT'), isTrue);
      expect(VisualVocabulary.matches(['Cat'], 'cats'), isTrue);
    });

    test('Arabic finds it', () {
      for (final String query in ['قطة', 'قطه', 'قط', 'بسة', 'هرة']) {
        expect(VisualVocabulary.matches(['Cat'], query), isTrue, reason: query);
      }
    });

    test('a partially typed word still matches', () {
      expect(VisualVocabulary.matches(['Butterfly'], 'فرا'), isTrue);
      expect(VisualVocabulary.matches(['Elephant'], 'eleph'), isTrue);
    });
  });

  group('the general question', () {
    test('"animal" finds a cat, in both languages', () {
      expect(VisualVocabulary.matches(['Cat'], 'animal'), isTrue);
      expect(VisualVocabulary.matches(['Cat'], 'حيوان'), isTrue);
      expect(VisualVocabulary.matches(['Cat'], 'حيوانات'), isTrue);
    });

    test('every group term reaches at least one of its own labels', () {
      for (final VisualGroup group in VisualVocabulary.groups) {
        for (final String term in group.terms) {
          expect(
            VisualVocabulary.matches([group.labels.first], term),
            isTrue,
            reason: '"$term" should find ${group.labels.first}',
          );
        }
      }
    });

    test('a label can answer more than one question', () {
      // A cake is food and it is also how you find a birthday.
      expect(VisualVocabulary.matches(['Cake'], 'أكل'), isTrue);
      expect(VisualVocabulary.matches(['Cake'], 'مناسبة'), isTrue);
    });
  });

  group('not matching things it should not', () {
    test('an animal query does not return food', () {
      expect(VisualVocabulary.matches(['Pizza'], 'حيوان'), isFalse);
      expect(VisualVocabulary.matches(['Pizza'], 'animal'), isFalse);
    });

    test('a mid-word fragment does not match', () {
      // Substring matching would have "at" return every cat in the library.
      expect(VisualVocabulary.matches(['Cat'], 'at'), isFalse);
      expect(VisualVocabulary.matches(['Elephant'], 'phant'), isFalse);
    });

    test('a query shorter than the minimum never matches', () {
      expect(VisualVocabulary.matches(['Cat'], 'c'), isFalse);
      expect(VisualVocabulary.matches(['Cat'], ''), isFalse);
      expect(VisualVocabulary.matches(['Cat'], '  '), isFalse);
    });

    test('a screenshot with no labels matches nothing', () {
      expect(VisualVocabulary.matches(const [], 'حيوان'), isFalse);
    });
  });

  group('labels the tables never anticipated', () {
    test('are still searchable by their own English word', () {
      // The single most important property: a gap in the tables, or a model
      // update emitting something new, must not make a picture unreachable.
      expect(VisualVocabulary.matches(['Quokka'], 'quokka'), isTrue);
      expect(VisualVocabulary.matches(['Ice hockey'], 'ice'), isTrue);
    });

    test('but do not silently join a group', () {
      expect(VisualVocabulary.matches(['Quokka'], 'حيوان'), isFalse);
    });
  });

  group('explaining the match', () {
    test('reports only the labels that caused it', () {
      final List<String> reasons = VisualVocabulary.matchingLabels([
        'Cat',
        'Sofa',
        'Dog',
      ], 'حيوان');
      expect(reasons, ['Cat', 'Dog']);
    });

    test('is empty when nothing matched', () {
      expect(VisualVocabulary.matchingLabels(['Sofa'], 'حيوان'), isEmpty);
    });
  });

  group('table hygiene', () {
    test('every synonym list is non-empty and free of blanks', () {
      VisualVocabulary.synonyms.forEach((label, terms) {
        expect(terms, isNotEmpty, reason: label);
        for (final String term in terms) {
          expect(term.trim(), isNotEmpty, reason: label);
        }
      });
    });

    test('no group is empty', () {
      for (final VisualGroup group in VisualVocabulary.groups) {
        expect(group.terms, isNotEmpty);
        expect(group.labels, isNotEmpty);
      }
    });
  });

  /// These pin down the fix for the bug that made "shows something" look like
  /// a feature that simply did not work: a rule saying "shows an animal"
  /// never fired, because a real library's labels turned out to be almost
  /// entirely `Screenshot`, `Mobile phone` and `Web page` — all true of the
  /// medium and all useless about the subject.
  group('medium labels are not subjects', () {
    test('the model describing a phone screen is filtered out', () {
      for (final String label in [
        'Screenshot',
        'Mobile phone',
        'Web page',
        'Font',
        'Product',
      ]) {
        expect(VisualVocabulary.isMeaningful(label), isFalse, reason: label);
      }
    });

    test('real subjects survive', () {
      for (final String label in ['Dog', 'Cat', 'Food', 'Flower']) {
        expect(VisualVocabulary.isMeaningful(label), isTrue, reason: label);
      }
    });

    test('a screenshot of a dog is a dog, not a screenshot', () {
      // Exactly the shape the live database was full of.
      expect(
        VisualVocabulary.meaningful(['Screenshot', 'Mobile phone', 'Dog']),
        ['Dog'],
      );
    });

    test('"shows something" can no longer match the medium', () {
      // Before the fix this held for every screenshot in the app, which made
      // the condition worthless — matching everything is matching nothing.
      expect(VisualVocabulary.matches(['Screenshot'], 'screenshot'), isFalse);
      expect(VisualVocabulary.matches(['Mobile phone'], 'phone'), isFalse);
    });
  });

  group('the reported case: a dog that would not file', () {
    test('matches "animal" in both languages', () {
      expect(VisualVocabulary.matches(['Dog'], 'animal'), isTrue);
      expect(VisualVocabulary.matches(['Dog'], 'حيوان'), isTrue);
    });

    test('still matches its own word', () {
      expect(VisualVocabulary.matches(['Dog'], 'dog'), isTrue);
      expect(VisualVocabulary.matches(['Dog'], 'كلب'), isTrue);
    });

    test('a dog inside a screenshot still matches', () {
      expect(
        VisualVocabulary.matches([
          'Screenshot',
          'Dog',
          'Mobile phone',
        ], 'animal'),
        isTrue,
      );
    });

    test('an unrelated subject does not', () {
      expect(VisualVocabulary.matches(['Dog'], 'receipt'), isFalse);
    });
  });

  /// The model rarely names a species on a cropped screenshot; it reaches for
  /// the surrounding evidence instead. These are the labels a live library
  /// actually produced, and before this they led nowhere — the proof of an
  /// animal existed and did not count as an animal.
  group('weak animal evidence still answers "animal"', () {
    test('Pet, Snout, Whiskers and Fur all reach the animal group', () {
      for (final String label in ['Pet', 'Snout', 'Whiskers', 'Fur']) {
        expect(
          VisualVocabulary.matches([label], 'animal'),
          isTrue,
          reason: label,
        );
        expect(
          VisualVocabulary.matches([label], 'حيوان'),
          isTrue,
          reason: label,
        );
      }
    });

    test('a real row from the reported library now matches', () {
      // Exactly what the database held after the crop pass started working.
      const List<String> row = ['Pet', 'Screenshot', 'Mobile phone'];
      expect(VisualVocabulary.matches(row, 'animal'), isTrue);
      expect(VisualVocabulary.matches(row, 'حيوان'), isTrue);
    });

    test('and food is still not an animal', () {
      expect(VisualVocabulary.matches(['Pizza'], 'animal'), isFalse);
    });
  });
}
