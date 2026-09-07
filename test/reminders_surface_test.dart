import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/widgets/asset_thumbnail_image.dart';
import 'package:shoto/features/home/presentation/widgets/home_inbox.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';

import 'support/fake_gallery.dart';
import 'support/test_fonts.dart';

/// Where a reminder can be *seen*.
///
/// The feature shipped able to fire and unable to be looked at: a reminder was
/// invisible unless you long-pressed the exact screenshot it was set on. These
/// pin the two halves of the fix — the state derives the list, and Home says
/// enough about it to be worth a tap.
ScreenshotEntity _shot(int id, {DateTime? remindAt}) => ScreenshotEntity(
  asset: FakeGallery.asset(id),
  isFavorite: false,
  folderId: null,
  remindAt: remindAt,
);

void main() {
  setUpAll(() async {
    // **Real type, because half of this file is now about whether text fits.**
    // `flutter test` draws every glyph as a square em box, which is twice the
    // width of the face that ships — a wrapping test run against it fails on
    // strings the phone renders comfortably, and passes on none.
    await loadTestFonts();
    await FakeGallery.install();
    // Tapping anything in this app goes through `PressableScale`, which asks
    // `Haptics` whether the user wants a buzz — and that reads the preference
    // out of the service locator.
    if (!sl.isRegistered<AppPreferences>()) {
      sl.registerLazySingleton<AppPreferences>(() => AppPreferences());
    }
  });

  group('the derived list', () {
    test('holds only the screenshots that have one, soonest first', () {
      final ScreenshotsLoadedState state = ScreenshotsLoadedState(
        screenshots: <ScreenshotEntity>[
          _shot(1, remindAt: DateTime(2030, 6, 3)),
          _shot(2),
          _shot(3, remindAt: DateTime(2030, 6, 1)),
          _shot(4, remindAt: DateTime(2030, 6, 2)),
        ],
      );

      expect(state.reminders.map((ScreenshotEntity s) => s.id), <String>[
        '3',
        '4',
        '1',
      ]);
    });

    test('keeps the ones whose moment has passed', () {
      // The reason this screen exists: a notification clears itself when it
      // fires, so dropping past reminders here would mean the one moment the
      // app asked for attention is the only one it ever gets.
      final ScreenshotsLoadedState state = ScreenshotsLoadedState(
        screenshots: <ScreenshotEntity>[
          _shot(1, remindAt: DateTime(2020, 1, 1)),
          _shot(2, remindAt: DateTime(2030, 1, 1)),
        ],
      );

      expect(state.reminders.length, 2);
      expect(state.reminders.first.id, '1');
    });

    test('is empty when nobody has set one', () {
      final ScreenshotsLoadedState state = ScreenshotsLoadedState(
        screenshots: <ScreenshotEntity>[_shot(1), _shot(2)],
      );
      expect(state.reminders, isEmpty);
    });
  });

  group('the row on Home', () {
    Widget wrap(Widget child) => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, _) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

    testWidgets('counts them, and says when the next one is due', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          HomeInbox(
            unsorted: const <ScreenshotEntity>[],
            waiting: const {},
            reminders: <ScreenshotEntity>[
              _shot(1, remindAt: DateTime.now().add(const Duration(hours: 2))),
              _shot(2, remindAt: DateTime.now().add(const Duration(days: 1))),
            ],
            onOpenLibrary: (_) {},
            onOpenIntent: (_) {},
            onOpenReminders: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 reminders'), findsOneWidget);
      // Not the alert wording — nothing has been missed.
      expect(find.textContaining('missed'), findsNothing);
      expect(find.textContaining('Next'), findsOneWidget);
    });

    testWidgets('leads with what was missed, when something was', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          HomeInbox(
            unsorted: const <ScreenshotEntity>[],
            waiting: const {},
            reminders: <ScreenshotEntity>[
              _shot(1, remindAt: DateTime(2020, 1, 1)),
              _shot(2, remindAt: DateTime.now().add(const Duration(days: 1))),
            ],
            onOpenLibrary: (_) {},
            onOpenIntent: (_) {},
            onOpenReminders: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // **It is the sentence now, not a footnote on one.** This used to read
      // "2 reminders" in body weight with a small grey "1 missed" at the far
      // end — the neutral total loud, the fact that needed somebody quiet, and
      // the reader left subtracting to find out how much of the two was a
      // problem.
      expect(find.text('1 missed reminder'), findsOneWidget);

      // And the total is gone rather than demoted: on Home the only question
      // is whether to tap, and the screen behind this row carries the
      // breakdown.
      expect(find.textContaining('2 reminders'), findsNothing);

      // **And what is still coming survives being told about what was not.**
      // On one line there was room for a single fact, so a missed reminder
      // cost the row its ability to say anything about the future. Two lines
      // is what gave that back — the condition on the second line is "is
      // anything still coming", which has nothing to do with whether something
      // was missed.
      expect(find.textContaining('Next'), findsOneWidget);
    });

    testWidgets('and says nothing about a next one when there is none', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          HomeInbox(
            unsorted: const <ScreenshotEntity>[],
            waiting: const {},
            reminders: <ScreenshotEntity>[
              _shot(1, remindAt: DateTime(2020, 1, 1)),
              _shot(2, remindAt: DateTime(2020, 1, 2)),
            ],
            onOpenLibrary: (_) {},
            onOpenIntent: (_) {},
            onOpenReminders: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 missed reminders'), findsOneWidget);
      // Not an empty line held open for a sentence the row has no answer for:
      // with everything missed there is genuinely nothing next.
      expect(find.textContaining('Next'), findsNothing);
    });

    testWidgets('shows the screenshots the reminders are about', (
      tester,
    ) async {
      // **The row said how many and never which.** A reminder is about a
      // picture — the whole reminders screen is built on that — and the
      // leading slot was spending itself on a bell that said "reminders" beside
      // a sentence with the word *reminders* in it.
      await tester.pumpWidget(
        wrap(
          HomeInbox(
            unsorted: const <ScreenshotEntity>[],
            waiting: const {},
            reminders: <ScreenshotEntity>[
              for (int i = 1; i <= 5; i++)
                _shot(i, remindAt: DateTime.now().add(Duration(days: i))),
            ],
            onOpenLibrary: (_) {},
            onOpenIntent: (_) {},
            onOpenReminders: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Two, however many there are: the count is in the sentence beside them,
      // and nobody counts a stack.
      expect(find.byType(AssetThumbnailImage), findsNWidgets(2));
    });

    testWidgets('a single reminder is a single thumbnail', (tester) async {
      await tester.pumpWidget(
        wrap(
          HomeInbox(
            unsorted: const <ScreenshotEntity>[],
            waiting: const {},
            reminders: <ScreenshotEntity>[
              _shot(1, remindAt: DateTime.now().add(const Duration(hours: 2))),
            ],
            onOpenLibrary: (_) {},
            onOpenIntent: (_) {},
            onOpenReminders: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AssetThumbnailImage), findsOneWidget);
    });

    testWidgets('opens the list when tapped', (tester) async {
      int taps = 0;
      await tester.pumpWidget(
        wrap(
          HomeInbox(
            unsorted: const <ScreenshotEntity>[],
            waiting: const {},
            reminders: <ScreenshotEntity>[
              _shot(1, remindAt: DateTime.now().add(const Duration(hours: 2))),
            ],
            onOpenLibrary: (_) {},
            onOpenIntent: (_) {},
            onOpenReminders: () => taps++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('1 reminder'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('a library with only reminders is not "all filed"', (
      tester,
    ) async {
      // The clear state collapses the whole block to one quiet line. A pending
      // reminder is work, so claiming there is none would be the app telling
      // somebody they are done while holding an alarm for them.
      await tester.pumpWidget(
        wrap(
          HomeInbox(
            unsorted: const <ScreenshotEntity>[],
            waiting: const {},
            reminders: <ScreenshotEntity>[
              _shot(1, remindAt: DateTime.now().add(const Duration(hours: 2))),
            ],
            onOpenLibrary: (_) {},
            onOpenIntent: (_) {},
            onOpenReminders: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 reminder'), findsOneWidget);
    });

    testWidgets('and nothing is drawn when there are none', (tester) async {
      await tester.pumpWidget(
        wrap(
          HomeInbox(
            unsorted: const <ScreenshotEntity>[],
            waiting: const {},
            reminders: const <ScreenshotEntity>[],
            onOpenLibrary: (_) {},
            onOpenIntent: (_) {},
            onOpenReminders: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('reminder'), findsNothing);
    });
  });

  /// Whether the row still fits on the narrowest phone the app supports.
  ///
  /// **It did not, and nothing about it looked wrong.** The row was
  /// `[bell] headline …… detail [›]` with the headline flexible and the
  /// detail at its natural width — and `Expanded` is not a claim on space, it
  /// is an offer to give space back. So the fixed child took what it wanted and
  /// the flexible one wrapped into whatever was left: at 360dp "12
  /// Erinnerungen" came out over two lines, and at the 1.3× text size a great
  /// many people run, "12 lembretes" came out over **five** — a column of
  /// single characters where a sentence belonged.
  ///
  /// It was not a near miss that a long translation exposed. The row only ever
  /// fit because the moment was printed as a bare clock time; giving the date
  /// the honesty it needed is what made the arithmetic visible, and the
  /// arithmetic had never worked.
  ///
  /// These run every shipped language at both sizes, because the failure is
  /// entirely a matter of how long a word is in somebody else's language and
  /// English is the one that hides it longest.
  group('the row on Home fits', () {
    /// How many lines a piece of text actually came out on.
    ///
    /// The renderer's own answer, not the string's. `find.text` matches on
    /// `Text.data`, which reports the string handed *in* — identical whether
    /// it landed on one line or five.
    ///
    /// Its laid-out height over the height the same span wants when nothing is
    /// squeezing it, which is by definition one line.
    int linesOf(WidgetTester tester, Finder text) {
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: text, matching: find.byType(RichText)).first,
      );
      final double oneLine = paragraph.getMaxIntrinsicHeight(double.infinity);
      return (paragraph.size.height / oneLine).round();
    }

    Future<void> pumpAt(
      WidgetTester tester,
      Locale locale,
      double textScale,
      List<ScreenshotEntity> reminders,
    ) async {
      // 360 is the narrow end of the phones this ships to. It is also the
      // design width, so `.w` and `.sp` both resolve 1:1 here and the numbers
      // below are the ones a reviewer would measure on the screen.
      tester.view.physicalSize = const Size(360, 690);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (BuildContext context, Widget? _) => MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (BuildContext c, Widget? child) => MediaQuery(
              data: MediaQuery.of(
                c,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: Scaffold(
              body: Padding(
                // Home's own gutter. The row has no width of its own, so
                // measuring it anywhere else measures nothing.
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: HomeInbox(
                  unsorted: const <ScreenshotEntity>[],
                  waiting: const {},
                  reminders: reminders,
                  onOpenLibrary: (_) {},
                  onOpenIntent: (_) {},
                  onOpenReminders: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // **The headline is found by its exact sentence, not by hunting for the
    // digits in it.** These cases used to look for any text containing "12",
    // which is the headline for most of the day and two widgets at 16:12 —
    // the second line under it prints a clock, and a clock contains digits.
    // The suite went red on a change that touched neither the row nor the
    // wording, purely because of the minute it was run in.
    for (final Locale locale in AppLocalizations.supportedLocales) {
      for (final double scale in const <double>[1.0, 1.3]) {
        testWidgets(
          'the headline stays on one line — ${locale.languageCode} at '
          '${scale}x',
          (WidgetTester tester) async {
            // Twelve, and every one of them still to come: the longest the
            // neutral sentence gets, over the longest form of the moment
            // underneath it.
            await pumpAt(tester, locale, scale, <ScreenshotEntity>[
              for (int i = 1; i <= 12; i++)
                _shot(i, remindAt: DateTime.now().add(Duration(days: 2 + i))),
            ]);

            final Finder headline = find.text(
              lookupAppLocalizations(locale).remindersCount(12),
            );
            expect(headline, findsOneWidget);
            expect(linesOf(tester, headline), 1);
          },
        );

        testWidgets(
          'the missed headline stays on one line — ${locale.languageCode} at '
          '${scale}x',
          (WidgetTester tester) async {
            // The louder sentence, and the longer one in every language here
            // — over a second line, since one of the twelve is still to come.
            await pumpAt(tester, locale, scale, <ScreenshotEntity>[
              for (int i = 1; i <= 12; i++)
                _shot(i, remindAt: DateTime(2020, 1, i)),
              _shot(99, remindAt: DateTime.now().add(const Duration(days: 9))),
            ]);

            final Finder headline = find.text(
              lookupAppLocalizations(locale).remindersMissedTitle(12),
            );
            expect(headline, findsOneWidget);
            expect(linesOf(tester, headline), 1);
          },
        );
      }
    }
  });
}
