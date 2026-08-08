import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/features/smart_actions/data/services/action_extractor.dart';
import 'package:shoto/features/smart_actions/domain/entities/action_details.dart';
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

  /// **No bare run of digits may become an action.**
  ///
  /// There was a phone rule here once, guarded six ways, and it still read a
  /// screenshot of a table of IBANs as three numbers to dial — the actions
  /// sheet offered Call, WhatsApp and Message on every one of them. The text
  /// below is what the recogniser actually returned from that screenshot, kept
  /// verbatim so the case cannot come back by accident.
  ///
  /// These tests assert an *absence*, which is unusual and deliberate. They
  /// are the executable form of the rule in [ActionExtractor]'s header: a
  /// digit run carries nothing that distinguishes a phone number from an
  /// account number, so anything that reintroduces one will fail here first.
  group('bare numbers never become actions', () {
    const String ibanTable = '''
      123 user_id      ABC iban
      1   GBFD 5531-5100-6718
      2   GBFD 8629-9487-4145
      10  GBFD 3698-5387-302
      IBAN Generator | Knowledge Center
      Eingabe BLZ            76350000
      Eingabe Konto Nr.      159759
      IBAN nach Bestandteilen  DE 43 76350000 0000159759
    ''';

    test('a table of account numbers yields no dialable action', () {
      final List<DetectedAction> actions = ActionExtractor.extract(ibanTable);
      // Nothing here is a link, an address or a checksum-valid IBAN, so the
      // only honest answer is that there is nothing to offer.
      expect(
        actions.where((a) => a.kind != DetectedActionKind.iban),
        isEmpty,
        reason: 'a numbers table produced actions: $actions',
      );
    });

    test('a grouped reference is not chopped into verification codes', () {
      // The second failure on the same screenshot, found only by re-running
      // the fix on the device: with the phone rule gone, `8629` and `9487`
      // came back as codes, cut out of `GBFD 8629-9487-4145` and vouched for
      // by the words "country code" a few characters away.
      expect(
        ActionExtractor.extract(ibanTable)
            .where((a) => a.kind == DetectedActionKind.code),
        isEmpty,
      );
      expect(
        ActionExtractor.extract('Country code\nGBFD 8629-9487-4145'),
        isEmpty,
      );
    });

    test('a real verification code is still one group and still found', () {
      expect(
        valuesOf('Your verification code is 481920', DetectedActionKind.code),
        ['481920'],
      );
    });

    test('a number that reads like a phone is still not an action', () {
      // Every one of these passed the old rule. None of them is offered now,
      // and the reason is that no rule can tell them from the ones above.
      for (final String text in <String>[
        'Call us on +962 7 9123 4567',
        'Support (06) 465-1234',
        'Anruf unter 0791234567',
        'Meter reading 0000 1597 54',
      ]) {
        expect(
          ActionExtractor.extract(text),
          isEmpty,
          reason: '"$text" produced an action',
        );
      }
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
      // A cue from one of the other shipped languages counts the same. This
      // was an Arabic phrasing until Arabic stopped shipping — the recogniser
      // has no model for that script, so the assertion was green over
      // something no screenshot could ever produce.
      expect(valuesOf('Sicherheitscode 4821', DetectedActionKind.code), [
        '4821',
      ]);
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
      expect(valuesOf(text, DetectedActionKind.link), [
        'https://shoto.app/orders',
      ]);
      // The order number, the date, the total and the support number must
      // not become actions.
      expect(actions, hasLength(2));
    });

    test('empty and trivial text yields nothing', () {
      expect(ActionExtractor.extract(''), isEmpty);
      expect(ActionExtractor.extract('hi'), isEmpty);
      expect(ActionExtractor.extract('just some ordinary words here'), isEmpty);
    });

    test('duplicates collapse to one action', () {
      const String text = 'write to sales@shoto.app or Sales@Shoto.App';
      expect(of(text, DetectedActionKind.email), hasLength(1));
    });

    test('results are capped', () {
      final String text = List.generate(
        30,
        (i) => 'user$i@example.com',
      ).join(' ');
      expect(ActionExtractor.extract(text).length, ActionExtractor.maxActions);
    });
  });

  // -------------------------------------------------------------------
  // Intents
  // -------------------------------------------------------------------

  // Every event test pins the clock, because the single strongest rule in the
  // detector is "the past is not an event" — and a test whose expectations
  // expire is worse than no test.
  final DateTime today = DateTime(2026, 3, 1);

  List<DetectedAction> eventsIn(String text, {bool dayFirst = true}) {
    return ActionExtractor.extract(text, now: today, dayFirst: dayFirst)
        .where((action) => action.kind == DetectedActionKind.event)
        .toList();
  }

  EventDetails firstEvent(String text, {bool dayFirst = true}) {
    return eventsIn(text, dayFirst: dayFirst).single.details! as EventDetails;
  }

  group('events', () {
    test('a numeric date with a time becomes an appointment', () {
      final EventDetails event = firstEvent(
        'Team sync\nMeeting on 12/05/2026 at 3:00 PM',
      );
      expect(event.start, DateTime(2026, 5, 12, 15, 0));
      expect(event.allDay, isFalse);
      // The heading above the date, not the line the date sits on.
      expect(event.title, 'Team sync');
    });

    test('a date already past is not an appointment', () {
      // January is behind the pinned clock; the same text a year later would
      // be a perfectly good event, which is the whole point of the rule.
      expect(eventsIn('Meeting on 12/01/2026 at 3:00 PM'), isEmpty);
    });

    test('an invitation screenshotted last week still counts', () {
      // Photographing a card and opening it a few days later is a real
      // pattern, and rejecting the whole past lost it.
      final EventDetails event = firstEvent(
        'Einladung zur Hochzeit\n20/02/2026',
      );
      expect(event.start, DateTime(2026, 2, 20));
    });

    test('a chat header from last week does not', () {
      // The exact case the recent-past window would otherwise let in: a date
      // and a time and nothing calling it an occasion. A clock time earns a
      // future date its row and earns a past one nothing at all.
      expect(eventsIn('20/02/2026 3:42 PM\nsee you'), isEmpty);
    });

    test('an occasion older than the window is a record, not a plan', () {
      expect(eventsIn('Einladung zur Hochzeit\n09/11/2024'), isEmpty);
    });
    test('a bare future date with no time and no cue is left alone', () {
      expect(eventsIn('Total 240.00\n12/05/2026'), isEmpty);
    });

    test('a cue makes a bare future date an all-day event', () {
      final EventDetails event = firstEvent('Invitation\n12/05/2026');
      expect(event.start, DateTime(2026, 5, 12));
      expect(event.allDay, isTrue);
    });

    test('the region decides an ambiguous numeric date', () {
      expect(
        firstEvent('Appointment 05/12/2026', dayFirst: true).start,
        DateTime(2026, 12, 5),
      );
      expect(
        firstEvent('Appointment 05/12/2026', dayFirst: false).start,
        DateTime(2026, 5, 12),
      );
    });

    test('a day past twelve settles the order without the region', () {
      // 25 cannot be a month, so both conventions have to agree.
      for (final bool dayFirst in <bool>[true, false]) {
        expect(
          firstEvent('Appointment 25/03/2027', dayFirst: dayFirst).start,
          DateTime(2027, 3, 25),
        );
      }
    });

    test('a month name is read, and a range gives the finish time', () {
      final EventDetails event = firstEvent(
        'Design review\nMay 20 2026, 2:00 PM - 3:30 PM',
      );
      expect(event.start, DateTime(2026, 5, 20, 14, 0));
      expect(event.end, DateTime(2026, 5, 20, 15, 30));
    });

    test('a year-less date resolves to the next time it comes round', () {
      final EventDetails event = firstEvent('Interview on 20 June at 09:30');
      expect(event.start, DateTime(2026, 6, 20, 9, 30));
    });

    test('a month name from a new market is a month, accent or not', () {
      // The four languages that replaced ar/ur/hi brought their own month
      // names, and recognition drops a diacritic often enough that every
      // spelling of March has to resolve to the same day.
      for (final String month in <String>['März', 'Maerz', 'Mrz']) {
        final EventDetails event = firstEvent('Einladung\n12 $month 2026');
        expect(event.start, DateTime(2026, 3, 12), reason: month);
        expect(event.allDay, isTrue, reason: month);
      }
    });

    test('Dutch, Italian and Portuguese months resolve too', () {
      expect(
        firstEvent('Uitnodiging\n12 mei 2026').start,
        DateTime(2026, 5, 12),
      );
      expect(
        firstEvent('Invito\n12 giugno 2026').start,
        DateTime(2026, 6, 12),
      );
      expect(
        firstEvent('Convite\n12 outubro 2026').start,
        DateTime(2026, 10, 12),
      );
    });

    test('Arabic-Indic digits are still normalised, the letters are not', () {
      // The digit fold in ActionExtractor survived the Latin-only cut and the
      // Arabic meridiem did not, which is not an inconsistency. A digit is
      // rewritten before any rule sees it and costs nothing when it never
      // arrives; a cue word is a match target, and one that can only ever
      // match text the recogniser cannot produce is dead weight.
      final EventDetails event = firstEvent(
        'Vorstellungsgespräch\n٢٠/٠٥/٢٠٢٦ 15:00',
      );
      expect(event.start, DateTime(2026, 5, 20, 15, 0));
    });

    test('a German invitation says the hour with a word, not a meridiem', () {
      // "20 Uhr" is how a German card writes eight in the evening. Without the
      // marker the time is lost and the event lands as all-day, which is the
      // likeliest shape of a German invitation this feature will ever meet.
      final EventDetails event = firstEvent('Einladung\n12.06.2026, 20 Uhr');
      expect(event.start, DateTime(2026, 6, 12, 20, 0));
      expect(event.allDay, isFalse);
    });

    test('the hour word is a whole word, and does not fold', () {
      // "Uhren" is clocks, not a time; and `Uhr` states the twenty-four-hour
      // reading rather than folding onto it, so 20 stays 20 and does not
      // become thirty-two.
      expect(
        firstEvent('Einladung\n12/06/2026\n12 Uhren stehen hier').allDay,
        isTrue,
      );
      expect(
        firstEvent('Einladung\n12.06.2026, 15:00 Uhr').start,
        DateTime(2026, 6, 12, 15, 0),
      );
    });

    test('a month ending a sentence does not eat the next one', () {
      // The dot that lets "15. Oktober" read as a date is placed between a
      // number and a month name only. Allowing one *after* a month name as
      // well — which an earlier draft of this did — turns the full stop
      // between two sentences into a date separator, and "im Mai. 15 Personen
      // kamen" becomes the fifteenth of May.
      expect(eventsIn('Einladung\nim Mai. 15 Personen kamen'), isEmpty);
    });

    test('a venue label is a whole word, not the end of one', () {
      // `ort` ends Support, Transport, Export, Report and Airport, and every
      // one of them is followed by a colon on a real screen. Without a left
      // edge the support address was being filed as the venue.
      for (final String line in <String>[
        'Support: help@example.com',
        'Transport: DHL Express',
        'Export: CSV Datei',
      ]) {
        expect(
          firstEvent('Einladung\n12/06/2026 20 Uhr\n$line').location,
          isNull,
          reason: line,
        );
      }
      expect(
        firstEvent(
          'Einladung\n12/06/2026 20 Uhr\nOrt: Hauptstrasse 12',
        ).location,
        'Hauptstrasse 12',
      );
    });

    test('decorative type spaces out its separators, and it still reads', () {
      // A printed invitation sets the date in a wide face and recognition
      // comes back with the separators floating: "12 / 5 / 2026", "20 : 00".
      // Both spellings missed entirely until this was allowed for, which is
      // the difference between the feature working on a real wedding card and
      // only on a calendar app's tidy output.
      final EventDetails event = firstEvent(
        'Einladung zur Hochzeit\n12 / 5 / 2026 - 20 : 00',
      );
      expect(event.start, DateTime(2026, 5, 12, 20, 0));
    });

    test('a ratio is not a time', () {
      // Insisting on a two-digit minute is what keeps the spaced colon safe:
      // "3 : 1" has the shape of a clock and none of the meaning.
      final EventDetails event = firstEvent('Invitation 12/05/2026\nOdds 3 : 1');
      expect(event.allDay, isTrue);
    });

    test('a card expiry is not an appointment', () {
      // Two digits, a slash, two digits, no time anywhere near it.
      expect(eventsIn('Visa •••• 4242\nExpires 05/29'), isEmpty);
    });

    test('a version number is not a date', () {
      expect(eventsIn('Updated to 1.2.30 — meeting notes'), isEmpty);
    });

    test('a date inside a URL is a path, not a plan', () {
      expect(
        eventsIn('Invitation https://blog.test/p/12.05.2026/details'),
        isEmpty,
      );
    });

    test('the thirty-first of February is not a date', () {
      expect(eventsIn('Appointment 31/02/2027'), isEmpty);
    });

    test('a date beyond three years is an expiry, not a plan', () {
      expect(eventsIn('Appointment 12/05/2033'), isEmpty);
    });

    test('the event claims its own digits before any later rule sees them', () {
      final List<DetectedAction> actions = ActionExtractor.extract(
        'Meeting on 12/05/2026 at 3:00 PM',
        now: today,
      );
      expect(actions.map((a) => a.kind), everyElement(DetectedActionKind.event));
    });

    test('an event leads the list', () {
      final List<DetectedAction> actions = ActionExtractor.extract(
        'Standup\n12/05/2026 at 9:00 AM\nCall 0791234567',
        now: today,
      );
      expect(actions.first.kind, DetectedActionKind.event);
    });
  });

  group('the Hijri calendar', () {
    // Every expectation below is a published Umm al-Qura date, not a
    // round-trip through the same code that produced it. A conversion test
    // that checks the converter against itself proves nothing.
    //
    // Anchors used: 1 Ramadan 1447 = 18 Feb 2026, 1 Shawwal 1447 (Eid
    // al-Fitr) = 20 Mar 2026, 1 Muharram 1448 = 16 Jun 2026.
    //
    // **Every case here is written in Latin, and that is the point.** The
    // Arabic spellings went with the rest of the unreachable vocabulary; the
    // converter did not, because two ways in survived it. The romanised month
    // names below are Latin text, and `15/9/1447` is nothing but digits and a
    // slash. See `docs/decisions/shipped-languages.md`.
    DateTime hijriStart(String text) => firstEvent(text, dayFirst: true).start;

    test('a wedding card converts to the right day', () {
      // 15 Ramadan 1447 - the fifteenth day of a month beginning 18 Feb.
      expect(hijriStart('Einladung\n15 Ramadan 1447'), DateTime(2026, 3, 4));
    });

    test('the era marker is an optional spelling', () {
      expect(hijriStart('Einladung\n15 Ramadan 1447 AH'), DateTime(2026, 3, 4));
      expect(hijriStart('Einladung\n15 Ramadhan 1447'), DateTime(2026, 3, 4));
    });

    test('the romanisations of one month are the same month', () {
      // There is no standard transliteration, so a card is as likely to say
      // "Rabi I" as "Rabi al-awwal". A table holding one of them silently
      // ignores every card that chose the other.
      // Pinned to a published date rather than to each other. Comparing the
      // spellings only would pass just as happily if every one of them
      // resolved to the same wrong day.
      //
      // 1 Muharram 1448 = 16 Jun 2026, and Muharram (30) plus Safar (29) puts
      // 1 Rabi al-awwal at 14 Aug — so the tenth is 23 Aug 2026.
      for (final String month in <String>[
        'Rabi al-awwal',
        'Rabi al awwal',
        'Rabi ul-awwal',
        'Rabi I',
      ]) {
        expect(
          hijriStart('Einladung\n10 $month 1448'),
          DateTime(2026, 8, 23),
          reason: month,
        );
      }
    });

    test('a digit-only Hijri date needs no era marker to be recognised', () {
      // A four-digit year in the fourteen-hundreds cannot be a Gregorian date
      // this feature would accept, so the year settles it on its own. This is
      // also the one Hijri spelling that needs no vocabulary at all, which is
      // why the converter outlived the Arabic cue words.
      expect(hijriStart('Einladung\n15/9/1447'), DateTime(2026, 3, 4));
    });

    test('a Hijri date carries its time across the conversion', () {
      final EventDetails event = firstEvent(
        'Einladung\n15 Ramadan 1447 - 8:00 PM',
      );
      expect(event.start, DateTime(2026, 3, 4, 20, 0));
      expect(event.allDay, isFalse);
    });

    test('the thirtieth of a twenty-nine-day month is not a date', () {
      // Safar 1447 runs twenty-nine days. Without the length check the
      // conversion rolls quietly into the next month, exactly as DateTime
      // does with the thirty-first of February.
      expect(eventsIn('Einladung\n30/2/1447'), isEmpty);
    });

    test('a Hijri occasion already past is still past', () {
      // 1445 ended in 2024; the calendar it was written in changes nothing
      // about which rules apply after the conversion.
      expect(eventsIn('Einladung\n15 Ramadan 1445'), isEmpty);
    });

    test('a month name without a year is not a date', () {
      // The year is what makes a lone month name safe to act on - "Rajab" is
      // a given name, and a greeting is not an appointment.
      expect(eventsIn('Ramadan Mubarak - Einladung'), isEmpty);
      expect(eventsIn('Betrag 15 Safar 2024'), isEmpty);
    });

    test('a Hijri date still has to say it is an occasion', () {
      // The conversion buys no exemption from the gate every other date
      // passes through.
      expect(eventsIn('Rechnung\n15 Ramadan 1447'), isEmpty);
    });
  });
  group('wi-fi', () {
    WifiDetails firstWifi(String text) =>
        of(text, DetectedActionKind.wifi).single.details! as WifiDetails;

    test('a network name and password are read off a café card', () {
      final WifiDetails wifi = firstWifi(
        'Free WiFi\nNetwork: CafeGuest\nPassword: latte2026',
      );
      expect(wifi.network, 'CafeGuest');
      expect(wifi.password, 'latte2026');
    });

    /// A café card in each shipped language. Every one of these read as
    /// nothing before the language swap: the cue list knew `wi-fi` and
    /// `wireless` in English and Arabic, so a German card saying **WLAN** and
    /// **Passwort** produced no action at all.
    test('a café card is read in every shipped language', () {
      const Map<String, (String, String)> cards = <String, (String, String)>{
        'WLAN\nNetzwerk: CafeGast\nPasswort: latte2026': ('CafeGast', 'latte2026'),
        'Draadloos\nNetwerknaam: CafeGast\nWachtwoord: latte2026':
            ('CafeGast', 'latte2026'),
        'Rete wireless\nNome rete: CafeGast\nChiave: latte2026':
            ('CafeGast', 'latte2026'),
        'Wi-Fi\nNome da rede: CafeGast\nSenha: latte2026':
            ('CafeGast', 'latte2026'),
        'Wi-Fi\nNombre de la red: CafeGast\nContraseña: latte2026':
            ('CafeGast', 'latte2026'),
        'Wi-Fi\nNom du réseau: CafeGast\nMot de passe: latte2026':
            ('CafeGast', 'latte2026'),
      };

      cards.forEach((String text, (String, String) want) {
        final WifiDetails wifi = firstWifi(text);
        expect(wifi.network, want.$1, reason: text);
        expect(wifi.password, want.$2, reason: text);
      });
    });

    test('a password with nothing calling it wireless is not a network key', () {
      // The single most likely false positive in the whole feature.
      expect(of('Your password: hunter2024', DetectedActionKind.wifi), isEmpty);
      // And the same trap in the new languages: a bare login password with no
      // word anywhere calling the connection wireless.
      expect(of('Ihr Passwort: hunter2024', DetectedActionKind.wifi), isEmpty);
      expect(of('Je wachtwoord: hunter2024', DetectedActionKind.wifi), isEmpty);
    });

    test('a sentence about a password is not a password', () {
      expect(
        of('WiFi password required to join', DetectedActionKind.wifi),
        isEmpty,
      );
    });

    test('the QR payload is parsed on its own evidence', () {
      final WifiDetails wifi = firstWifi('WIFI:S:MyNet;T:WPA;P:s3cr3t99;;');
      expect(wifi.network, 'MyNet');
      expect(wifi.password, 's3cr3t99');
    });

    test('a numeric key is not also listed as a verification code', () {
      const String text = 'Guest WiFi\nPassword: 48291733';
      expect(of(text, DetectedActionKind.wifi), hasLength(1));
      expect(of(text, DetectedActionKind.code), isEmpty);
    });

    test('a short label must begin a word', () {
      // Each of these handed the user an invented password: `pass` sits in
      // "Bypass", `key` in "Monkey", `clave` in "Enclave" and `senha` in the
      // Portuguese "Resenha". A colon after them is not evidence of anything.
      for (final String line in <String>[
        'Bypass: latte2026',
        'Monkey: latte2026',
        'Enclave: latte2026',
        'Resenha: latte2026',
      ]) {
        expect(
          of('Free WiFi settings\n$line', DetectedActionKind.wifi),
          isEmpty,
          reason: line,
        );
      }
    });

    test('a long label may sit inside a compound', () {
      // The other half of the same rule, and the half a blind word boundary
      // would break: German and Dutch build the compound around the head
      // word, so "Gastpasswort" is exactly as much a password label as
      // "Passwort" is.
      for (final String line in <String>[
        'Gastpasswort: latte2026',
        'WLAN-Kennwort: latte2026',
        'Netwerksleutel: latte2026',
      ]) {
        expect(
          firstWifi('Freies WLAN\n$line').password,
          'latte2026',
          reason: line,
        );
      }
    });

    test('a network name is held to the same rule', () {
      // `red` is Spanish for network and also ends "Shared", "Hundred" and
      // "Required" — the one this language swap actually introduced.
      final WifiDetails wifi = firstWifi(
        'Free WiFi\nShared: NotANetwork\nPassword: latte2026',
      );
      expect(wifi.password, 'latte2026');
      expect(wifi.network, isNull);

      // Still found when it really is the label.
      expect(
        firstWifi('WiFi gratis\nRed: CafeGuest\nContraseña: latte2026').network,
        'CafeGuest',
      );
      // And still found inside a German compound.
      expect(
        firstWifi(
          'Freies WLAN\nGastnetzwerk: Cafe\nPasswort: latte2026',
        ).network,
        'Cafe',
      );
    });
  });

  group('shipments', () {
    TrackingDetails firstParcel(String text) =>
        of(text, DetectedActionKind.tracking).first.details!
            as TrackingDetails;

    test('a labelled number takes the carrier named on the screen', () {
      final TrackingDetails parcel = firstParcel(
        'Your Aramex shipment is on its way\nTracking number: 4512378901',
      );
      expect(parcel.carrier, ShipmentCarrier.aramex);
      expect(parcel.number, '4512378901');
    });

    test('a labelled parcel number is claimed, not left to the code rule', () {
      // Ten digits either way; only the label tells them apart.
      expect(
        ActionExtractor.extract(
          'Aramex\nTracking number: 4512378901',
        ).map((a) => a.kind),
        everyElement(DetectedActionKind.tracking),
      );
    });

    test('a UPS number identifies itself with no label at all', () {
      final TrackingDetails parcel = firstParcel('1Z999AA10123456784');
      expect(parcel.carrier, ShipmentCarrier.ups);
    });

    test('an S10 postal barcode falls back to the aggregator', () {
      final TrackingDetails parcel = firstParcel('Item RA123456789JO posted');
      expect(parcel.carrier, ShipmentCarrier.post);
    });

    test('an unlabelled run of digits is not a parcel', () {
      expect(of('Order Details 4512378901', DetectedActionKind.tracking),
          isEmpty);
    });

    /// The shipped-language carriers, in the wording their own notifications
    /// use. Every one of these was invisible before the language swap: the
    /// label was English-only and the alias table held the Gulf carriers plus
    /// Arabic transliterations no recogniser could return.
    test('the European carriers are recognised in their own wording', () {
      const Map<String, ShipmentCarrier> notifications = <String, ShipmentCarrier>{
        'DPD\nSendungsnummer: 09876543210987': ShipmentCarrier.dpd,
        'GLS Sendungsverfolgung\nPaketnummer 12345678901': ShipmentCarrier.gls,
        'Hermes\nSendungsnummer 33012345678901': ShipmentCarrier.hermes,
        'PostNL\nTrack & trace: 3SABCD1234567': ShipmentCarrier.postnl,
        'Poste Italiane\nNumero di spedizione: 12345678901':
            ShipmentCarrier.poste,
        'CTT\nNúmero de objeto: RR123456789PT': ShipmentCarrier.ctt,
        'Correos\nNúmero de seguimiento: PK123456789ES':
            ShipmentCarrier.correos,
        'Colissimo\nNuméro de suivi : 6A12345678901': ShipmentCarrier.colissimo,
      };

      notifications.forEach((String text, ShipmentCarrier want) {
        final TrackingDetails parcel = firstParcel(text);
        expect(parcel.carrier, want, reason: text);
        expect(parcel.number, isNotEmpty, reason: text);
      });
    });

    test('a tracking label with no carrier still yields a number', () {
      final TrackingDetails parcel = firstParcel('Tracking No. 778812349');
      expect(parcel.number, '778812349');
      // No brand on the screen, so no Track button will be offered.
      expect(parcel.carrier, isNull);
    });
  });

  group('places', () {
    PlaceDetails firstPlace(String text) =>
        of(text, DetectedActionKind.place).first.details! as PlaceDetails;

    test('a labelled delivery address is a place', () {
      expect(
        firstPlace('Delivery address: 12 King Fahd Road, Riyadh').query,
        '12 King Fahd Road, Riyadh',
      );
    });

    test('a coordinate pair is exact', () {
      final PlaceDetails place = firstPlace('Dropped pin 24.7743, 46.7386');
      expect(place.query, '24.7743,46.7386');
      expect(place.isCoordinates, isTrue);
    });

    test('coordinates are not read as a long number', () {
      expect(
        ActionExtractor.extract(
          'Dropped pin 24.7743, 46.7386',
        ).map((a) => a.kind),
        everyElement(DetectedActionKind.place),
      );
    });

    /// An unlabelled street line, in each of the two word orders the shipped
    /// languages actually use.
    ///
    /// This was one Arabic case before the language swap, and it was the only
    /// coverage the *number-last* word order had anywhere in the suite — which
    /// is how it went unnoticed that removing it would have left German,
    /// Dutch, Italian, Portuguese, Spanish and French with no unlabelled
    /// street rule at all. The rule was rewritten rather than deleted; these
    /// are its cases.
    test('a street line needs no label, in either word order', () {
      // Number last, street type welded to the name.
      expect(firstPlace('Lieferung an Hauptstraße 12').query,
          contains('Hauptstraße 12'));
      expect(firstPlace('Bezorgen op Kerkstraat 5a').query,
          contains('Kerkstraat 5a'));
      // Number last, street type leading.
      expect(firstPlace('Consegna in Via Roma 12').query,
          contains('Via Roma 12'));
      expect(firstPlace('Entrega na Rua Augusta 24').query,
          contains('Rua Augusta 24'));
      // And the English order still works.
      expect(firstPlace('Deliver to 221 Baker Street').query,
          contains('221 Baker Street'));
    });

    test('an ordinary sentence in those languages is not a street', () {
      // `Weg`, `Ring`, `corso` and `place` are common nouns; the house number
      // is what separates the address from the sentence.
      for (final String text in <String>[
        'Der Weg war lang und ruhig',
        'Il corso di italiano inizia lunedì',
        'Er is genoeg plaats voor iedereen',
      ]) {
        expect(of(text, DetectedActionKind.place), isEmpty, reason: text);
      }
    });

    test('a settings row is not a place', () {
      expect(of('Location services', DetectedActionKind.place), isEmpty);
      expect(of('Address book', DetectedActionKind.place), isEmpty);
    });

    test('a labelled link stays a link', () {
      final List<DetectedAction> actions = ActionExtractor.extract(
        'Location: https://maps.test/x9f2',
      );
      expect(actions.where((a) => a.kind == DetectedActionKind.place), isEmpty);
      expect(actions.where((a) => a.kind == DetectedActionKind.link),
          hasLength(1));
    });
  });
}
