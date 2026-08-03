import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/features/smart_actions/domain/entities/action_details.dart';
import 'package:shoto/features/smart_actions/domain/entities/detected_action.dart';
import 'package:shoto/features/smart_actions/presentation/widgets/action_options.dart';
import 'package:shoto/l10n/app_localizations.dart';

/// Covers the half of smart actions the extractor tests cannot reach: what the
/// detection turns into once it has to be handed to another app.
///
/// The link is the whole feature. A perfectly parsed event that produces a
/// calendar URL with the timestamp in the wrong shape is worth nothing, and
/// nothing about it would show up in a parser test.
void main() {
  /// Runs [body] with a context that has the app's translations attached, in
  /// [locale]. Needed because every label and the date formatting are read
  /// from the tree.
  Future<void> withContext(
    WidgetTester tester,
    String locale,
    void Function(BuildContext context) body,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) {
            body(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  group('calendar link', () {
    test('a timed event becomes a template with a floating local stamp', () {
      final Uri uri = calendarUriFor(
        EventDetails(
          title: 'Team sync',
          start: DateTime(2026, 5, 12, 15, 0),
          end: DateTime(2026, 5, 12, 16, 30),
          location: 'Room 4',
          notes: 'Team sync\n12/05/2026 3:00 PM',
        ),
        'Team sync',
      );

      expect(uri.host, 'calendar.google.com');
      expect(uri.queryParameters['action'], 'TEMPLATE');
      expect(uri.queryParameters['text'], 'Team sync');
      // No trailing Z and no offset: Google reads this in the calendar's own
      // timezone, which is what a screenshot saying "3:00 PM" means.
      expect(
        uri.queryParameters['dates'],
        '20260512T150000/20260512T163000',
      );
      expect(uri.queryParameters['location'], 'Room 4');
      expect(uri.queryParameters['details'], contains('Team sync'));
    });

    test('a missing finish time becomes an hour', () {
      final Uri uri = calendarUriFor(
        EventDetails(title: null, start: DateTime(2026, 5, 12, 12, 0)),
        'Event',
      );
      expect(uri.queryParameters['dates'], '20260512T120000/20260512T130000');
    });

    test('an all-day event uses dates and an exclusive end', () {
      final Uri uri = calendarUriFor(
        EventDetails(
          title: 'Eid',
          start: DateTime(2026, 5, 12),
          allDay: true,
        ),
        'Eid',
      );
      expect(uri.queryParameters['dates'], '20260512/20260513');
    });

    test('a range that crosses midnight still finishes after it starts', () {
      // "11:00 PM – 1:00 AM" parses both ends onto the same calendar day, so
      // the finish lands two hours before the start unless it is pushed on.
      final Uri uri = calendarUriFor(
        EventDetails(
          title: 'Late show',
          start: DateTime(2026, 5, 12, 23, 0),
          end: DateTime(2026, 5, 12, 1, 0),
        ),
        'Late show',
      );
      expect(uri.queryParameters['dates'], '20260512T230000/20260513T010000');
    });

    test('single-digit months and hours are padded', () {
      final Uri uri = calendarUriFor(
        EventDetails(title: 'x', start: DateTime(2026, 1, 2, 3, 4)),
        'x',
      );
      expect(uri.queryParameters['dates'], startsWith('20260102T030400'));
    });
  });

  group('maps link', () {
    test('an address becomes a search', () {
      final Uri uri = mapsUriFor(
        '/maps/search/',
        'query',
        const PlaceDetails(query: '12 King Fahd Road, Riyadh'),
      );
      expect(uri.toString(), startsWith('https://www.google.com/maps/search/'));
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['query'], '12 King Fahd Road, Riyadh');
    });

    test('coordinates become a destination', () {
      final Uri uri = mapsUriFor(
        '/maps/dir/',
        'destination',
        const PlaceDetails(query: '24.7743,46.7386', isCoordinates: true),
      );
      expect(uri.queryParameters['destination'], '24.7743,46.7386');
    });
  });

  group('tracking link', () {
    test('each carrier carries the number in its own parameter', () {
      expect(
        ShipmentCarrier.aramex.trackingUrl('4512378901').toString(),
        endsWith('4512378901'),
      );
      expect(
        ShipmentCarrier.ups.trackingUrl('1Z999AA10123456784').host,
        'www.ups.com',
      );
    });

    test('a number needing escaping survives the round trip', () {
      final Uri uri = ShipmentCarrier.dhl.trackingUrl('JD01 4600');
      expect(uri.queryParameters['AWB'], 'JD01 4600');
    });
  });

  group('rows', () {
    testWidgets('an event shows its title above a formatted date', (
      WidgetTester tester,
    ) async {
      final DetectedAction action = DetectedAction(
        kind: DetectedActionKind.event,
        value: 'x',
        display: '12/05/2026 3:00 PM',
        details: EventDetails(
          title: 'Team sync',
          start: DateTime(2026, 5, 12, 15, 0),
        ),
      );

      await withContext(tester, 'en', (BuildContext context) {
        expect(action.displayText(context), 'Team sync');
        final String? subtitle = action.subtitle(context);
        expect(subtitle, contains('2026'));
        expect(subtitle, contains('3:00'));
        expect(action.options(context).first.label, 'Add to calendar');
      });
    });

    testWidgets('an untitled event falls back to a translated placeholder', (
      WidgetTester tester,
    ) async {
      final DetectedAction action = DetectedAction(
        kind: DetectedActionKind.event,
        value: 'x',
        display: '12/05/2026',
        details: EventDetails(
          title: null,
          start: DateTime(2026, 5, 12),
          allDay: true,
        ),
      );

      await withContext(tester, 'en', (BuildContext context) {
        expect(action.displayText(context), 'Event');
      });
    });

    testWidgets('an Arabic reader gets an Arabic date, not a crash', (
      WidgetTester tester,
    ) async {
      // The one real risk in formatting: `DateFormat` throws outright when a
      // locale's date symbols were never loaded, and it would take the whole
      // row down with it.
      final DetectedAction action = DetectedAction(
        kind: DetectedActionKind.event,
        value: 'x',
        display: '',
        details: EventDetails(
          title: 'اجتماع',
          start: DateTime(2026, 5, 12, 15, 0),
        ),
      );

      for (final String locale in <String>['ar', 'ur', 'hi', 'fr', 'es']) {
        await withContext(tester, locale, (BuildContext context) {
          expect(action.subtitle(context), isNotEmpty);
          expect(action.options(context), isNotEmpty);
        });
      }
    });

    testWidgets('copy never hands back the internal identity value', (
      WidgetTester tester,
    ) async {
      final DetectedAction place = DetectedAction(
        kind: DetectedActionKind.place,
        // Case-folded, because that is what makes two detections the same one.
        value: '12 king fahd road',
        display: '12 King Fahd Road',
        details: const PlaceDetails(query: '12 King Fahd Road'),
      );

      await withContext(tester, 'en', (BuildContext context) {
        expect(place.copyText(context), '12 King Fahd Road');
      });
    });

    testWidgets('a network without a name offers no name to copy', (
      WidgetTester tester,
    ) async {
      const DetectedAction named = DetectedAction(
        kind: DetectedActionKind.wifi,
        value: 'latte2026',
        display: 'latte2026',
        details: WifiDetails(network: 'CafeGuest', password: 'latte2026'),
      );
      const DetectedAction anonymous = DetectedAction(
        kind: DetectedActionKind.wifi,
        value: 'latte2026',
        display: 'latte2026',
        details: WifiDetails(network: null, password: 'latte2026'),
      );

      await withContext(tester, 'en', (BuildContext context) {
        // Copy and Share are appended to every kind, so the network chip is
        // the difference between three options and two.
        expect(named.options(context), hasLength(3));
        expect(anonymous.options(context), hasLength(2));
        expect(named.subtitle(context), 'CafeGuest');
        expect(anonymous.subtitle(context), isNull);
      });
    });

    testWidgets('an unidentified carrier offers no Track button', (
      WidgetTester tester,
    ) async {
      const DetectedAction known = DetectedAction(
        kind: DetectedActionKind.tracking,
        value: '4512378901',
        display: '4512378901',
        details: TrackingDetails(
          carrier: ShipmentCarrier.aramex,
          number: '4512378901',
        ),
      );
      const DetectedAction unknown = DetectedAction(
        kind: DetectedActionKind.tracking,
        value: '778812349',
        display: '778812349',
        details: TrackingDetails(carrier: null, number: '778812349'),
      );

      await withContext(tester, 'en', (BuildContext context) {
        expect(known.options(context), hasLength(3));
        expect(unknown.options(context), hasLength(2));
        expect(known.subtitle(context), 'Aramex');
      });
    });

    testWidgets('every kind has a label in every language', (
      WidgetTester tester,
    ) async {
      for (final String locale in <String>['en', 'ar', 'es', 'fr', 'hi', 'ur']) {
        await withContext(tester, locale, (BuildContext context) {
          for (final DetectedActionKind kind in DetectedActionKind.values) {
            expect(
              DetectedAction(
                kind: kind,
                value: 'v',
                display: 'v',
                details: _detailsFor(kind),
              ).kindLabel(context),
              isNotEmpty,
              reason: '$kind has no label in $locale',
            );
          }
        });
      }
    });
  });
}

ActionDetails? _detailsFor(DetectedActionKind kind) => switch (kind) {
  DetectedActionKind.event => EventDetails(
    title: 't',
    start: DateTime(2026, 5, 12, 12, 0),
  ),
  DetectedActionKind.place => const PlaceDetails(query: 'q'),
  DetectedActionKind.wifi => const WifiDetails(network: 'n', password: 'p'),
  DetectedActionKind.tracking => const TrackingDetails(
    carrier: ShipmentCarrier.dhl,
    number: '1',
  ),
  _ => null,
};
