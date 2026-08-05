import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/content_traits.dart';

/// One row of the filter's behaviour, stated as an expectation.
///
/// Either [want] — this text must carry the trait — or [not] — it must not.
class _Case {
  final String label;
  final String text;
  final ContentTrait? want;
  final ContentTrait? not;
  const _Case(this.label, this.text, {this.want, this.not});
}

/// **Every case the library's content filters are expected to get right.**
///
/// Written as one table rather than scattered tests because the failures that
/// actually reached the user were never in the logic — they were in the gap
/// between what the code assumed OCR returns and what it does return. A space
/// beside an `@`, a card wrapped onto a second line, a heading three lines
/// above a number. Those only surface when the cases sit side by side and are
/// read as a list.
///
/// Each entry that begins "NOT" is a false positive somebody would have to
/// live with, and several of them are transcriptions of real screenshots from
/// the test device.

const List<_Case> _cases = <_Case>[
  // ---------------- SENSITIVE (checksum-backed) ----------------
  _Case(
    'card spaced',
    'Paid with 4539 1488 0343 6467 today',
    want: ContentTrait.sensitive,
  ),
  _Case(
    'card dashed',
    'Card 4539-1488-0343-6467 exp 04/27',
    want: ContentTrait.sensitive,
  ),
  _Case(
    'card solid',
    'Card 4539148803436467 exp',
    want: ContentTrait.sensitive,
  ),
  _Case(
    'card across lines (OCR)',
    'Card number\n4539 1488\n0343 6467\nexp',
    want: ContentTrait.sensitive,
  ),
  _Case(
    'card arabic digits',
    'البطاقة ٤٥٣٩ ١٤٨٨ ٠٣٤٣ ٦٤٦٧',
    want: ContentTrait.sensitive,
  ),
  _Case(
    'IBAN spaced',
    'IBAN DE43 7635 0000 0000 1597 59 bank',
    want: ContentTrait.sensitive,
  ),
  _Case(
    'IBAN solid',
    'IBAN DE43763500000000159759 bank',
    want: ContentTrait.sensitive,
  ),
  _Case(
    'IBAN lowercase',
    'iban de43 7635 0000 0000 1597 59',
    want: ContentTrait.sensitive,
  ),
  _Case(
    'NOT card (luhn fail)',
    'Order 1234 5678 9012 3456 shipped',
    not: ContentTrait.sensitive,
  ),
  _Case('NOT card (too short)', 'Ref 4539 1488', not: ContentTrait.sensitive),

  // ---------------- LINK ----------------
  _Case('https', 'go to https://example.com/a', want: ContentTrait.link),
  _Case('www', 'go to www.example.com now', want: ContentTrait.link),
  _Case('bare domain', 'visit example.com today', want: ContentTrait.link),
  _Case('uppercase domain', 'Visit EXAMPLE.COM today', want: ContentTrait.link),
  _Case('trailing dot', 'see example.com.', want: ContentTrait.link),
  _Case('co.uk', 'visit shop.co.uk now', want: ContentTrait.link),
  _Case('arabic + link', 'زوروا example.com اليوم', want: ContentTrait.link),
  _Case('spanish tld', 'visita ejemplo.es hoy', want: ContentTrait.link),
  _Case(
    'OCR space after scheme',
    'open https:// example.com now',
    want: ContentTrait.link,
  ),
  _Case('NOT version', 'app version 2.5.1 released', not: ContentTrait.link),
  _Case('NOT decimal', 'total 45.90 paid', not: ContentTrait.link),

  // ---------------- CONTACT: email ----------------
  _Case('email plain', 'write to sales@shoto.app', want: ContentTrait.contact),
  _Case('email spaced @', 'wikihowseth @gmail.com', want: ContentTrait.contact),
  _Case('email space after @', 'name@ gmail.com', want: ContentTrait.contact),
  _Case('email both spaces', 'help @ example.com', want: ContentTrait.contact),
  _Case(
    'email uppercase',
    'Write To SALES@SHOTO.APP',
    want: ContentTrait.contact,
  ),
  _Case('email plus tag', 'me+news@example.com', want: ContentTrait.contact),
  _Case('email subdomain', 'a@mail.example.co', want: ContentTrait.contact),
  _Case(
    'email dotted local',
    'first.last@example.com',
    want: ContentTrait.contact,
  ),
  _Case(
    'NOT email across lines',
    'username\n@\nexample.com',
    not: ContentTrait.contact,
  ),
  _Case(
    'NOT sentence @',
    'meet me @ home.com later',
    not: ContentTrait.contact,
  ),
  _Case('NOT page @', 'see page 3 @ site.com', not: ContentTrait.contact),

  // ---------------- CONTACT: phone ----------------
  _Case('phone +country', 'call +962 7 9123 4567', want: ContentTrait.contact),
  _Case('phone cue en', 'Mobile 0599123456', want: ContentTrait.contact),
  _Case('phone cue ar', 'جوال 0599123456', want: ContentTrait.contact),
  _Case('phone arabic digits', 'هاتف ٠٥٩٩١٢٣٤٥٦', want: ContentTrait.contact),
  _Case('phone urdu digits', 'فون ۰۵۹۹۱۲۳۴۵۶', want: ContentTrait.contact),
  _Case(
    'phone brackets + cue',
    'Tel (06) 465-1234',
    want: ContentTrait.contact,
  ),
  _Case(
    'NOT bare digits',
    'Your order 1234565 shipped',
    not: ContentTrait.contact,
  ),
  _Case(
    'NOT ref 4-4-4',
    'Reference 9923-7290-4590 kept',
    not: ContentTrait.contact,
  ),
  _Case(
    'NOT welded letters',
    'BBAN ABNA0417164300 code',
    not: ContentTrait.contact,
  ),
  _Case(
    'NOT hotel substring',
    'The hotel booking 5551234',
    not: ContentTrait.contact,
  ),
  _Case('NOT date', 'Due 12/05/2024 please', not: ContentTrait.contact),

  // ---------------- CODE ----------------
  _Case(
    'code en before',
    'Your verification code is 481920',
    want: ContentTrait.code,
  ),
  _Case(
    'code en after',
    '295183 is your verification code',
    want: ContentTrait.code,
  ),
  _Case(
    'code newline',
    'Your verification code is\n481920',
    want: ContentTrait.code,
  ),
  _Case('code ar', 'رمز التحقق الخاص بك هو ٤٨١٩٢٠', want: ContentTrait.code),
  _Case(
    'code es',
    'Su código de verificación es 481920',
    want: ContentTrait.code,
  ),
  _Case(
    'code fr',
    'Votre code de vérification est 481920',
    want: ContentTrait.code,
  ),
  _Case('code hi', 'आपका सत्यापन कोड 481920 है', want: ContentTrait.code),
  _Case('code ur', 'آپ کا تصدیقی کوڈ 481920 ہے', want: ContentTrait.code),
  _Case('code OTP word', 'OTP 4821 valid 5 min', want: ContentTrait.code),
  _Case(
    'NOT barcode page',
    'country mfg code\nUPC-A\nC5 google\n012345 678905\nInterleaved',
    not: ContentTrait.code,
  ),
  _Case('NOT bare number', 'Total was 4820 shekels', not: ContentTrait.code),
  _Case('NOT room number', 'Room 4821 on floor 3', not: ContentTrait.code),
  _Case(
    'NOT shipping pin',
    'Your shipping 4821 is out',
    not: ContentTrait.code,
  ),

  // ---------------- EVENT ----------------
  _Case(
    'event numeric+time',
    'Meeting on 15/09/2026 at 3:00 PM',
    want: ContentTrait.event,
  ),
  _Case(
    'event month name',
    'Conference on 15 September 2026 at 10:00',
    want: ContentTrait.event,
  ),
  _Case(
    'event cue ar',
    'موعد الاجتماع ١٥/٠٩/٢٠٢٦ الساعة ٣:٠٠',
    want: ContentTrait.event,
  ),
  _Case(
    'event cue es',
    'Reunión el 15/09/2026 a las 15:00',
    want: ContentTrait.event,
  ),
  _Case(
    'event cue fr',
    'Réunion le 15/09/2026 à 15:00',
    want: ContentTrait.event,
  ),
  _Case(
    'event cue hi',
    'बैठक 15/09/2026 को 3:00 बजे',
    want: ContentTrait.event,
  ),
  _Case(
    'event cue ur',
    'ملاقات 15/09/2026 کو 3:00 بجے',
    want: ContentTrait.event,
  ),
  _Case(
    'event invitation word',
    'Invitation\nWedding on 15/09/2026',
    want: ContentTrait.event,
  ),
  _Case(
    'NOT past date',
    'Invoice issued 10/03/2023 paid',
    not: ContentTrait.event,
  ),
  _Case('NOT far future', 'Card expires 12/2032', not: ContentTrait.event),
  _Case(
    'NOT eventually',
    'It eventually arrived 15/09/2026',
    not: ContentTrait.event,
  ),
];

void main() {
  for (final _Case c in _cases) {
    test(c.label, () {
      final Set<ContentTrait> got = ContentTraits.of(c.text);
      final String detail =
          'got {${got.map((ContentTrait t) => t.name).join(", ")}}';
      if (c.want != null) {
        expect(got, contains(c.want), reason: detail);
      } else {
        expect(got, isNot(contains(c.not)), reason: detail);
      }
    });
  }

  test('the table covers every trait in both directions', () {
    // A trait added later with no row here would leave the suite looking as
    // thorough as it does now while testing nothing about it.
    for (final ContentTrait trait in ContentTrait.values) {
      expect(
        _cases.any((_Case c) => c.want == trait),
        isTrue,
        reason: 'no positive case for ${trait.name}',
      );
      expect(
        _cases.any((_Case c) => c.not == trait),
        isTrue,
        reason: 'no negative case for ${trait.name}',
      );
    }
  });
}
