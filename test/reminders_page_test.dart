import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/use_cases/set_reminder_use_case.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/pages/reminders_page.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/fake_gallery.dart';
import 'support/test_theme.dart';

/// The screen that exists so a missed reminder is not a thing that happened
/// once and vanished.
///
/// What is pinned here is the behaviour the second pass added, because each of
/// those replaced something that was actively unhelpful: a single "Coming up"
/// heading covering this afternoon and next month alike, a second line on every
/// row that restated the heading above it, and a removal that could not be
/// taken back.
void main() {
  late _StubScreenshotsBloc bloc;

  setUpAll(() async {
    await FakeGallery.install();
    // The page records that the swipe has been learnt, which writes through
    // `SharedPreferences` — unmocked, that is a `MissingPluginException` in
    // the middle of a gesture rather than a failed assertion.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    if (!sl.isRegistered<ThemeController>()) {
      sl.registerLazySingleton<ThemeController>(() => ThemeController());
    }
  });

  setUp(() {
    bloc = _StubScreenshotsBloc();
    // **A new one per test, because one of these preferences is written to.**
    // `markReminderSwiped` is a fact that never goes back, so a shared
    // instance would carry "this user knows about swiping" out of the swipe
    // tests and into every test that runs after them — and the legend they
    // expect to see would silently stop being drawn depending on the order the
    // file happens to run in.
    //
    // Registered at all because tapping anything goes through
    // `PressableScale`, which asks `Haptics` whether the user wants a buzz,
    // and that reads the service locator.
    if (sl.isRegistered<AppPreferences>()) {
      sl.unregister<AppPreferences>();
    }
    sl.registerSingleton<AppPreferences>(AppPreferences());
  });
  tearDown(() => bloc.close());

  /// Scoped to a reminder row, because the swipe legend above the list says
  /// the same two words and carries the same two glyphs — deliberately, since
  /// its whole job is to be a legend for them. An unscoped `find.byIcon` here
  /// asks "is this control on the page" when the question is "is it on the
  /// row".
  Finder inRow(Finder matching) =>
      find.descendant(of: find.byType(Dismissible), matching: matching);

  /// **A Tuesday afternoon, and the page is told so.**
  ///
  /// Half of what this screen says is a comparison against *now* — which band
  /// a moment falls in, how long ago it went by, how soon it is due — so a test
  /// measuring from the real clock has to either skip itself around midnight
  /// and the evening or assert something weaker than it means. `RemindersPage`
  /// takes a clock for exactly this; every case below is stated as an offset
  /// from [fixedNow] and is the same case at three in the morning.
  final DateTime fixedNow = DateTime(2026, 8, 18, 14, 30);

  /// A reminder [offset] from [fixedNow], so every case sits in a band by
  /// construction rather than by whatever time the suite happens to run.
  ScreenshotEntity shot(int id, Duration offset) => ScreenshotEntity(
    asset: FakeGallery.asset(id),
    isFavorite: false,
    folderId: null,
    remindAt: fixedNow.add(offset),
  );

  Future<void> pumpPage(
    WidgetTester tester,
    List<ScreenshotEntity> reminders, {
    DateTime? now,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    bloc.push(ScreenshotsLoadedState(screenshots: reminders));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (BuildContext context, Widget? _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: testTheme(Brightness.dark),
          home: BlocProvider<ScreenshotsBloc>.value(
            value: bloc,
            child: RemindersPage(clock: () => now ?? fixedNow),
          ),
        ),
      ),
    );
    // Bounded rather than `pumpAndSettle`, and now for three reasons rather
    // than two: thumbnails resolve through a fake gallery future, the app bar
    // carries an implicit animation, and the missed band's heading breathes on
    // a loop that by design never ends.
    //
    // **Three pumps, because the rows arrive under `EntranceStagger`.** The
    // first frame paints them at opacity zero; the second is what lets the
    // zero-delay `Future` behind the first row's entrance fire; only the third
    // gives its controller a tick to run on. Two pumps left every row fully
    // built, findable by text — and invisible, which is a distinction only the
    // semantics tree notices, and it noticed by reporting no labels at all.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    // **And one long frame to let the demonstration finish.** The first row
    // performs the swipe once for a new user, which takes about two and a half
    // seconds and leaves a translated card and a revealed panel on screen for
    // most of it — a tap aimed at the row would land somewhere else, and the
    // panel's own label would be a second copy of a word the legend already
    // says. Every case below is about the settled page, so it is settled here
    // rather than in each of them. The nudge test does its own pumping.
    await tester.pump(const Duration(seconds: 6));
  }

  testWidgets('with nothing set it says so rather than showing headings', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester, const <ScreenshotEntity>[]);

    expect(find.text('No reminders'), findsOneWidget);
    expect(find.text('Missed'), findsNothing);

    // **Says what the screen is for, not how to reach it.** The copy here used
    // to be a route — "open a screenshot's actions and pick …" — quoting a menu
    // item from another screen at somebody who is standing on this one. Every
    // other empty state in the app states its purpose instead; this pins that
    // it does too, by refusing the shape of an instruction.
    expect(
      find.textContaining('wait here'),
      findsOneWidget,
      reason: 'the empty state should describe the place, not the route',
    );
  });

  testWidgets('a moment gone is filed under Missed, not under a day', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester, <ScreenshotEntity>[
      shot(1, const Duration(hours: -2)),
    ]);

    expect(find.text('Missed'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
  });

  testWidgets('the bands appear in order and only when they have items', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester, <ScreenshotEntity>[
      shot(1, const Duration(hours: -3)),
      shot(2, const Duration(days: 2)),
    ]);

    // Nothing due later today and nothing tomorrow, so neither heading is
    // drawn — an empty band is a row that costs height and says nothing.
    expect(find.text('Missed'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
    expect(find.text('Tomorrow'), findsNothing);

    final double missedY = tester.getTopLeft(find.text('Missed')).dy;
    final double weekY = tester.getTopLeft(find.text('This week')).dy;
    expect(
      missedY,
      lessThan(weekY),
      reason: 'missed reminders must lead the list',
    );
  });

  testWidgets('the heading carries the count so the rows need not', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester, <ScreenshotEntity>[
      shot(1, const Duration(hours: -3)),
      shot(2, const Duration(hours: -2)),
      shot(3, const Duration(hours: -1)),
    ]);

    expect(find.text('Missed'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    // The old row printed its own band on every line. Three rows under one
    // heading must not produce four copies of the word.
    expect(find.text('Missed'), findsOneWidget);
  });

  testWidgets('every row offers a way to move it as well as to drop it', (
    WidgetTester tester,
  ) async {
    await pumpPage(tester, <ScreenshotEntity>[
      shot(1, const Duration(hours: -2)),
    ]);

    expect(inRow(find.byIcon(Icons.edit_calendar_rounded)), findsOneWidget);
    expect(inRow(find.byIcon(Icons.close_rounded)), findsOneWidget);
  });

  testWidgets('the due time is itself the control that changes it', (
    WidgetTester tester,
  ) async {
    // Not a separate button repeating a verb on every row — the value is the
    // control, and what a screen reader hears has to say so even though the
    // visible chip carries no words beyond the time.
    await pumpPage(tester, <ScreenshotEntity>[
      shot(1, const Duration(hours: -2)),
    ]);

    expect(
      inRow(find.bySemanticsLabel(RegExp('Change the time'))),
      findsOneWidget,
      reason: 'the chip must announce what pressing it does',
    );
  });

  group('emptying the missed band', () {
    testWidgets('one missed reminder gets no bulk control', (
      WidgetTester tester,
    ) async {
      // It would be a second way to do exactly what the ✕ beside it does.
      await pumpPage(tester, <ScreenshotEntity>[
        shot(1, const Duration(hours: -2)),
      ]);

      expect(find.text('Clear all'), findsNothing);
    });

    testWidgets('several missed reminders get one', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, <ScreenshotEntity>[
        shot(1, const Duration(hours: -3)),
        shot(2, const Duration(hours: -2)),
      ]);

      expect(find.text('Clear all'), findsOneWidget);
    });

    testWidgets('a band of things still to come never offers one', (
      WidgetTester tester,
    ) async {
      // "Clear everything I am waiting for" is not something anybody means to
      // do in a single tap.
      await pumpPage(tester, <ScreenshotEntity>[
        shot(1, const Duration(days: 2)),
        shot(2, const Duration(days: 3)),
      ]);

      expect(find.text('This week'), findsOneWidget);
      expect(find.text('Clear all'), findsNothing);
    });
  });

  /// **How much of a moment a row says, and in what terms.**
  ///
  /// Two rows were getting this wrong in opposite directions, and both were
  /// invisible until the page was read on the day it describes.
  ///
  /// Under *Missed*, every row printed the full date — "Tue, Aug 18, 11:17 AM",
  /// read on Tuesday the 18th. The loudest element of the row, spent restating
  /// the day it is being read on; and a clock time is the one thing a missed
  /// reminder cannot use, because nobody can act at 11:17 AM once it has gone.
  ///
  /// Under *Today*, "2:23 PM" and "9:17 PM" were the same kind of thing, one of
  /// them six minutes away and the other seven hours away.
  group('what a row says about when', () {
    testWidgets('a reminder missed minutes ago says how long, not the date', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, <ScreenshotEntity>[
        shot(1, const Duration(minutes: -4)),
      ]);

      expect(find.text('4 min ago'), findsOneWidget);
      // Today's date has no business on a page being read today.
      expect(find.textContaining('Aug 18'), findsNothing);
    });

    testWidgets('one missed earlier in the day counts in hours', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, <ScreenshotEntity>[
        shot(1, const Duration(hours: -3)),
      ]);

      expect(find.text('3 h ago'), findsOneWidget);
      expect(find.textContaining('Aug 18'), findsNothing);
    });

    testWidgets('one missed days ago keeps its date, which is the handle', (
      WidgetTester tester,
    ) async {
      // **And this row is the last place the app says it.** The reminder sheet
      // prints a moment only while it is still pending, so a missed one has
      // nowhere else to be read — which is why the ladder stops at a day
      // rather than going on to "6 days ago".
      await pumpPage(tester, <ScreenshotEntity>[
        shot(1, const Duration(days: -6)),
      ]);

      expect(find.textContaining('Aug 12'), findsOneWidget);
    });

    testWidgets('one due within the hour says how soon', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, <ScreenshotEntity>[
        shot(1, const Duration(minutes: 6)),
      ]);

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('in 6 min'), findsOneWidget);
    });

    testWidgets('and one due later today goes back to the clock', (
      WidgetTester tester,
    ) async {
      // **Not symmetrical with the past, on purpose.** A time still to come is
      // something to plan around — "9:30 PM" says "after dinner" where "in 7 h"
      // does not — so the future returns to the clock as soon as it is far
      // enough off to plan around. A time already gone can be planned around by
      // nobody, so the past stays relative for a whole day.
      await pumpPage(tester, <ScreenshotEntity>[
        shot(1, const Duration(hours: 7)),
      ]);

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('9:30 PM'), findsOneWidget);
      expect(find.textContaining('in '), findsNothing);
    });

    testWidgets('a moment about to arrive is never "in 0 min"', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, <ScreenshotEntity>[
        shot(1, const Duration(seconds: 20)),
      ]);

      expect(find.text('in 1 min'), findsOneWidget);
    });
  });

  testWidgets('the page keeps up with the clock while it is being looked at', (
    WidgetTester tester,
  ) async {
    // **A relative label is a claim that expires.** Left alone this page would
    // still be saying "in 5 min" a quarter of an hour later — on the screen
    // whose entire purpose is that a moment does not slip past unnoticed. The
    // clock is stood forward here the way it moves on a phone; nothing else
    // happens, and in particular the bloc emits nothing.
    DateTime now = DateTime(2026, 8, 18, 14, 30);

    bloc.push(
      ScreenshotsLoadedState(
        screenshots: <ScreenshotEntity>[shot(1, const Duration(minutes: 5))],
      ),
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (BuildContext context, Widget? _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: testTheme(Brightness.dark),
          home: BlocProvider<ScreenshotsBloc>.value(
            value: bloc,
            child: RemindersPage(clock: () => now),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('in 5 min'), findsOneWidget);

    // Three minutes of phone time, past two ticks of the page's own timer.
    now = now.add(const Duration(minutes: 3));
    await tester.pump(const Duration(seconds: 31));

    expect(find.text('in 2 min'), findsOneWidget);
    expect(find.text('in 5 min'), findsNothing);

    // **And it crosses into Missed by itself**, which is the band's whole job:
    // the reminder came due while somebody was looking straight at it.
    now = now.add(const Duration(minutes: 3));
    await tester.pump(const Duration(seconds: 31));

    expect(find.text('Missed'), findsOneWidget);
    expect(find.text('1 min ago'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
  });
  group('the summary above the list', () {
    testWidgets('is not drawn over an empty list', (WidgetTester tester) async {
      // There is nothing to summarise, and a card reading "0 reminders" over
      // an empty state is the empty state said twice.
      await pumpPage(tester, const <ScreenshotEntity>[]);

      expect(find.text('No reminders'), findsOneWidget);
      // The summary, the band counts and the closing line are the only things
      // on this screen that put a number on it, so no digit anywhere is the
      // whole assertion — and it does not care which of the three appeared.
      expect(
        find.textContaining(RegExp(r'[0-9]')),
        findsNothing,
        reason: 'nothing to count, so nothing counts it',
      );
    });

    testWidgets('leads with what was missed, when something was', (
      WidgetTester tester,
    ) async {
      // The neutral total is the wrong headline when part of it is a problem —
      // the same rule the Home row states at length. The closing line under the
      // list is where the total still belongs.
      await pumpPage(tester, <ScreenshotEntity>[
        shot(1, const Duration(hours: -3)),
        shot(2, const Duration(hours: -1)),
        shot(3, const Duration(days: 2)),
      ]);

      expect(find.text('2 missed reminders'), findsOneWidget);
      expect(find.text('3 reminders'), findsOneWidget);
    });

    testWidgets('says when the next one lands without repeating the row', (
      WidgetTester tester,
    ) async {
      // **The one duplication this screen must not have.** The summary and the
      // first upcoming row sit a few pixels apart and answer the same question
      // about the same moment, so they divide it: the summary says *when* on
      // the clock, the row says *how soon*. A reminder six minutes away reads
      // "Next 2:36 PM" at the top and "in 6 min" on the card, and neither line
      // is the other one again.
      await pumpPage(tester, <ScreenshotEntity>[
        shot(1, const Duration(minutes: 6)),
      ]);

      expect(find.text('Next 2:36 PM'), findsOneWidget);
      expect(find.text('in 6 min'), findsOneWidget);
    });

    testWidgets('and says nothing about a next one when there is none', (
      WidgetTester tester,
    ) async {
      // Every reminder missed means there genuinely is no next one, and a line
      // held open for a sentence with no answer is a line of blank space.
      await pumpPage(tester, <ScreenshotEntity>[
        shot(1, const Duration(hours: -3)),
      ]);

      expect(find.textContaining('Next'), findsNothing);
    });
  });

  testWidgets('the list says where it ends rather than running out', (
    WidgetTester tester,
  ) async {
    // Two cards and then two thirds of a black phone reads as content that
    // failed to load. The closing line is what makes a short list look
    // finished — the same fix, for the same reason, as the intent screen's.
    await pumpPage(tester, <ScreenshotEntity>[
      shot(1, const Duration(hours: -3)),
      shot(2, const Duration(days: 2)),
    ]);

    expect(find.text('2 reminders'), findsOneWidget);
  });

  testWidgets('a band heading stays put while its rows go past', (
    WidgetTester tester,
  ) async {
    // Unpinned, the word that says what every time on screen *means* is gone
    // after two rows — leaving the reader doing exactly the arithmetic the
    // bands were added to spare them.
    await pumpPage(tester, <ScreenshotEntity>[
      shot(1, const Duration(hours: -3)),
    ]);

    final SliverPersistentHeader header = tester.widget<SliverPersistentHeader>(
      find.byType(SliverPersistentHeader).first,
    );
    expect(header.pinned, isTrue);
  });

  testWidgets('the headings of the bands you have passed stay stacked', (
    WidgetTester tester,
  ) async {
    // **Every pinned heading holds at the top, and they accumulate.** They
    // were scoped to their own sections for one revision, which made each
    // band push the last one out on arrival; the stack was preferred and put
    // back. What is pinned here is that decision, because the arrangement is
    // one line of code away from the other one and nothing else would say
    // which was meant.
    //
    // The second band has to be the long one: a list only scrolls as far as it
    // is taller than the phone, so with three rows under each heading the
    // first band never leaves the viewport however hard it is dragged, and the
    // assertion would hold for a reason that has nothing to do with pinning.
    await pumpPage(tester, <ScreenshotEntity>[
      shot(1, const Duration(hours: -5)),
      shot(2, const Duration(hours: -4)),
      shot(3, const Duration(hours: -3)),
      for (int i = 1; i <= 8; i++) shot(10 + i, Duration(hours: i)),
    ]);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final double viewportTop = tester
        .getTopLeft(find.byType(CustomScrollView))
        .dy;
    final double missedTop = tester.getTopLeft(find.text('Missed')).dy;
    final double todayTop = tester.getTopLeft(find.text('Today')).dy;

    expect(
      missedTop,
      greaterThanOrEqualTo(viewportTop),
      reason: 'the band scrolled past keeps its heading on screen',
    );
    expect(
      todayTop,
      greaterThan(missedTop),
      reason: 'and the next one sits under it rather than replacing it',
    );
    expect(
      todayTop - missedTop,
      lessThan(60),
      reason: 'stacked against each other, not separated by the rows between',
    );
  });

  group('what marks a missed reminder', () {
    testWidgets('the alert colour, after a revision in amber', (
      WidgetTester tester,
    ) async {
      // Amber was tried, on the argument that `app_colors.dart` reserves red
      // for the destructive and gives "needs attention, nothing lost" its own
      // hue. It lost on how it looked. The reasoning is kept at `_bandTint`
      // rather than repeated here; this only holds the outcome still, so the
      // next person to reopen it does so on purpose.
      await pumpPage(tester, <ScreenshotEntity>[
        shot(1, const Duration(hours: -3)),
      ]);

      final Text heading = tester.widget<Text>(find.text('Missed'));
      expect(heading.style?.color, AppPalette.dark.error);
    });

    testWidgets('and a weight, which no palette setting can take away', (
      WidgetTester tester,
    ) async {
      // **The signal that survives the accent.** A user can set the app's own
      // colour to the same red as the alert, and then the band is wearing the
      // hue everything else on the phone is wearing. What is left is the
      // shape: a solid node against open rings, and this — a missed card
      // carrying a heavier edge than the rows under every other heading.
      await pumpPage(tester, <ScreenshotEntity>[
        shot(1, const Duration(hours: -3)),
        shot(2, const Duration(hours: 3)),
      ]);

      double edgeOf(int row) {
        final Container card = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(Dismissible).at(row),
                matching: find.byType(Container),
              )
              .first,
        );
        return ((card.decoration! as BoxDecoration).border! as Border)
            .top
            .width;
      }

      expect(
        edgeOf(0),
        greaterThan(edgeOf(1)),
        reason: 'the missed row is marked without reference to any colour',
      );
    });
  });

  group('teaching the swipe', () {
    testWidgets('a new user is told which way does what', (
      WidgetTester tester,
    ) async {
      // Both directions, in words, in the two colours the swipe itself
      // reveals — the row's own controls carry the same glyphs, which is why
      // this counts rather than finds.
      await pumpPage(tester, <ScreenshotEntity>[
        shot(1, const Duration(hours: -3)),
      ]);

      expect(find.text('Swipe a reminder'), findsOneWidget);
      expect(
        find.text('Change the time'),
        findsOneWidget,
        reason: 'the legend names the forward direction',
      );
      expect(
        find.text('Clear'),
        findsOneWidget,
        reason: 'and the one that takes it away',
      );
    });

    testWidgets('but never over an empty list', (WidgetTester tester) async {
      // There is nothing to swipe. An instruction for a gesture that has no
      // target is the definition of a tutorial in the way.
      await pumpPage(tester, const <ScreenshotEntity>[]);

      expect(find.text('Swipe a reminder'), findsNothing);
    });

    testWidgets('and it goes away for good once they have swiped', (
      WidgetTester tester,
    ) async {
      final _RecordingSetReminder setReminder = _RecordingSetReminder();
      if (sl.isRegistered<SetReminderUseCase>()) {
        sl.unregister<SetReminderUseCase>();
      }
      sl.registerSingleton<SetReminderUseCase>(setReminder);

      await pumpPage(tester, <ScreenshotEntity>[
        shot(1, const Duration(hours: -3)),
        shot(2, const Duration(hours: -2)),
      ]);
      expect(find.text('Swipe a reminder'), findsOneWidget);

      await tester.drag(find.byType(Dismissible).first, const Offset(-260, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Swipe a reminder'), findsNothing);
      expect(
        sl<AppPreferences>().hasSwipedReminder,
        isTrue,
        reason: 'recorded, so the next visit does not start the lesson again',
      );
    });

    testWidgets('closing it counts as knowing', (WidgetTester tester) async {
      // Somebody who shuts an instruction has read it. Holding the card there
      // until they perform the gesture is telling a person who understands to
      // prove it first.
      await pumpPage(tester, <ScreenshotEntity>[
        shot(1, const Duration(hours: -3)),
      ]);

      final Finder close = find.descendant(
        of: find.byTooltip('Close'),
        matching: find.byIcon(Icons.close_rounded),
      );
      expect(close, findsOneWidget);

      await tester.tap(close);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Swipe a reminder'), findsNothing);
      expect(sl<AppPreferences>().hasSwipedReminder, isTrue);
    });
  });

  group('the demonstration on the first row', () {
    /// Pumps the page without letting the nudge finish, and hands back a
    /// reader for where the first card currently is.
    ///
    /// [pumpPage] deliberately settles it; every case here is about the
    /// seconds before that, so the frames are walked by hand.
    Future<double Function()> open(
      WidgetTester tester,
      List<ScreenshotEntity> reminders,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      bloc.push(ScreenshotsLoadedState(screenshots: reminders));
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          builder: (BuildContext context, Widget? _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: testTheme(Brightness.dark),
            home: BlocProvider<ScreenshotsBloc>.value(
              value: bloc,
              child: RemindersPage(clock: () => fixedNow),
            ),
          ),
        ),
      );
      // **Past the entrance and short of the nudge, which is a narrow gap.**
      //
      // `EntranceStagger` scales the first rows up from 0.96, and a card that
      // is 4% narrow has its leading edge five pixels right of where it will
      // settle — more than anything here is checked to. Clearing it takes
      // three frames rather than two: the first paints, the second advances
      // the clock far enough for the stagger's zero-delay `Future` to fire and
      // call `forward`, and only the third gives that controller a tick to run
      // on.
      //
      // All of which has to happen inside the nudge's own opening pause of
      // 420ms, or the baseline is taken from a card that has already set off.
      // 0 + 100 + 250 lands at 350, inside the demonstration's opening
      // 500ms of stillness.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 250));
      return () => tester.getTopLeft(find.byType(Dismissible).first).dx;
    }

    testWidgets('shows the gesture by making it, both ways', (
      WidgetTester tester,
    ) async {
      // **The half of the lesson the legend above cannot give.** Words can
      // name a gesture; they cannot show that the card follows your thumb and
      // that a coloured surface comes out from behind it. So the top row does
      // it — out towards the end, back, then out towards the start — and what
      // is pinned here is that both directions are actually performed and that
      // the row is left exactly where it started.
      final double Function() cardX = await open(tester, <ScreenshotEntity>[
        shot(1, const Duration(hours: -3)),
      ]);

      final double home = cardX();

      // Out towards the end of the line, which is rightwards in English.
      // t = 1450ms, inside the hold at full reach (1200-1760) rather than on
      // one of its boundaries.
      await tester.pump(const Duration(milliseconds: 1100));
      final double forward = cardX();
      expect(
        forward,
        greaterThan(home + 40),
        reason: 'the card travels far enough to uncover the panel behind it',
      );

      // Back, then out the other way — t = 3500ms, inside the second hold
      // (3280-3840).
      await tester.pump(const Duration(milliseconds: 2050));
      final double back = cardX();
      expect(
        back,
        lessThan(home - 40),
        reason: 'and then demonstrates the destructive direction too',
      );

      // Finished, and exactly where it began.
      await tester.pump(const Duration(seconds: 4));
      expect(cardX(), moreOrLessEquals(home, epsilon: 0.5));
    });

    testWidgets('gathers itself before it goes, and settles when it lands', (
      WidgetTester tester,
    ) async {
      // **The two beats that separate this from a rectangle sliding about.**
      // Both are a few pixels, both are one edit away from being deleted as
      // noise, and both are the whole reason the second version of this
      // stopped feeling hurried:
      //
      //   * a wind-up — the card gathers itself the *wrong* way before each
      //     reach, because nothing with weight starts moving from perfectly
      //     still;
      //   * a settle — it swings a little past home on the way back, because a
      //     card that stops dead on zero was placed there rather than let go
      //     of.
      final double Function() cardX = await open(tester, <ScreenshotEntity>[
        shot(1, const Duration(hours: -3)),
      ]);
      final double home = cardX();

      // t = 620ms: near the end of the 140ms counter-move, before the reach.
      await tester.pump(const Duration(milliseconds: 270));
      final double wound = cardX();
      expect(
        wound,
        lessThan(home - 4),
        reason: 'the card pulls back before it sets off',
      );
      expect(
        wound,
        greaterThan(home - 25),
        reason:
            'and only just — more than this reads as a stutter, not a '
            'wind-up',
      );

      // t = 2120ms: two thirds through the release, where `easeOutBack` has
      // carried it past home and is bringing it back.
      await tester.pump(const Duration(milliseconds: 1500));
      expect(
        cardX(),
        lessThan(home - 4),
        reason: 'released rather than parked',
      );
    });

    testWidgets('names the surface it is uncovering while it moves', (
      WidgetTester tester,
    ) async {
      // The panel revealed here is the same widget the real gesture reveals,
      // built from the same constructor — so a user who reads it during the
      // demonstration is reading the thing they will see under their thumb.
      // Two copies of the words at this moment is the legend plus the panel,
      // which is the point.
      await open(tester, <ScreenshotEntity>[
        shot(1, const Duration(hours: -3)),
      ]);

      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text('Change the time'), findsNWidgets(2));
    });

    testWidgets('only the first row does it', (WidgetTester tester) async {
      // One demonstration is a demonstration. Every row moving at once is the
      // list having a seizure.
      final double Function() cardX = await open(tester, <ScreenshotEntity>[
        shot(1, const Duration(hours: -3)),
        shot(2, const Duration(hours: -2)),
      ]);

      double secondX() => tester.getTopLeft(find.byType(Dismissible).at(1)).dx;

      final double firstHome = cardX();
      final double secondHome = secondX();

      await tester.pump(const Duration(milliseconds: 1100));

      expect(cardX(), greaterThan(firstHome + 40));
      expect(
        secondX(),
        moreOrLessEquals(secondHome, epsilon: 0.5),
        reason: 'the row under it stays exactly where it was',
      );
    });

    testWidgets('a finger landing on it takes over immediately', (
      WidgetTester tester,
    ) async {
      // An instructive animation that has to finish before you may touch it is
      // a modal dialog wearing a disguise. The offset drops to zero on the
      // same frame the pointer arrives, so a drag starts from where the card
      // looks like it is rather than from wherever the demonstration had
      // carried it.
      final double Function() cardX = await open(tester, <ScreenshotEntity>[
        shot(1, const Duration(hours: -3)),
      ]);
      final double home = cardX();

      await tester.pump(const Duration(milliseconds: 1100));
      expect(cardX(), greaterThan(home + 40));

      // **Pressed where the row is, not where the card has been carried to.**
      // Mid-demonstration the card is translated half its own width, so its
      // centre sits on the outer edge of the row that contains it and a press
      // aimed there lands on nothing. Anywhere inside the row's own box will
      // do — here, just inside its leading edge, which at this moment is the
      // panel the card has slid off.
      final Offset row = tester.getCenter(find.byType(Dismissible).first);
      final TestGesture touch = await tester.startGesture(
        Offset(home + 20, row.dy),
      );
      await tester.pump();

      expect(
        cardX(),
        moreOrLessEquals(home, epsilon: 0.5),
        reason: 'the demonstration gets out of the way of a real gesture',
      );

      await touch.up();
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('and it never runs for a reader who asked for less motion', (
      WidgetTester tester,
    ) async {
      // The most decorative thing on this screen, and so the clearest thing
      // that setting means. The legend stays — it is words, not movement.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      bloc.push(
        ScreenshotsLoadedState(
          screenshots: <ScreenshotEntity>[shot(1, const Duration(hours: -3))],
        ),
      );
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          builder: (BuildContext context, Widget? _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: testTheme(Brightness.dark),
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: BlocProvider<ScreenshotsBloc>.value(
                value: bloc,
                child: RemindersPage(clock: () => fixedNow),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final double home = tester.getTopLeft(find.byType(Dismissible).first).dx;
      await tester.pump(const Duration(milliseconds: 1100));

      expect(
        tester.getTopLeft(find.byType(Dismissible).first).dx,
        moreOrLessEquals(home, epsilon: 0.5),
      );
      expect(find.text('Swipe a reminder'), findsOneWidget);
    });
  });

  group('taking a reminder off', () {
    late _RecordingSetReminder setReminder;

    setUp(() {
      setReminder = _RecordingSetReminder();
      if (sl.isRegistered<SetReminderUseCase>()) {
        sl.unregister<SetReminderUseCase>();
      }
      sl.registerSingleton<SetReminderUseCase>(setReminder);
    });

    testWidgets('takes the row with it, without waiting for the library', (
      WidgetTester tester,
    ) async {
      // **The bloc deliberately never answers here.** `_StubScreenshotsBloc`
      // records the reload and emits nothing, which is exactly the first few
      // hundred milliseconds of the real thing: the write has landed and the
      // photo store has not been re-read yet. That window used to be a row
      // sitting unchanged under a finger that had just removed it.
      await pumpPage(tester, <ScreenshotEntity>[
        shot(1, const Duration(hours: -3)),
      ]);

      expect(find.text('3 h ago'), findsOneWidget);

      await tester.tap(inRow(find.byIcon(Icons.close_rounded)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(setReminder.calls.single.at, isNull);
      expect(
        find.text('3 h ago'),
        findsNothing,
        reason: 'the row leaves on the tap, not on the reload',
      );
    });

    testWidgets('and lets it back in if the library reports it again', (
      WidgetTester tester,
    ) async {
      // The hidden set forgets an id the moment the library stops claiming a
      // reminder for it, which is what makes an undo work without anything on
      // this page having to know that an undo happened.
      await pumpPage(tester, <ScreenshotEntity>[
        shot(1, const Duration(hours: -3)),
      ]);

      await tester.tap(inRow(find.byIcon(Icons.close_rounded)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('3 h ago'), findsNothing);

      // The reload lands, without it. **Two pumps, and the second is the one
      // that matters**: the first only delivers the new state to the
      // `BlocBuilder`, whose `setState` schedules the rebuild that actually
      // prunes the hidden id. Asserting after one frame passes either way —
      // an empty library and a hidden row draw the same empty state — which is
      // exactly why the step after this one has to be here.
      bloc.push(
        ScreenshotsLoadedState(screenshots: const <ScreenshotEntity>[]),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('No reminders'), findsOneWidget);

      // And undo puts it back, which has to be visible.
      bloc.push(
        ScreenshotsLoadedState(
          screenshots: <ScreenshotEntity>[shot(1, const Duration(hours: -3))],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('3 h ago'), findsOneWidget);
    });

    testWidgets('a swipe towards the end does the same thing the cross does', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, <ScreenshotEntity>[
        shot(1, const Duration(hours: -3)),
      ]);

      await tester.drag(find.byType(Dismissible).first, const Offset(-260, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(setReminder.calls.single.at, isNull);
      expect(find.text('3 h ago'), findsNothing);
    });

    testWidgets(
      'and a swipe the other way opens the picker, removing nothing',
      (WidgetTester tester) async {
        // A card that leaves before a new time has been chosen is a promise
        // about what happened that has not been kept — so this one snaps back
        // and the sheet does the talking.
        await pumpPage(tester, <ScreenshotEntity>[
          shot(1, const Duration(hours: -3)),
        ]);

        await tester.drag(find.byType(Dismissible).first, const Offset(260, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          setReminder.calls,
          isEmpty,
          reason: 'nothing is written until a time has been picked',
        );
        expect(
          find.text('Remove reminder'),
          findsOneWidget,
          reason: 'the reminder sheet is what a swipe back opens',
        );
      },
    );
  });
}

/// Records what the page asks to be written, with no database under it.
///
/// The shape the reminder sheet's own suite uses, for the same reason: `null`
/// for the moment is how this app says "clear it", so one recorded call with a
/// null moment is the whole assertion for a removal.
class _RecordingSetReminder implements SetReminderUseCase {
  final List<({String assetId, DateTime? at})> calls =
      <({String assetId, DateTime? at})>[];

  @override
  Future<bool> call(
    String assetId,
    DateTime? at, {
    String title = '',
    String body = '',
  }) async {
    calls.add((assetId: assetId, at: at));
    return true;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubScreenshotsBloc extends Cubit<ScreenshotsState>
    implements ScreenshotsBloc {
  _StubScreenshotsBloc()
    : super(ScreenshotsLoadedState(screenshots: const <ScreenshotEntity>[]));

  final List<ScreenshotsEvent> events = <ScreenshotsEvent>[];

  void push(ScreenshotsState state) => emit(state);

  @override
  void add(ScreenshotsEvent event) => events.add(event);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
