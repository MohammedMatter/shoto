import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/features/smart_actions/data/services/action_extractor.dart';
import 'package:shoto/features/smart_actions/domain/entities/detected_action.dart';

void main() {
  List<DetectedAction> of(String text, DetectedActionKind kind) {
    return ActionExtractor.extract(
      text,
    ).where((action) => action.kind == kind).toList();
  }

  List<String> valuesOf(String text, DetectedActionKind kind) {
    return of(text, kind).map((action) => action.value).toList();
  }

  group('phone numbers', () {
    test('international format with separators', () {
      expect(
        valuesOf('Call us on +962 7 9123 4567', DetectedActionKind.phone),
        ['+962791234567'],
      );
    });

    test('local number in brackets', () {
      expect(valuesOf('Support (06) 465-1234', DetectedActionKind.phone), [
        '064651234',
      ]);
    });

    test('Arabic-Indic digits are understood', () {
      // An Arabic phone UI renders the number in Arabic-Indic numerals; a
      // plain \d pattern would see nothing at all here.
      expect(valuesOf('اتصل على ٠٧٩١٢٣٤٥٦٧', DetectedActionKind.phone), [
        '0791234567',
      ]);
    });

    test('a date is not a phone number', () {
      expect(of('Due 12/05/2024', DetectedActionKind.phone), isEmpty);
      expect(of('Issued 12-05-2024', DetectedActionKind.phone), isEmpty);
    });

    test('short numbers and prices are ignored', () {
      expect(of('Total 45.90', DetectedActionKind.phone), isEmpty);
      expect(of('Order #4482', DetectedActionKind.phone), isEmpty);
      expect(of('Year 2024', DetectedActionKind.phone), isEmpty);
    });
  });

  group('emails and links', () {
    test('plain email', () {
      expect(
        valuesOf('Write to Sales@Shoto.App today', DetectedActionKind.email),
        ['sales@shoto.app'],
      );
    });

    test('an email is not also reported as a link', () {
      // "shoto.app" inside the address matches the bare-domain rule too;
      // whichever pattern claims the text first must exclude the other.
      const String text = 'contact me at hello@shoto.app';
      expect(of(text, DetectedActionKind.email), hasLength(1));
      expect(of(text, DetectedActionKind.link), isEmpty);
    });

    test('full url keeps its scheme and path', () {
      expect(
        valuesOf(
          'Read https://example.com/a/b?x=1 now',
          DetectedActionKind.link,
        ),
        ['https://example.com/a/b?x=1'],
      );
    });

    test('bare domain gets a scheme added', () {
      expect(valuesOf('visit shoto.app', DetectedActionKind.link), [
        'https://shoto.app',
      ]);
    });

    test('trailing sentence punctuation is dropped', () {
      expect(valuesOf('See www.example.com.', DetectedActionKind.link), [
        'https://www.example.com',
      ]);
    });

    test('version numbers and abbreviations are not links', () {
      expect(of('Updated to 2.5.1 today', DetectedActionKind.link), isEmpty);
      expect(of('sizes S.M.L available', DetectedActionKind.link), isEmpty);
    });
  });

  group('verification codes', () {
    test('needs a cue word to count', () {
      expect(valuesOf('Your code is 483920', DetectedActionKind.code), [
        '483920',
      ]);
      expect(valuesOf('رمز التحقق 4821', DetectedActionKind.code), ['4821']);
    });

    test('a bare number with no cue is not a code', () {
      expect(of('Room 4821 on floor 3', DetectedActionKind.code), isEmpty);
    });

    test('cue may follow the number', () {
      expect(
        valuesOf('295183 is your verification code', DetectedActionKind.code),
        ['295183'],
      );
    });
  });

  group('IBAN', () {
    test('accepts a checksum-valid IBAN', () {
      expect(
        valuesOf(
          'Transfer to GB82 WEST 1234 5698 7654 32',
          DetectedActionKind.iban,
        ),
        ['GB82WEST12345698765432'],
      );
    });

    test('rejects one that is merely IBAN-shaped', () {
      // Same layout, one digit changed — the mod-97 check is the only thing
      // standing between this and a button that copies wrong bank details.
      expect(
        of('Ref GB82WEST12345698765433', DetectedActionKind.iban),
        isEmpty,
      );
    });

    test('rejects ordinary reference numbers', () {
      expect(of('Tracking AB12345678901234', DetectedActionKind.iban), isEmpty);
    });

    test('display is grouped in fours for readability', () {
      final DetectedAction iban = of(
        'GB82WEST12345698765432',
        DetectedActionKind.iban,
      ).single;
      expect(iban.display, 'GB82 WEST 1234 5698 7654 32');
    });
  });

  group('whole-screenshot behaviour', () {
    test('a realistic receipt yields exactly the useful bits', () {
      const String text = '''
        Shoto Store
        Order #4482 · 12/05/2024
        Questions? support@shoto.app or call +962 6 465 1234
        Track it at shoto.app/orders
        Total 45.90 JOD
      ''';

      final List<DetectedAction> actions = ActionExtractor.extract(text);

      expect(valuesOf(text, DetectedActionKind.email), ['support@shoto.app']);
      expect(valuesOf(text, DetectedActionKind.phone), ['+96264651234']);
      expect(valuesOf(text, DetectedActionKind.link), [
        'https://shoto.app/orders',
      ]);
      // The order number, the date and the total must not become actions.
      expect(actions, hasLength(3));
    });

    test('empty and trivial text yields nothing', () {
      expect(ActionExtractor.extract(''), isEmpty);
      expect(ActionExtractor.extract('hi'), isEmpty);
      expect(ActionExtractor.extract('just some ordinary words here'), isEmpty);
    });

    test('duplicates collapse to one action', () {
      const String text = 'call 0791234567 or 079 123 4567';
      expect(of(text, DetectedActionKind.phone), hasLength(1));
    });

    test('results are capped', () {
      final String text = List.generate(
        30,
        (i) => 'user$i@example.com',
      ).join(' ');
      expect(ActionExtractor.extract(text).length, ActionExtractor.maxActions);
    });
  });
}
