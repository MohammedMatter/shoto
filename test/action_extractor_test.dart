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
      final EventDetails event = firstEvent('دعوة حفل زفاف\n20/02/2026');
      expect(event.start, DateTime(2026, 2, 20));
    });

    test('a chat header from last week does not', () {
      // The exact case the recent-past window would otherwise let in: a date
      // and a time and nothing calling it an occasion. A clock time earns a
      // future date its row and earns a past one nothing at all.
      expect(eventsIn('20/02/2026 3:42 PM\nsee you'), isEmpty);
    });

    test('an occasion older than the window is a record, not a plan', () {
      expect(eventsIn('دعوة حفل زفاف\n09/11/2024'), isEmpty);
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

    test('Levantine month names are months', () {
      // "أيار" is May across the Levant and appears in no table built from
      // "مايو" — an Arabic screenshot from Amman would otherwise find nothing.
      final EventDetails event = firstEvent('دعوة زفاف\n12 أيار 2026');
      expect(event.start, DateTime(2026, 5, 12));
      expect(event.allDay, isTrue);
    });

    test('Arabic digits and an Arabic meridiem are understood', () {
      final EventDetails event = firstEvent(
        'موعد المقابلة\n٢٠/٠٥/٢٠٢٦ الساعة ٣:٠٠ م',
      );
      expect(event.start, DateTime(2026, 5, 20, 15, 0));
    });

    test('decorative type spaces out its separators, and it still reads', () {
      // A printed invitation sets the date in a wide face and recognition
      // comes back with the separators floating: "12 / 5 / 2026", "8 : 00".
      // Both spellings missed entirely until this was allowed for, which is
      // the difference between the feature working on a real wedding card and
      // only on a calendar app's tidy output.
      final EventDetails event = firstEvent('دعوة حفل زفاف\n١٢ / ٥ / ٢٠٢٦ - ٨ : ٠٠ مساءً');
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

    test('the event claims its own digits before the phone rule sees them', () {
      final List<DetectedAction> actions = ActionExtractor.extract(
        'Meeting on 12/05/2026 at 3:00 PM',
        now: today,
      );
      expect(actions.where((a) => a.kind == DetectedActionKind.phone), isEmpty);
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
    DateTime hijriStart(String text) =>
        firstEvent(text, dayFirst: true).start;

    test('a wedding card in Arabic digits converts to the right day', () {
      // 15 Ramadan 1447 — the fifteenth day of a month beginning 18 Feb.
      expect(hijriStart('دعوة حفل\n١٥ رمضان ١٤٤٧'), DateTime(2026, 3, 4));
    });

    test('the era marker and Latin digits are both optional spellings', () {
      expect(hijriStart('دعوة زفاف\n15 رمضان 1447 هـ'), DateTime(2026, 3, 4));
      expect(hijriStart('دعوة زفاف\n15 من رمضان 1447'), DateTime(2026, 3, 4));
    });

    test('a month spelled without its hamza is the same month', () {
      // Printed cards drop the hamza as often as they write it, and a table
      // holding only ربيع الأول silently ignores half of them.
      expect(
        hijriStart('دعوة حفل\n10 ربيع الاول 1448'),
        hijriStart('دعوة حفل\n10 ربيع الأول 1448'),
      );
    });

    test('a digit-only Hijri date needs no era marker to be recognised', () {
      // A four-digit year in the fourteen-hundreds cannot be a Gregorian date
      // this feature would accept, so the year settles it on its own.
      expect(hijriStart('دعوة حفل\n15/9/1447'), DateTime(2026, 3, 4));
    });

    test('a Hijri date carries its time across the conversion', () {
      final EventDetails event = firstEvent('دعوة حفل\n15 رمضان 1447 - 8:00 م');
      expect(event.start, DateTime(2026, 3, 4, 20, 0));
      expect(event.allDay, isFalse);
    });

    test('the thirtieth of a twenty-nine-day month is not a date', () {
      // Safar 1447 runs twenty-nine days. Without the length check the
      // conversion rolls quietly into the next month, exactly as DateTime
      // does with the thirty-first of February.
      expect(eventsIn('دعوة حفل\n30/2/1447'), isEmpty);
    });

    test('a Hijri occasion already past is still past', () {
      // 1445 ended in 2024; the calendar it was written in changes nothing
      // about which rules apply after the conversion.
      expect(eventsIn('دعوة حفل\n15 رمضان 1445'), isEmpty);
    });

    test('a month name without a year is not a date', () {
      // صفر is also the word for zero and رجب is a given name. The year is
      // what makes the month name safe to act on.
      expect(eventsIn('رمضان مبارك — دعوة'), isEmpty);
      expect(eventsIn('المبلغ 15 صفر 2024'), isEmpty);
    });

    test('a Hijri date still has to say it is an occasion', () {
      // The conversion buys no exemption from the gate every other date
      // passes through.
      expect(eventsIn('الفاتورة\n15 رمضان 1447'), isEmpty);
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

    test('a password with nothing calling it wireless is not a network key', () {
      // The single most likely false positive in the whole feature.
      expect(of('Your password: hunter2024', DetectedActionKind.wifi), isEmpty);
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

    test('a labelled number is not a phone number', () {
      // Ten digits either way; only the label tells them apart.
      expect(
        of(
          'Aramex\nTracking number: 4512378901',
          DetectedActionKind.phone,
        ),
        isEmpty,
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
        of('Dropped pin 24.7743, 46.7386', DetectedActionKind.phone),
        isEmpty,
      );
    });

    test('an Arabic street line needs no label', () {
      expect(firstPlace('التوصيل إلى شارع الملك فهد').query,
          contains('شارع الملك فهد'));
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
