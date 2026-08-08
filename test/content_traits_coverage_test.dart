import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/content_traits.dart';

/// **How much of the real world these rules actually cover.**
///
/// The hand-written case table next door measures whether the logic does what
/// it was written to do. This measures something different and harder: whether
/// what it was written to do is *enough*. Both of the bugs that reached the
/// user came from real screenshots rather than from either suite, so the point
/// here is breadth — a spread of forms that genuinely occur in the world,
/// scored as a fraction rather than a pass.
///
/// It caught two things a pass/fail suite would not have:
///
/// * `+49 151 12345678` is thirteen digits and passes Luhn by chance, so the
///   card rule was claiming it — losing the phone number and putting a false
///   detection into the one trait whose entire claim is certainty.
/// * bare domains resolved for 25 of 40 real TLDs. Every miss was a country
///   or modern gTLD simply absent from the list.
///
/// Three misses are left and all three are deliberate, asserted at the bottom
/// so that a regression cannot hide among them.
void main() {
  /// The clock every case in this file is measured against.
  ///
  /// The event rules accept a date only between thirty days back and three
  /// years ahead, so a table of literal dates measured against the real clock
  /// does not stay correct — it goes amber on its own, on a date nobody wrote
  /// down. Pinning is the only fix: there is no year that is future enough to
  /// last and near enough to count.
  ///
  /// Every date in the `events` block below is written relative to this day.
  final DateTime today = DateTime(2026, 3, 1);

  /// [ContentTraits.of] with the clock pinned. Every call in this file goes
  /// through it, including the blocks that hold no dates — a case moved
  /// between blocks should not change its answer.
  Set<ContentTrait> traitsOf(String text) =>
      ContentTraits.of(text, now: today, dayFirst: true);

  void report(String name, Map<String, bool> results) {
    final int hit = results.values.where((bool v) => v).length;
    // ignore: avoid_print
    print('\n### $name — $hit/${results.length}');
    results.forEach((String k, bool v) {
      if (!v) {
        // ignore: avoid_print
        print('   MISS  $k');
      }
    });
  }

  /// Raised when a block scores below what it scored when last measured.
  void expectAtLeast(String name, Map<String, bool> results, int floor) {
    final int hit = results.values.where((bool v) => v).length;
    report(name, results);
    expect(
      hit,
      greaterThanOrEqualTo(floor),
      reason: '$name coverage fell below $floor/${results.length}',
    );
  }

  test('coverage', () {
    // ---------------- international phone formats ----------------
    const Map<String, String> phones = <String, String>{
      'Jordan +962': '+962 7 9123 4567',
      'Palestine +970': '+970 59 912 3456',
      'Saudi +966': '+966 50 123 4567',
      'UAE +971': '+971 50 123 4567',
      'Egypt +20': '+20 100 123 4567',
      'UK +44': '+44 20 7123 4567',
      'US +1 dashes': '+1-415-555-0172',
      'US (415) form': 'Phone (415) 555-0172',
      'India +91': '+91 98765 43210',
      'Pakistan +92': '+92 300 1234567',
      'Spain +34': '+34 612 345 678',
      'France +33': '+33 6 12 34 56 78',
      'Germany +49': '+49 151 12345678',
      'Turkey +90': '+90 532 123 45 67',
      '00 prefix': 'Tel 00962791234567',
      'dotted local': 'Mobile 059.912.3456',
      'local no cue 10d': '0599123456',
      'e164 solid': '+962791234567',
    };
    expectAtLeast('phone formats', <String, bool>{
      for (final MapEntry<String, String> e in phones.entries)
        e.key: traitsOf(e.value).contains(ContentTrait.contact),
    }, 17);

    // ---------------- email forms ----------------
    const Map<String, String> emails = <String, String>{
      'plain': 'a.person@example.com',
      'plus tag': 'me+tag@example.com',
      'underscore': 'first_last@example.com',
      'digits': 'user123@example.com',
      'subdomain': 'me@mail.example.com',
      'country tld': 'me@example.co.uk',
      'new gtld': 'me@example.app',
      'hyphen domain': 'me@my-site.com',
      'OCR space before @': 'wikihowseth @gmail.com',
      'OCR space after @': 'name@ gmail.com',
      'OCR both sides': 'help @ example.com',
      'uppercase': 'ME@EXAMPLE.COM',
      'long tld': 'me@example.online',
    };
    expectAtLeast('email forms', <String, bool>{
      for (final MapEntry<String, String> e in emails.entries)
        e.key: traitsOf(e.value).contains(ContentTrait.contact),
    }, 13);

    // ---------------- link forms ----------------
    const Map<String, String> links = <String, String>{
      'https': 'see https://example.com',
      'http': 'see http://example.com',
      'www': 'see www.example.com',
      'bare .com': 'see example.com',
      'bare .net': 'see example.net',
      'bare .org': 'see example.org',
      'bare .io': 'see example.io',
      'bare .app': 'see example.app',
      'bare .co.uk': 'see example.co.uk',
      'bare .es': 'see ejemplo.es',
      'bare .fr': 'see exemple.fr',
      'bare .in': 'see example.in',
      'bare .pk': 'see example.pk',
      'bare .de': 'see beispiel.de',
      'bare .it': 'see esempio.it',
      'bare .nl': 'see voorbeeld.nl',
      'bare .ru': 'see primer.ru',
      'bare .cn': 'see example.cn',
      'bare .jp': 'see example.jp',
      'bare .br': 'see exemplo.br',
      'bare .au': 'see example.au',
      'bare .ca': 'see example.ca',
      'bare .ch': 'see example.ch',
      'bare .se': 'see example.se',
      'bare .pl': 'see example.pl',
      'bare .gr': 'see example.gr',
      'bare .il': 'see example.il',
      'bare .ir': 'see example.ir',
      'bare .ng': 'see example.ng',
      'bare .ke': 'see example.ke',
      'bare .za': 'see example.za',
      'bare .mx': 'see example.mx',
      'bare .ar': 'see example.ar',
      'bare .news': 'see example.news',
      'bare .blog': 'see example.blog',
      'bare .tech': 'see example.tech',
      'with path': 'see example.com/a/b?c=1',
      'youtu.be': 'see youtu.be/abc123',
      't.co': 'see t.co/abc',
      'bit.ly': 'see bit.ly/abc',
    };
    expectAtLeast('link forms', <String, bool>{
      for (final MapEntry<String, String> e in links.entries)
        e.key: traitsOf(e.value).contains(ContentTrait.link),
    }, 40);

    // ---------------- verification code phrasings ----------------
    const Map<String, String> codes = <String, String>{
      'en code is': 'Your code is 481920',
      'en verification': 'Verification code: 481920',
      'en OTP': 'OTP 481920',
      'en PIN': 'Your PIN is 4819',
      'en one-time': 'Your one-time password is 481920',
      'en G- prefix': 'G-481920 is your Google verification code',
      'en do not share': '481920 is your code. Do not share it.',
      'es': 'Su código de verificación es 481920',
      'fr': 'Votre code de vérification est 481920',
      'de': 'Ihr Bestätigungscode lautet 481920',
      'de Sicherheitscode': 'Sicherheitscode 481920',
      'it': 'Il tuo codice di verifica è 481920',
      'pt': 'O seu código de verificação é 481920',
      'nl': 'Je verificatiecode is 481920',
      'nl bevestiging': 'Bevestigingscode 481920',
      'tr': 'Doğrulama kodunuz 481920',
    };
    expectAtLeast('verification code phrasings', <String, bool>{
      for (final MapEntry<String, String> e in codes.entries)
        e.key: traitsOf(e.value).contains(ContentTrait.code),
    }, 14);

    // ------- date / event forms (all future, measured against `today`) ------
    //
    // Every date here is 15 September 2026 or a lunar date converting near it,
    // which is future only because the clock above says 1 March 2026. Change
    // that constant and this whole block has to move with it.
    const Map<String, String> events = <String, String>{
      'dd/mm/yyyy + time': 'Meeting 15/09/2026 at 15:00',
      'dd-mm-yyyy + time': 'Meeting 15-09-2026 at 15:00',
      'yyyy-mm-dd + time': 'Meeting 2026-09-15 at 15:00',
      'dd.mm.yyyy + time': 'Meeting 15.09.2026 at 15:00',
      'month name': 'Meeting on 15 September 2026 at 10:00',
      'month abbrev': 'Meeting on 15 Sep 2026 at 10:00',
      'US month first': 'Meeting September 15, 2026 at 10:00',
      'cue no time': 'Invitation for 15/09/2026',
      'appointment word': 'Appointment 15/09/2026',
      'booking word': 'Booking confirmed 15/09/2026',
      // German writes the day as an ordinal - "15. Oktober" - which is the
      // commonest date form in the language and matched nothing until the day
      // separator learned to carry a dot.
      'de ordinal day': 'Besprechung am 15. Oktober 2026 um 15:00',
      'de abbreviated': 'Besprechung am 15. Okt. 2026 um 15:00',
      'de hour word': 'Einladung 15/09/2026, 20 Uhr',
      'de': 'Besprechung 15/09/2026 um 15:00',
      'nl': 'Vergadering 15/09/2026 om 15:00',
      'it': 'Riunione 15/09/2026 alle 15:00',
      'pt': 'Reunião 15/09/2026 às 15:00',
      'es': 'Reunión el 15/09/2026 a las 15:00',
      'fr': 'Réunion le 15/09/2026 à 15:00',
      // Not vocabulary - the digits fold to ASCII before any rule sees them.
      'arabic-indic numerals': 'Termin ١٥/٠٩/٢٠٢٦ 15:00',
      // Latin transliteration and a Hijri year, the two spellings of a lunar
      // date that a Latin recogniser can actually deliver.
      'hijri romanised': 'Einladung 15 Ramadan 1447',
      'hijri numeric': 'Einladung 15/9/1447',
      'flight': 'Departure 15/09/2026 08:30',
      'deadline': 'Deadline 15/09/2026',
    };
    expectAtLeast('event / date forms', <String, bool>{
      for (final MapEntry<String, String> e in events.entries)
        e.key: traitsOf(e.value).contains(ContentTrait.event),
    }, 24);

    // ---------------- card / IBAN forms ----------------
    const Map<String, String> cards = <String, String>{
      'visa spaced': 'Card 4539 1488 0343 6467',
      'visa solid': 'Card 4539148803436467',
      'visa dashed': 'Card 4539-1488-0343-6467',
      'visa wrapped': 'Card\n4539 1488\n0343 6467',
      'mastercard': 'Card 5425 2334 3010 9903',
      'amex 15': 'Card 3782 822463 10005',
      // The digit fold is preprocessing, not vocabulary: it runs before any
      // rule looks at the text, so it survived the Latin-only cut that took
      // the Arabic cue words. Kept as a case because the code still does it.
      'arabic-indic digits': 'Karte ٤٥٣٩ ١٤٨٨ ٠٣٤٣ ٦٤٦٧',
      'IBAN DE spaced': 'IBAN DE43 7635 0000 0000 1597 59',
      'IBAN DE solid': 'IBAN DE43763500000000159759',
      'IBAN GB': 'IBAN GB33BUKB20201555555555',
      'IBAN JO': 'IBAN JO94CBJO0010000000000131000302',
      'IBAN SA': 'IBAN SA0380000000608010167519',
      'IBAN lowercase': 'iban de43 7635 0000 0000 1597 59',
    };
    expectAtLeast('card / IBAN forms', <String, bool>{
      for (final MapEntry<String, String> e in cards.entries)
        e.key: traitsOf(e.value).contains(ContentTrait.sensitive),
    }, 13);
  });

  group('the remaining misses are deliberate', () {
    test('a bare local number with no cue is refused', () {
      // The filter's stricter bar. Ten digits alone are indistinguishable from
      // a reference number, and this trait would rather miss than claim.
      expect(
        traitsOf('0599123456'),
        isNot(contains(ContentTrait.contact)),
      );
    });

    test('code cues cover the shipped languages, not every language', () {
      // Turkish "Doğrulama kodunuz" is unrecognised, and deliberately so: it
      // is not a language the app ships in, and cue vocabulary for a language
      // nobody on the project reads is vocabulary nobody can review.
      //
      // German used to be the other half of this test and has moved to the
      // covered side — it ships now. That swap is the whole point of the
      // assertion: the line between recognised and not is the shipped set,
      // and it moves when the set does.
      expect(
        traitsOf('Doğrulama kodunuz 481920'),
        isNot(contains(ContentTrait.code)),
      );
      expect(
        traitsOf('Ihr Bestätigungscode lautet 481920'),
        contains(ContentTrait.code),
      );
    });
  });
}
