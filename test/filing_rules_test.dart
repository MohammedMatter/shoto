import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/filing_rules.dart';
import 'package:shoto/core/utils/sensitive_data.dart';

/// A rule engine that files things for you has to be predictable above all
/// else — the previous attempt at automatic filing was deleted for being
/// unexplainable, not for being inaccurate. So the cases that matter most
/// here are the ones where a rule must *not* fire.
void main() {
  FilingRule rule(
    List<RuleCondition> conditions, {
    RuleMatch match = RuleMatch.all,
    bool isEnabled = true,
  }) {
    return FilingRule(
      id: 1,
      name: 'Test',
      folderId: 7,
      conditions: conditions,
      match: match,
      isEnabled: isEnabled,
    );
  }

  group('text conditions', () {
    test('matches a word printed in the screenshot', () {
      final ScreenshotFacts facts = ScreenshotFacts.from(
        text: 'Invoice #4410 — total 90.00',
      );
      expect(
        FilingRules.matches(
          rule([
            const RuleCondition(
              type: ConditionType.textContains,
              value: 'invoice',
            ),
          ]),
          facts,
        ),
        isTrue,
      );
    });

    test('Arabic spelling differences do not break a rule', () {
      // A rule written with ta marbuta must still fire on OCR that read it
      // as ha, and the other way round.
      final ScreenshotFacts written = ScreenshotFacts.from(
        text: 'فاتورة الكهرباء',
      );
      final ScreenshotFacts read = ScreenshotFacts.from(
        text: 'فاتوره الكهرباء',
      );

      for (final String needle in ['فاتورة', 'فاتوره']) {
        final FilingRule r = rule([
          RuleCondition(type: ConditionType.textContains, value: needle),
        ]);
        expect(FilingRules.matches(r, written), isTrue, reason: needle);
        expect(FilingRules.matches(r, read), isTrue, reason: needle);
      }
    });

    test('a word inside a longer word is not that word', () {
      // The defect this engine shipped with: a plain substring test filed a
      // screenshot of a barcode into the folder for verification codes, and
      // the card explaining the rule said "says code", which was true of the
      // rule and not of the picture. See [WordMatch] for the full case.
      final FilingRule codes = rule([
        const RuleCondition(type: ConditionType.textContains, value: 'code'),
      ]);
      expect(
        FilingRules.matches(codes, ScreenshotFacts.from(text: 'Scan barcode')),
        isFalse,
      );
      expect(
        FilingRules.matches(
          codes,
          ScreenshotFacts.from(text: 'Your code is 4410'),
        ),
        isTrue,
      );
    });

    test('the Arabic article does not stop a rule firing', () {
      // Arabic attaches it, so "الفاتورة" *is* the word the rule asked for.
      expect(
        FilingRules.matches(
          rule([
            const RuleCondition(
              type: ConditionType.textContains,
              value: 'فاتورة',
            ),
          ]),
          ScreenshotFacts.from(text: 'وصلت والفاتورة مرفقة'),
        ),
        isTrue,
      );
    });

    test('an empty needle never matches', () {
      // Otherwise a half-typed rule silently swallows the library.
      expect(
        FilingRules.matches(
          rule([
            const RuleCondition(type: ConditionType.textContains, value: '  '),
          ]),
          ScreenshotFacts.from(text: 'anything'),
        ),
        isFalse,
      );
    });

    test('"has any text" separates documents from photos', () {
      const RuleCondition hasText = RuleCondition(
        type: ConditionType.hasAnyText,
      );
      expect(
        FilingRules.matches(rule([hasText]), ScreenshotFacts.from(text: 'hi')),
        isTrue,
      );
      expect(
        FilingRules.matches(rule([hasText]), const ScreenshotFacts()),
        isFalse,
      );
      expect(
        FilingRules.matches(rule([hasText]), ScreenshotFacts.from(text: '   ')),
        isFalse,
      );
    });
  });

  group('subject conditions', () {
    test('a rule about animals fires on a picture of a cat', () {
      final ScreenshotFacts facts = ScreenshotFacts.from(labels: ['Cat']);
      for (final String subject in ['حيوان', 'animal', 'قطة']) {
        expect(
          FilingRules.matches(
            rule([
              RuleCondition(type: ConditionType.showsSubject, value: subject),
            ]),
            facts,
          ),
          isTrue,
          reason: subject,
        );
      }
    });

    test('a word that merely starts with a label is not that label', () {
      // Search matches by prefix in both directions so half-typed words find
      // things, which also makes "category" start with "cat". Harmless in a
      // result list; not harmless when it moves a photo into Pets.
      for (final String subject in ['category', 'catalogue', 'dogma']) {
        expect(
          FilingRules.matches(
            rule([
              RuleCondition(type: ConditionType.showsSubject, value: subject),
            ]),
            ScreenshotFacts.from(labels: ['Cat', 'Dog']),
          ),
          isFalse,
          reason: subject,
        );
      }
    });

    test('but an English plural of the label still is', () {
      expect(
        FilingRules.matches(
          rule([
            const RuleCondition(
              type: ConditionType.showsSubject,
              value: 'cats',
            ),
          ]),
          ScreenshotFacts.from(labels: ['Cat']),
        ),
        isTrue,
      );
    });

    test('and not on a picture of a pizza', () {
      expect(
        FilingRules.matches(
          rule([
            const RuleCondition(
              type: ConditionType.showsSubject,
              value: 'حيوان',
            ),
          ]),
          ScreenshotFacts.from(labels: ['Pizza']),
        ),
        isFalse,
      );
    });
  });

  group('sensitive-data conditions', () {
    test('fires on a real card number', () {
      // Passes Luhn; the detector rejects shapes that do not.
      final ScreenshotFacts facts = ScreenshotFacts.from(
        text: 'Card 4111 1111 1111 1111',
      );
      expect(facts.sensitiveKinds, contains(SensitiveKind.card));
      expect(
        FilingRules.matches(
          rule([
            RuleCondition(
              type: ConditionType.containsSensitive,
              value: SensitiveKind.card.name,
            ),
          ]),
          facts,
        ),
        isTrue,
      );
    });

    test('an unknown kind never matches instead of throwing', () {
      expect(
        FilingRules.matches(
          rule([
            const RuleCondition(
              type: ConditionType.containsSensitive,
              value: 'passport',
            ),
          ]),
          ScreenshotFacts.from(text: 'Card 4111 1111 1111 1111'),
        ),
        isFalse,
      );
    });
  });

  group('combining conditions', () {
    final ScreenshotFacts receipt = ScreenshotFacts.from(
      text: 'Invoice from Careem — total 40.00',
    );

    test('all: every condition must hold', () {
      expect(
        FilingRules.matches(
          rule([
            const RuleCondition(
              type: ConditionType.textContains,
              value: 'invoice',
            ),
            const RuleCondition(
              type: ConditionType.textContains,
              value: 'careem',
            ),
          ]),
          receipt,
        ),
        isTrue,
      );
      expect(
        FilingRules.matches(
          rule([
            const RuleCondition(
              type: ConditionType.textContains,
              value: 'invoice',
            ),
            const RuleCondition(
              type: ConditionType.textContains,
              value: 'uber',
            ),
          ]),
          receipt,
        ),
        isFalse,
      );
    });

    test('any: one is enough', () {
      expect(
        FilingRules.matches(
          rule([
            const RuleCondition(
              type: ConditionType.textContains,
              value: 'uber',
            ),
            const RuleCondition(
              type: ConditionType.textContains,
              value: 'careem',
            ),
          ], match: RuleMatch.any),
          receipt,
        ),
        isTrue,
      );
    });

    test('negation says what you actually mean', () {
      // "receipts, but not the work ones" is not expressible without it.
      final FilingRule personal = rule([
        const RuleCondition(type: ConditionType.textContains, value: 'invoice'),
        const RuleCondition(
          type: ConditionType.textContains,
          value: 'careem',
          isNegated: true,
        ),
      ]);
      expect(FilingRules.matches(personal, receipt), isFalse);
      expect(
        FilingRules.matches(
          personal,
          ScreenshotFacts.from(text: 'Invoice from the pharmacy'),
        ),
        isTrue,
      );
    });
  });

  group('refusing to act', () {
    test('a rule with no conditions matches nothing', () {
      // Matching everything would mean a rule swallows the whole library the
      // instant it is created, before a single condition is added.
      expect(
        FilingRules.matches(rule([]), ScreenshotFacts.from(text: 'anything')),
        isFalse,
      );
    });

    test('a disabled rule never files anything', () {
      final FilingRule off = rule([
        const RuleCondition(type: ConditionType.hasAnyText),
      ], isEnabled: false);

      expect(
        FilingRules.winner([off], ScreenshotFacts.from(text: 'hi')),
        isNull,
      );
      // ...though asking directly still answers honestly, so the builder can
      // preview what a disabled rule would do.
      expect(
        FilingRules.matches(off, ScreenshotFacts.from(text: 'hi')),
        isTrue,
      );
    });

    test('a screenshot with nothing known about it matches nothing', () {
      final List<FilingRule> rules = [
        rule([
          const RuleCondition(
            type: ConditionType.textContains,
            value: 'invoice',
          ),
        ]),
        rule([
          const RuleCondition(type: ConditionType.showsSubject, value: 'حيوان'),
        ]),
        rule([
          RuleCondition(
            type: ConditionType.containsSensitive,
            value: SensitiveKind.card.name,
          ),
        ]),
      ];
      expect(FilingRules.winner(rules, const ScreenshotFacts()), isNull);
    });
  });

  group('two rules wanting the same screenshot', () {
    FilingRule named(int id, String word, int folderId, {bool on = true}) {
      return FilingRule(
        id: id,
        name: 'Rule $id',
        folderId: folderId,
        isEnabled: on,
        conditions: [
          RuleCondition(type: ConditionType.textContains, value: word),
        ],
      );
    }

    final ScreenshotFacts receipt = ScreenshotFacts.from(
      text: 'Invoice from Careem — total 40.00',
    );

    test('the higher-priority one files it', () {
      // A screenshot lives in one folder, so the tie has to break somewhere.
      // It breaks on the order the rules screen shows and the arrows change,
      // which is the only version of the answer the user can check.
      expect(
        FilingRules.winner([
          named(1, 'invoice', 10),
          named(2, 'careem', 20),
        ], receipt)?.folderId,
        10,
      );
      expect(
        FilingRules.winner([
          named(2, 'careem', 20),
          named(1, 'invoice', 10),
        ], receipt)?.folderId,
        20,
      );
    });

    test('a disabled rule does not win, it is skipped entirely', () {
      // Otherwise switching a rule off would silently hand its screenshots to
      // nobody rather than to the rule below it.
      expect(
        FilingRules.winner([
          named(1, 'invoice', 10, on: false),
          named(2, 'careem', 20),
        ], receipt)?.folderId,
        20,
      );
    });

    test('nothing matching is null rather than the first rule', () {
      expect(FilingRules.winner([named(1, 'uber', 10)], receipt), isNull);
    });
  });
}
