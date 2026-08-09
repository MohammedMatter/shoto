import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/sensitive_data.dart';

/// These lean the opposite way to the classifier's tests. There, a false
/// positive was the thing to avoid; here a *missed* detection is the failure
/// that matters, because it is the one that leaks somebody's card number.
void main() {
  _emailRecallAfterOcrDamage();
  Set<SensitiveKind> of(String text) => SensitiveData.kindsIn(text);

  group('card numbers', () {
    test('finds a Luhn-valid number, spaced or not', () {
      // Visa test number — valid checksum, not a real card.
      expect(of('4111 1111 1111 1111'), contains(SensitiveKind.card));
      expect(of('4111111111111111'), contains(SensitiveKind.card));
      expect(of('Card: 5500-0000-0000-0004'), contains(SensitiveKind.card));
    });

    test('finds one buried in a sentence', () {
      expect(
        of('paid with 4111 1111 1111 1111 on tuesday'),
        contains(SensitiveKind.card),
      );
    });

    test('understands Arabic-Indic digits', () {
      // The same test number written the way an Arabic banking app renders
      // it. Without digit normalisation this is invisible.
      expect(of('٤١١١ ١١١١ ١١١١ ١١١١'), contains(SensitiveKind.card));
    });

    test('a same-length reference number is not a card', () {
      // Fails Luhn, so it must not be flagged — this is the check that keeps
      // order numbers and tracking codes out of the way.
      expect(of('Order 1234567890123456'), isNot(contains(SensitiveKind.card)));
    });

    test('short numbers are never cards', () {
      expect(of('total 4111'), isNot(contains(SensitiveKind.card)));
    });
  });

  group('bank accounts', () {
    test('finds a checksum-valid IBAN', () {
      expect(
        of('Transfer to GB82 WEST 1234 5698 7654 32'),
        contains(SensitiveKind.iban),
      );
    });

    test('ignores an IBAN-shaped reference that fails the checksum', () {
      expect(
        of('Ref GB82WEST12345698765433'),
        isNot(contains(SensitiveKind.iban)),
      );
    });
  });

  group('codes and identifiers', () {
    test('a verification code needs a cue word', () {
      expect(of('Your code is 483920'), contains(SensitiveKind.code));
      // One per shipped language, because a cue list is exactly the kind of
      // thing that gets extended in English and forgotten everywhere else.
      expect(of('Ihr Sicherheitscode 4821'), contains(SensitiveKind.code));
      expect(of('Je verificatiecode is 4821'), contains(SensitiveKind.code));
      expect(of('Il codice è 4821'), contains(SensitiveKind.code));
      expect(of('O código de verificação é 4821'),
          contains(SensitiveKind.code));
      expect(of('Su código de verificación es 4821'),
          contains(SensitiveKind.code));
      expect(of('Votre code de vérification est 4821'),
          contains(SensitiveKind.code));
      expect(of('Room 4821, floor 3'), isNot(contains(SensitiveKind.code)));
    });

    /// **A label describes the line it is on, and at most the one below.**
    ///
    /// The window either side of a number was `\D{0,20}` — any twenty
    /// non-digits, newlines included — so on a real screenshot the words
    /// "verification code" reached backwards past a line break and named the
    /// account number above them. Both numbers came back as codes, and the
    /// Safe Share review list said so in plain words.
    ///
    /// Covering an account number is right. *Naming* it a code is what
    /// [SensitiveKind.number] exists to avoid — and since the actions sheet
    /// now takes its private spans from this file, the wrong name also decides
    /// whether the app offers to copy it.
    group('a label reaches forward further than it reaches back', () {
      const String twoLines =
          'Account number 4820193\nYour verification code is 481920';

      List<SensitiveMatch> codesIn(String text) => SensitiveData.findIn(text)
          .where((SensitiveMatch m) => m.kind == SensitiveKind.code)
          .toList();

      test('the label does not claim the number on the line above it', () {
        final List<SensitiveMatch> codes = codesIn(twoLines);
        expect(codes, hasLength(1));
        expect(codes.single.value, '481920');
      });

      test('the account number above is still covered, just not named', () {
        // The point is the label, not the redaction: whatever it is called,
        // it must not be left visible.
        expect(of(twoLines), contains(SensitiveKind.number));
      });

      test('a label on its own line still reaches the number beneath it', () {
        // The layout this rule exists for, and the reason newlines are not
        // simply banned.
        expect(
          codesIn('Your verification code is:\n481920').single.value,
          '481920',
        );
        expect(
          codesIn('Ihr Bestätigungscode\n4821').single.value,
          '4821',
        );
      });

      test('but not two lines beneath it', () {
        // Two breaks means the label belongs to something else that has since
        // been passed over.
        expect(codesIn('Your verification code\n\n481920'), isEmpty);
      });

      test('a trailing label still works on its own line', () {
        expect(codesIn('481920 is your code').single.value, '481920');
      });
    });

    test('a national ID needs its label', () {
      expect(of('National ID 1234567890'), contains(SensitiveKind.nationalId));
      // Nine to eleven digits is the range this rule covers, so the labels
      // tested here are the ones whose numbers actually fall in it: the Dutch
      // BSN is nine, the Portuguese NIF nine, the German Steuer-ID eleven.
      expect(of('BSN: 123456789'), contains(SensitiveKind.nationalId));
      expect(of('NIF 123456789'), contains(SensitiveKind.nationalId));
      expect(
        of('Steuer-ID 12345678901'),
        contains(SensitiveKind.nationalId),
      );
      // Unlabelled, so far more likely an order number.
      expect(of('1234567890'), isNot(contains(SensitiveKind.nationalId)));
    });
  });

  group('contact details', () {
    test('email and phone', () {
      expect(of('write to sara@example.com'), contains(SensitiveKind.email));
      expect(of('call +962 7 9123 4567'), contains(SensitiveKind.phone));
      expect(of('Handy 0599123456'), contains(SensitiveKind.phone));
      expect(of('Telefoonnummer 0599123456'), contains(SensitiveKind.phone));
      expect(of('Cellulare 0599123456'), contains(SensitiveKind.phone));
      expect(of('Telemóvel 0599123456'), contains(SensitiveKind.phone));
    });

    test('a date is not a phone number', () {
      // Otherwise every receipt would come back with its date blurred.
      expect(of('12/05/2024'), isNot(contains(SensitiveKind.phone)));
      expect(of('12-05-2024'), isNot(contains(SensitiveKind.phone)));
    });

    test('a label makes a number a phone number', () {
      expect(of('Phone: 4567890123'), contains(SensitiveKind.phone));
      expect(of('جوال ٠٥٩٩١٢٣٤٥٦'), contains(SensitiveKind.phone));
      expect(of('WhatsApp 970 599 123456'), contains(SensitiveKind.phone));
    });
  });

  group('unnamed numbers', () {
    // The complaint this group exists for: every long number on a screen was
    // being listed to the user as a phone number, so the one label the review
    // list has to get right was wrong most of the time.
    test('a number with nothing to say for itself is not a phone number', () {
      expect(of('Meter reading 8842119'), isNot(contains(SensitiveKind.phone)));
      expect(of('Meter reading 8842119'), contains(SensitiveKind.number));
      expect(of('Balance 1250000 SAR'), isNot(contains(SensitiveKind.phone)));
    });

    test('but it is still covered', () {
      // Covering it was never in question. Naming it was.
      expect(of('8842119'), contains(SensitiveKind.number));
    });

    test('a long reference that fails Luhn no longer falls through', () {
      // Nineteen digits: too long for the old phone rule, rejected by the card
      // rule, unlabelled so no order-number rule claims it. It used to leave
      // the scan entirely and stay visible in the shared copy.
      const String reference = '1234567890123456789';
      expect(of(reference), contains(SensitiveKind.number));
    });

    test('a named number keeps its name', () {
      expect(of('Order number 4567890'), contains(SensitiveKind.orderNumber));
      expect(of('Order number 4567890'), isNot(contains(SensitiveKind.number)));
      expect(
        of('4111 1111 1111 1111'),
        allOf(contains(SensitiveKind.card), isNot(contains(SensitiveKind.number))),
      );
    });

    test('a date is still not a number worth hiding', () {
      expect(of('12/05/2024'), isEmpty);
    });
  });

  group('whole lines', () {
    test('one line can carry several kinds', () {
      final Set<SensitiveKind> kinds = of(
        'sara@example.com · 0791234567 · card 4111 1111 1111 1111',
      );
      expect(kinds, contains(SensitiveKind.email));
      expect(kinds, contains(SensitiveKind.phone));
      expect(kinds, contains(SensitiveKind.card));
    });

    test('ordinary text is left alone', () {
      expect(of('Meeting moved to the big room'), isEmpty);
      expect(of('Total 45.90 JOD'), isEmpty);
      expect(of(''), isEmpty);
    });
  });
}

/// Added after a real report: a screenshot holding four addresses had three
/// covered and one missed. The pattern was never wrong — what OCR handed it
/// was. These are the shapes text recognition actually produces.
void _emailRecallAfterOcrDamage() {
  group('emails survive OCR damage', () {
    const List<String> damaged = [
      'ali@gmail.com',
      'ali @gmail.com',
      'ali@ gmail.com',
      'ali @ gmail.com',
      'ali@gmail. com',
      'ali@gmail,com',
      'ali@gmail , com',
      'ali©gmail.com',
      'ali＠gmail.com',
      'Contact: Ali.Hassan+work@sub.domain.co.uk today',
    ];

    for (final String text in damaged) {
      test('finds an address in "$text"', () {
        expect(
          SensitiveData.kindsIn(text),
          contains(SensitiveKind.email),
          reason: 'a missed address is a leak the user cannot undo',
        );
      });
    }

    test('four addresses on four lines are all found', () {
      const List<String> lines = [
        'ali @gmail.com',
        'sara@outlook,com',
        'mohammed©hotmail.com',
        'x.y+z@sub.domain.co',
      ];
      for (final String line in lines) {
        expect(
          SensitiveData.kindsIn(line),
          contains(SensitiveKind.email),
          reason: line,
        );
      }
    });
  });

  group('the repair does not invent addresses', () {
    const List<String> notEmails = [
      'Total 1,000.50 SAR',
      'See you at 5 pm',
      'Copyright © 2026 Shoto',
      'version 2.5.1',
      'read the docs . thanks',
    ];

    for (final String text in notEmails) {
      test('"$text" is not an address', () {
        expect(
          SensitiveData.kindsIn(text),
          isNot(contains(SensitiveKind.email)),
        );
      });
    }
  });

  /// **The house number comes last outside the English-speaking world**, and
  /// until the shipped languages changed nothing in this file could express
  /// that. The unlabelled street rule required the number to *lead* — the
  /// English form — so `Hauptstraße 12` and `Via Roma 12` were invisible, and
  /// a German user sharing a screenshot of a delivery confirmation had their
  /// home address go out uncovered.
  ///
  /// This is the one place in the language swap where a translation gap was
  /// really a *missing rule*, which is why it gets its own group.
  group('street lines in the shipped word orders', () {
    const List<String> streets = <String>[
      // Number last, type welded to the name.
      'Hauptstraße 12',
      'Hauptstrasse 12',
      'Kerkstraat 5a',
      'Prinsengracht 263',
      'Lindenallee 7',
      'Bahnhofsplatz 3',
      // Number last, type leading.
      'Via Roma 12',
      'Piazza del Duomo 4',
      'Rua Augusta 24',
      'Avenida da Liberdade 110',
      'Calle Mayor 8',
      'Rue de Rivoli 15',
      // The English form still works.
      '221 Baker Street',
    ];

    for (final String text in streets) {
      test('"$text" is an address', () {
        expect(
          SensitiveData.kindsIn('Lieferung an $text, bitte klingeln'),
          contains(SensitiveKind.postalAddress),
          reason: 'an uncovered home address is a leak the user cannot undo',
        );
      });
    }
  });

  group('the street rules do not invent addresses', () {
    /// The words carrying the street rules are ordinary nouns in the same
    /// languages — *Weg*, *Ring*, *hof*, *place*, *corso* — so each of these
    /// is a sentence the rule must stay out of. The house number is what
    /// separates the two, which is why it is required.
    const List<String> notStreets = <String>[
      'Der Weg war lang und ruhig',
      'Ring mich morgen an',
      'Wir treffen uns im Hof',
      'De kade was druk vandaag',
      'Il corso di italiano inizia lunedì',
    ];

    for (final String text in notStreets) {
      test('"$text" is not an address', () {
        expect(
          SensitiveData.kindsIn(text),
          isNot(contains(SensitiveKind.postalAddress)),
          reason: text,
        );
      });
    }
  });
}
