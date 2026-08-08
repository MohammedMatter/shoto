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

  group('a cue that begins or ends with an accented letter', () {
    // The reason this file cannot be simplified to `\b`, pinned as a test
    // because the failure it prevents is invisible: Dart's word class is
    // ASCII-only, so `\bévénement\b` finds no boundary to anchor to and
    // matches nothing in any text at all. `événement` is a live entry in
    // EventExtractor's cue list.
    test('is matched here', () {
      expect(TextCues.has('un événement demain', 'événement'), isTrue);
      expect(TextCues.has('la réunion demain', 'réunion'), isTrue);
      expect(TextCues.has('einladung am 12. märz', 'märz'), isTrue);
    });

    test('is still held to whole words', () {
      // The accent buys no exemption from the rule the file exists for.
      expect(TextCues.has('événements', 'événement'), isFalse);
      expect(TextCues.has('réunions', 'réunion'), isFalse);
    });

    test('is exactly what a naive word boundary would drop', () {
      // Partial and quiet: only the *ends* of the cue matter, so a `\b`
      // rewrite passes for réunion and märz and silently loses événement.
      bool boundary(String cue, String hay) =>
          RegExp('\\b$cue\\b', caseSensitive: false).hasMatch(hay);

      expect(boundary('réunion', 'la réunion demain'), isTrue);
      expect(boundary('märz', 'einladung am 12. märz'), isTrue);
      expect(boundary('événement', 'un événement demain'), isFalse);
    });
  });
}
