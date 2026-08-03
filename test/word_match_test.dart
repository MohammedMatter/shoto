import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/word_match.dart';

/// The cases that matter here are the ones that must **not** match.
///
/// A filing rule is a substring test that moves your files. The whole reason
/// this class exists is that `String.contains` was reading "code" out of
/// "barcode" and filing screenshots into a folder for a word that was never
/// on them — and unlike a bad search result, nothing on screen said so.
void main() {
  group('whole words only', () {
    test('a word inside a longer word does not count', () {
      expect(WordMatch.contains('Scan the barcode', 'code'), isFalse);
      expect(WordMatch.contains('Failed to decode', 'code'), isFalse);
      expect(WordMatch.contains('I totally forgot', 'total'), isFalse);
      expect(WordMatch.contains('Password manager', 'word'), isFalse);
    });

    test('the same word standing on its own does', () {
      expect(WordMatch.contains('Your code is 4410', 'code'), isTrue);
      expect(WordMatch.contains('Order total: 90.00', 'total'), isTrue);
    });

    test('punctuation ends a word', () {
      for (final String text in [
        'total: 90',
        'total,90',
        '(total)',
        'Invoice — total',
        'total\n90',
      ]) {
        expect(WordMatch.contains(text, 'total'), isTrue, reason: text);
      }
    });

    test('an occurrence inside a word does not hide a real one later', () {
      // The first hit is rejected; the search has to keep going rather than
      // conclude the word is absent.
      expect(WordMatch.contains('barcode — your code is 12', 'code'), isTrue);
    });

    test('a phrase matches as a phrase', () {
      expect(WordMatch.contains('Your boarding pass', 'boarding pass'), isTrue);
      expect(WordMatch.contains('boarding gate 12', 'boarding pass'), isFalse);
    });
  });

  group('English plurals', () {
    test('a rule written singular still catches the plural', () {
      expect(WordMatch.contains('Two invoices attached', 'invoice'), isTrue);
      expect(WordMatch.contains('All my codes', 'code'), isTrue);
    });

    test('but only the plural, not any longer word', () {
      expect(WordMatch.contains('invoiced last week', 'invoice'), isFalse);
    });
  });

  group('Arabic', () {
    test('the attached article and conjunctions still match', () {
      // These are the forms the word actually appears in. Requiring a hard
      // boundary would be "stricter" and simply wrong.
      for (final String text in [
        'فاتورة الكهرباء',
        'الفاتورة جاهزة',
        'وصلت والفاتورة معها',
        'بالفاتورة المرفقة',
        'للفاتورة رقم 12',
      ]) {
        expect(WordMatch.contains(text, 'فاتورة'), isTrue, reason: text);
      }
    });

    test('spelling differences do not break it either', () {
      // Normalization runs on both sides — ta marbuta against ha.
      expect(WordMatch.contains('فاتوره الكهرباء', 'فاتورة'), isTrue);
      expect(WordMatch.contains('الفاتورة', 'فاتوره'), isTrue);
    });

    test('a different word that merely starts the same does not', () {
      expect(WordMatch.contains('كتاب الطبخ', 'كتب'), isFalse);
      expect(WordMatch.contains('مطعم', 'طعم'), isFalse);
    });

    test('Arabic punctuation ends a word', () {
      expect(WordMatch.contains('الفاتورة، والرقم', 'فاتورة'), isTrue);
      expect(WordMatch.contains('فاتورة؟', 'فاتورة'), isTrue);
    });
  });

  group('refusing to act', () {
    test('an empty or punctuation-only needle never matches', () {
      for (final String needle in ['', '   ', '—', '،']) {
        expect(WordMatch.contains('anything at all', needle), isFalse);
      }
    });

    test('empty text matches nothing', () {
      expect(WordMatch.contains('', 'invoice'), isFalse);
      expect(WordMatch.contains('   ', 'invoice'), isFalse);
    });

    test('case never matters', () {
      expect(WordMatch.contains('INVOICE #12', 'invoice'), isTrue);
      expect(WordMatch.contains('invoice #12', 'INVOICE'), isTrue);
    });
  });
}
