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
      final Set<ContentTrait> phone = ContentTraits.of('Call 0599 123 456');
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
