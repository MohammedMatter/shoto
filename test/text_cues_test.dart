import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/text_cues.dart';

void main() {
  group('Latin cues match whole words only', () {
    // Every pair below is a real or near-miss false positive from the app's
    // own cue lists. The left column is what a screenshot actually said.
    const Map<String, String> traps = <String, String>{
      'mobilefish.com': 'mobile',
      'barcode scanner': 'code',
      'shipping label': 'pin',
      'hotel booking': 'tel',
      'excellent work': 'cell',
      'please recall this': 'call',
      'for example see below': 'exam',
      'eventually it arrived': 'event',
      'took possession today': 'session',
      'citación judicial': 'cita',
      'postcode lookup': 'code',
      'decode the message': 'code',
    };

    traps.forEach((String haystack, String cue) {
      test('"$cue" does not match inside "$haystack"', () {
        expect(TextCues.has(haystack, cue), isFalse);
      });
    });

    test('the same cues still match when they stand alone', () {
      expect(TextCues.has('your code is 4821', 'code'), isTrue);
      expect(TextCues.has('mobile 0599123456', 'mobile'), isTrue);
      expect(TextCues.has('the exam starts at 9', 'exam'), isTrue);
      expect(TextCues.has('one event on friday', 'event'), isTrue);
    });

    test('punctuation and line breaks count as boundaries', () {
      expect(TextCues.has('(code) 4821', 'code'), isTrue);
      expect(TextCues.has('code:4821', 'code'), isTrue);
      expect(TextCues.has('your code\n4821', 'code'), isTrue);
      expect(TextCues.has('code', 'code'), isTrue);
    });
  });

  group('stems', () {
    test('a starred cue may run on', () {
      expect(TextCues.has('your invitation awaits', 'invit*'), isTrue);
      expect(TextCues.has('you are invited', 'invit*'), isTrue);
      expect(TextCues.has('inviting you along', 'invit*'), isTrue);
      expect(TextCues.has('reservation confirmed', 'reserv*'), isTrue);
      expect(TextCues.has('scheduled for monday', 'schedul*'), isTrue);
    });

    test('a stem still has to start a word', () {
      // Otherwise "reinvite" and "uninvited" would qualify, and more to the
      // point so would any word that merely contains the letters.
      expect(TextCues.has('disinvit', 'invit*'), isFalse);
      expect(TextCues.has('preserve it', 'reserv*'), isFalse);
    });
  });

  group('non-Latin cues match as substrings', () {
    // Arabic takes its article and conjunctions as prefixes, so a boundary
    // rule would lose ordinary hits. This is a deliberate difference, not an
    // oversight — see the class doc.
    test('an Arabic cue survives its prefixes', () {
      expect(TextCues.has('الموعد يوم الخميس', 'موعد'), isTrue);
      expect(TextCues.has('وموعد التسليم', 'موعد'), isTrue);
      expect(TextCues.has('رمز التحقق ٤٨٢١', 'رمز'), isTrue);
    });

    test('Hindi and Urdu cues match', () {
      expect(TextCues.has('मोबाइल 0599123456', 'मोबाइल'), isTrue);
      expect(TextCues.has('فون نمبر', 'فون'), isTrue);
    });

    test('an absent Arabic cue is still absent', () {
      expect(TextCues.has('رقم الطلب ٤٨٢١', 'جوال'), isFalse);
    });
  });

  group('anyNear', () {
    const String text =
        'reference 5551234 and further down the page contact us';

    test('a cue outside the window does not vouch', () {
      // "contact" sits ~35 characters past the end of the number.
      expect(TextCues.anyNear(text, 10, 17, 10, <String>['contact']), isFalse);
    });

    test('a cue inside the window does', () {
      expect(TextCues.anyNear(text, 10, 17, 60, <String>['contact']), isTrue);
    });

    test('windows clamp at both ends of the string', () {
      expect(
        TextCues.anyNear('code 4821', 5, 9, 999, <String>['code']),
        isTrue,
      );
    });
  });

  group('maxLineGap', () {
    // Verbatim shape of the barcode page from the test device: a real,
    // whole-word "code" within forty characters of the number, but three line
    // breaks away — a heading, not a label.
    const String barcodePage =
        'country mfg code\nUPC-A\nC5 google\n012345 678905\nInterleaved';

    test('a cue several lines away does not vouch', () {
      final int at = barcodePage.indexOf('012345');
      expect(
        TextCues.anyNear(barcodePage, at, at + 6, 40, <String>[
          'code',
        ], maxLineGap: 1),
        isFalse,
      );
    });

    test('without the cap the same text passes, which is the bug', () {
      final int at = barcodePage.indexOf('012345');
      expect(
        TextCues.anyNear(barcodePage, at, at + 6, 40, <String>['code']),
        isTrue,
      );
    });

    test('a label broken onto the next line still vouches', () {
      // How most one-time-password messages are actually laid out.
      const String otp = 'Your verification code is\n481920';
      final int at = otp.indexOf('481920');
      expect(
        TextCues.anyNear(otp, at, at + 6, 40, <String>['code'], maxLineGap: 1),
        isTrue,
      );
    });

    test('a cue after the number is measured the same way', () {
      const String otp = '295183 is your verification code';
      expect(
        TextCues.anyNear(otp, 0, 6, 40, <String>['code'], maxLineGap: 1),
        isTrue,
      );
    });
  });

  test('an empty cue never matches', () {
    expect(TextCues.has('anything at all', ''), isFalse);
    expect(TextCues.has('anything at all', '*'), isFalse);
  });
}
