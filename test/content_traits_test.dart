import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/content_traits.dart';

/// A Visa test number that genuinely passes Luhn — the filter's whole claim is
/// that it is arithmetic rather than shape, so a fake number here would test
/// nothing.
const String _validCard = '4539 1488 0343 6467';

void main() {
  group('recognition', () {
    test('a checksum-valid card marks the screenshot sensitive', () {
      expect(
        ContentTraits.of('Payment method $_validCard exp 04/27'),
        contains(ContentTrait.sensitive),
      );
    });

    test('a URL marks it as carrying a link', () {
      expect(
        ContentTraits.of('Read more at https://example.com/article'),
        contains(ContentTrait.link),
      );
    });

    test('a phone number and an email both land on one contact trait', () {
      final Set<ContentTrait> phone = ContentTraits.of('Phone 0599 123 456');
      final Set<ContentTrait> email = ContentTraits.of('write to a@b.com');
      expect(phone, contains(ContentTrait.contact));
      expect(email, contains(ContentTrait.contact));
    });

    test('a cued verification code is recognised', () {
      expect(
        ContentTraits.of('Your verification code is 481920'),
        contains(ContentTrait.code),
      );
    });
  });

  group('the sensitive trait is checksum-backed, not shape-backed', () {
    // This is the property that lets the UI label this trait "verified" while
    // every other trait is labelled "read from text". If a number that merely
    // looks like a card starts matching, that label becomes a lie.
    test('a 16-digit run that fails Luhn is not sensitive', () {
      expect(
        ContentTraits.of('Order reference 1234 5678 9012 3456 shipped'),
        isNot(contains(ContentTrait.sensitive)),
      );
    });

    test('a phone number does not make a screenshot sensitive', () {
      expect(
        ContentTraits.of('Call me on 0599 123 456'),
        isNot(contains(ContentTrait.sensitive)),
      );
    });

    test('an email address alone is not sensitive', () {
      expect(
        ContentTraits.of('Contact support at help@example.com'),
        isNot(contains(ContentTrait.sensitive)),
      );
    });
  });

  group('a phone needs a reason to be a phone', () {
    // Every string in this group was pulled off the test device, where they
    // were all being counted as somebody's phone number and lighting the
    // contact chip on screenshots holding no contact at all.
    test('4-4-4 reference groups are not contacts', () {
      for (final String run in <String>[
        '9923-7290-4590',
        '4018-5724-2201',
        '2143-9317-6250',
        '4206-1401-2233',
        '5296-8375-9467',
        '3698-5387-3049',
      ]) {
        expect(
          ContentTraits.of('Reference $run for your records'),
          isNot(contains(ContentTrait.contact)),
          reason: '$run must not read as a contact',
        );
      }
    });

    test('a long bare digit run is not a contact', () {
      expect(
        ContentTraits.of('Meter reading 742033809805910 recorded'),
        isNot(contains(ContentTrait.contact)),
      );
    });

    test('a number split across two lines is not a contact', () {
      expect(
        ContentTraits.of('Account\n76350000\n159759\nbalance'),
        isNot(contains(ContentTrait.contact)),
      );
    });

    test('a short unlabelled run is not a contact', () {
      expect(
        ContentTraits.of('Your order 1234565 has shipped today'),
        isNot(contains(ContentTrait.contact)),
      );
    });

    test('digits welded to letters are not a number at all', () {
      // Straight off the test device: an IBAN reference page printing
      // ABNA0417164300, which the app was offering to dial.
      expect(
        ContentTraits.of('BBAN ABNA0417164300 country code'),
        isNot(contains(ContentTrait.contact)),
      );
    });

    test('a country code is evidence enough on its own', () {
      expect(
        ContentTraits.of('+962 7 9123 4567'),
        contains(ContentTrait.contact),
      );
    });

    test('a cue word rescues a bare local number', () {
      expect(
        ContentTraits.of('جوال 0599123456'),
        contains(ContentTrait.contact),
      );
      expect(
        ContentTraits.of('Mobile 0599123456'),
        contains(ContentTrait.contact),
      );
    });

    test('"order number" is not a phone cue', () {
      // The bare word for "number" prefixes far more order references than
      // phones, which is why it is kept out of the cue list.
      expect(
        ContentTraits.of('رقم الطلب 5551234'),
        isNot(contains(ContentTrait.contact)),
      );
    });

    test('a cue must be a whole word, not a substring', () {
      // Taken verbatim from an IBAN reference page on the test device: the
      // byline "Mobilefish.com" contained the cue `mobile`, which certified an
      // account-number fragment as somebody's phone number.
      expect(
        ContentTraits.of(
          'IBAN structure BBAN NL91 ABNA0417164300 '
          '2 digit checksum Country code Mobilefish.com',
        ),
        isNot(contains(ContentTrait.contact)),
      );

      // The same trap in the other cues.
      for (final String text in <String>[
        'The hotel booking 5551234 is confirmed',
        'An excellent result 5551234 was recorded',
        'Please recall order 5551234 immediately',
      ]) {
        expect(
          ContentTraits.of(text),
          isNot(contains(ContentTrait.contact)),
          reason: text,
        );
      }
    });

    test('non-Latin cues still match as whole words', () {
      // `\b` is ASCII-only in Dart, so a naive word-boundary fix would have
      // silently killed every Arabic, Hindi and Urdu cue.
      expect(
        ContentTraits.of('هاتف 0599123456'),
        contains(ContentTrait.contact),
      );
      expect(
        ContentTraits.of('मोबाइल 0599123456'),
        contains(ContentTrait.contact),
      );
    });

    test('an email is a contact with no cue word at all', () {
      expect(
        ContentTraits.of('help@example.com'),
        contains(ContentTrait.contact),
      );
    });
  });

  group('false-positive resistance', () {
    test('a bare number with no cue word is not a verification code', () {
      expect(
        ContentTraits.of('Total was 4820 shekels for the whole order'),
        isNot(contains(ContentTrait.code)),
      );
    });

    test('a version string is not a link', () {
      expect(
        ContentTraits.of('Running app version 2.5.1 on this device'),
        isNot(contains(ContentTrait.link)),
      );
    });

    test('ordinary prose carries no traits at all', () {
      expect(
        ContentTraits.of(
          'I went to the shop this morning and it was raining the whole way',
        ),
        isEmpty,
      );
    });
  });

  group('absent and unusable text', () {
    // Null means "never read". It must come back empty rather than throwing,
    // because most of a fresh library is in exactly this state.
    test('null text yields no traits', () {
      expect(ContentTraits.of(null), isEmpty);
    });

    test('empty and whitespace-only text yield no traits', () {
      expect(ContentTraits.of(''), isEmpty);
      expect(ContentTraits.of('   \n  '), isEmpty);
    });

    test('text below the useful length is skipped', () {
      expect(ContentTraits.of('ok'), isEmpty);
    });
  });

  group('Arabic', () {
    // Arabic-Indic digits are the recurring trap in this codebase: \d matches
    // none of them, so an Arabic-UI screenshot silently yields nothing unless
    // the extractor normalises first.
    test('a code written in Arabic-Indic digits is still recognised', () {
      expect(
        ContentTraits.of('رمز التحقق الخاص بك هو ٤٨١٩٢٠'),
        contains(ContentTrait.code),
      );
    });

    test('an Arabic sentence with a link finds the link', () {
      expect(
        ContentTraits.of('اقرأ المزيد على https://example.com/news'),
        contains(ContentTrait.link),
      );
    });
  });

  group('certainty labelling', () {
    test('only the sensitive trait claims to be verified', () {
      expect(ContentTrait.sensitive.certainty, TraitCertainty.verified);
      for (final ContentTrait trait in ContentTrait.values) {
        if (trait == ContentTrait.sensitive) continue;
        expect(
          trait.certainty,
          TraitCertainty.read,
          reason: '$trait must not claim checksum certainty',
        );
      }
    });
  });

  test('several traits can coexist in one screenshot', () {
    final Set<ContentTrait> traits = ContentTraits.of(
      'Your code is 481920. Track it at https://example.com or call 0599123456',
    );
    expect(traits, contains(ContentTrait.code));
    expect(traits, contains(ContentTrait.link));
    expect(traits, contains(ContentTrait.contact));
  });
}
