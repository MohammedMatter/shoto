import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/sensitive_data.dart';

/// Spans, not just kinds.
///
/// `sensitive_data_test.dart` asks whether a card number is *there*, which is
/// all the old black-box redaction needed. Substitution needs to know exactly
/// which characters it is, and every one of these tests is really the same
/// assertion: the offsets and the text agree, so what gets painted over is
/// what was found. An off-by-one here is not a wrong colour on screen — it is
/// a digit of a real card number left showing at the edge of a fake one.
void main() {
  List<SensitiveMatch> find(String text, {Set<String> owner = const {}}) =>
      SensitiveData.findIn(text, ownerNames: owner);

  /// The invariant that has to hold for every match, whatever found it.
  void expectConsistent(String text, List<SensitiveMatch> matches) {
    for (final SensitiveMatch m in matches) {
      expect(m.start, greaterThanOrEqualTo(0), reason: '$m');
      expect(m.end, lessThanOrEqualTo(text.length), reason: '$m');
      expect(m.start, lessThan(m.end), reason: '$m');
      expect(
        text.substring(m.start, m.end),
        m.value,
        reason: 'span and value disagree for $m',
      );
    }
    for (int i = 1; i < matches.length; i++) {
      expect(
        matches[i].start,
        greaterThanOrEqualTo(matches[i - 1].end),
        reason: 'matches overlap: ${matches[i - 1]} and ${matches[i]}',
      );
    }
  }

  group('the value, not the line', () {
    test('a card number is claimed without its label', () {
      const String text = 'Card number: 4111 1111 1111 1111';
      final List<SensitiveMatch> found = find(text);
      expectConsistent(text, found);

      final SensitiveMatch card = found.singleWhere(
        (SensitiveMatch m) => m.kind == SensitiveKind.card,
      );
      expect(card.value, '4111 1111 1111 1111');
      expect(text.substring(0, card.start), 'Card number: ');
    });

    test('a trailing full stop stays in the sentence', () {
      // If the span eats the period, the exported image loses it and the
      // line reads as if it were cut off.
      const String text = 'Paid with 4111 1111 1111 1111.';
      final SensitiveMatch card = find(text).single;
      expect(card.value, '4111 1111 1111 1111');
      expect(text.substring(card.end), '.');
    });

    test('Arabic-Indic digits are reported at their real offsets', () {
      const String text = 'البطاقة ٤١١١ ١١١١ ١١١١ ١١١١';
      final List<SensitiveMatch> found = find(text);
      expectConsistent(text, found);
      expect(found.single.kind, SensitiveKind.card);
      expect(found.single.value, '٤١١١ ١١١١ ١١١١ ١١١١');
      expect(SensitiveData.usesArabicDigits(found.single.value), isTrue);
    });

    test('an email damaged by OCR still reports the real span', () {
      // The matcher works on a repaired copy where the spaces are gone, so
      // this is the case that breaks without an index map.
      const String text = 'write to ali @ gmail . com today';
      final List<SensitiveMatch> found = find(text);
      expectConsistent(text, found);

      final SensitiveMatch email = found.singleWhere(
        (SensitiveMatch m) => m.kind == SensitiveKind.email,
      );
      expect(email.value, 'ali @ gmail . com');
    });
  });

  group('names', () {
    test('a labelled name is found', () {
      const String text = 'Full name: Mohammed Abo Matter';
      final SensitiveMatch match = find(text).single;
      expect(match.kind, SensitiveKind.personName);
      expect(match.value, 'Mohammed Abo Matter');
    });

    test('bare "name" without a colon is not a field', () {
      expect(find('Name your folder'), isEmpty);
      expect(find('Filename report.pdf'), isEmpty);
    });

    test('"name" inside another word never triggers', () {
      // The lookbehind is the whole defence here.
      expect(find('Filename: report'), isEmpty);
      expect(find('Username: reports'), isEmpty);
    });

    test('the signed-in user is found with no label at all', () {
      const String text = 'Mohammed Abo Matter sent you a document';
      final Set<String> owner = SensitiveData.namesFrom('Mohammed Abo Matter');
      final SensitiveMatch match = find(text, owner: owner).single;

      expect(match.kind, SensitiveKind.personName);
      expect(match.start, 0);
      expect(match.value, 'Mohammed Abo Matter');
    });

    test('just the first name counts too', () {
      final Set<String> owner = SensitiveData.namesFrom('Mohammed Abo Matter');
      final SensitiveMatch match = find('Hi Mohammed', owner: owner).single;
      expect(match.value, 'Mohammed');
    });

    test('a name inside a longer word does not count', () {
      final Set<String> owner = SensitiveData.namesFrom('Mohammed Abo Matter');
      expect(find('Mohammedan history', owner: owner), isEmpty);
    });

    test('two-letter parts are ignored', () {
      // "Al" would otherwise match inside half the words on a screen.
      expect(SensitiveData.namesFrom('Al Bo Rashid'), <String>{
        'Al Bo Rashid',
        'Rashid',
      });
    });

    test('Arabic spelling variants are the same name', () {
      // Written with hamza in the account, without it in the screenshot.
      final Set<String> owner = SensitiveData.namesFrom('محمد أبو مطر');
      const String text = 'من محمد ابو مطر';
      final List<SensitiveMatch> found = find(text, owner: owner);
      expectConsistent(text, found);

      final SensitiveMatch match = found.singleWhere(
        (SensitiveMatch m) => m.kind == SensitiveKind.personName,
      );
      expect(match.value, 'محمد ابو مطر');
    });

    test('the full name wins over its parts', () {
      final Set<String> owner = SensitiveData.namesFrom('Mohammed Abo Matter');
      final List<SensitiveMatch> found = find(
        'To: Mohammed Abo Matter',
        owner: owner,
      );
      expect(found.length, 1);
      expect(found.single.value, 'Mohammed Abo Matter');
    });
  });

  group('addresses', () {
    test('a labelled address is claimed whole', () {
      const String text = 'Address: 418 Maple Avenue, Springfield';
      final SensitiveMatch match = find(text).single;
      expect(match.kind, SensitiveKind.postalAddress);
      expect(match.value, '418 Maple Avenue, Springfield');
    });

    test('an unlabelled street line is recognised', () {
      const String text = 'Deliver to 418 Maple Avenue before noon';
      final List<SensitiveMatch> found = find(text);
      expectConsistent(text, found);
      expect(
        found.map((SensitiveMatch m) => m.kind),
        contains(SensitiveKind.postalAddress),
      );
    });

    test('"1 st" is not a street', () {
      // Without requiring a word between the number and the suffix, every
      // "1 st place" in the app becomes an address.
      expect(find('finished 1 st place'), isEmpty);
    });

    test('"Location services" is not an address', () {
      expect(find('Location services are on'), isEmpty);
      expect(find('Address book'), isEmpty);
    });

    test('coordinates count as a location', () {
      const String text = '24.774265, 46.738586';
      final SensitiveMatch match = find(text).single;
      expect(match.kind, SensitiveKind.postalAddress);
      expect(match.value, text);
    });

    test('a phone inside an address keeps its own span', () {
      // The address capture runs over the phone number; clipping is what
      // stops the whole address being dropped because four characters of it
      // were already spoken for.
      const String text = 'Address: 418 Maple Avenue call 0501234567';
      final List<SensitiveMatch> found = find(text);
      expectConsistent(text, found);

      expect(found.map((SensitiveMatch m) => m.kind).toSet(), <SensitiveKind>{
        SensitiveKind.postalAddress,
        SensitiveKind.phone,
      });
      expect(
        found
            .singleWhere((SensitiveMatch m) => m.kind == SensitiveKind.phone)
            .value,
        '0501234567',
      );
    });
  });

  group('order numbers', () {
    test('a labelled reference is found', () {
      const String text = 'Order number 4567890';
      final SensitiveMatch match = find(text).single;
      expect(match.kind, SensitiveKind.orderNumber);
      expect(match.value, '4567890');
    });

    test('a colon does the same job as the word "number"', () {
      final SensitiveMatch match = find('Order: A82-4471').single;
      expect(match.kind, SensitiveKind.orderNumber);
      expect(match.value, 'A82-4471');
    });

    test('a full stop separates a numeric field', () {
      final SensitiveMatch match = find('Invoice no. 55231').single;
      expect(match.value, '55231');
    });

    test('"Order Details" is a heading, not a number', () {
      expect(find('Order Details'), isEmpty);
      expect(find('Order Summary'), isEmpty);
      expect(find('Tracking your parcel'), isEmpty);
    });

    test('a value with no digit is not a reference', () {
      expect(find('Reference: unavailable'), isEmpty);
    });
  });

  group('one piece of text is only ever one thing', () {
    test('a bank account is never reported as a card', () {
      // A 24-character IBAN contains eighteen-digit runs, and about one in
      // ten of those passes Luhn by coincidence. Before IBANs were claimed
      // first, those accounts were labelled "Card number" — and would have
      // been replaced by a *card* number, breaking the line's shape.
      for (final String iban in <String>[
        'SA03 8000 0000 6080 1016 7519',
        'SA04 5810 8100 1005 7975 6700',
        'SA59 6280 7166 1483 3841 6626',
        'SA03 4361 6446 6656 4115 6525',
      ]) {
        final List<SensitiveMatch> found = find(iban);
        expect(found.map((SensitiveMatch m) => m.kind), <SensitiveKind>[
          SensitiveKind.iban,
        ], reason: iban);
      }
    });

    test('a card number is not also a phone number', () {
      final List<SensitiveMatch> found = find('4556 7375 8689 9855');
      expect(found.length, 1);
      expect(found.single.kind, SensitiveKind.card);
    });

    test('an email domain is not an address', () {
      const String text = 'Contact: ali.hassan@example.com';
      final List<SensitiveMatch> found = find(text);
      expectConsistent(text, found);
      expect(
        found
            .singleWhere((SensitiveMatch m) => m.kind == SensitiveKind.email)
            .value,
        'ali.hassan@example.com',
      );
    });

    test('a whole receipt line stays consistent', () {
      const String text =
          'Order number 4567890 — Full name: Sara Ahmed — call 0559876543 — '
          'sara@example.com — Address: 12 King Fahd Road, Riyadh';
      final List<SensitiveMatch> found = find(text);
      expectConsistent(text, found);

      expect(
        found.map((SensitiveMatch m) => m.kind).toSet(),
        containsAll(<SensitiveKind>[
          SensitiveKind.orderNumber,
          SensitiveKind.personName,
          SensitiveKind.phone,
          SensitiveKind.email,
          SensitiveKind.postalAddress,
        ]),
      );
    });

    test('ordinary interface text yields nothing', () {
      for (final String text in <String>[
        'Settings',
        'Add to favourites',
        'Order Details',
        '3 items in your basket',
        'Version 2.5.1',
        'Updated 12/05/2024',
      ]) {
        expect(find(text), isEmpty, reason: text);
      }
    });
  });
}
