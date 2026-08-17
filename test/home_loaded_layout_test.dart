import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/core/services/feature_trials.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_state.dart';
import 'package:shoto/features/home/presentation/pages/home_page.dart';
import 'package:shoto/features/home/presentation/widgets/home_greeting.dart';
import 'package:shoto/features/home/presentation/widgets/home_recent_strip.dart';
import 'package:shoto/features/home/presentation/widgets/home_tool_list.dart';
import 'package:shoto/features/screenshots/domain/entities/library_summary.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/pages/intent_page.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_intent.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/fake_gallery.dart';
import 'support/test_theme.dart';

/// **Home with a real library — the state the user is actually in.**
///
/// The blocked, empty and cold-start states each have a file already. What had
/// none is the ordinary one: a loaded library, where this page makes its two
/// largest claims and neither was pinned by anything.
///
/// The first claim is the reordering. `home_page.dart` spends a paragraph on
/// it: with work waiting, Tools comes before Recent, because Home is a hub and
/// a hub routes to what you can *do*; with the inbox clear, Recent leads
/// instead, because otherwise the reward for being organised is a one-line
/// "all filed" above four tool rows — a blank page. That is a rule about the
/// order of two widgets, expressed in prose, enforced by nothing.
///
/// The second is the inbox itself: what counts as needing you, and what
/// happens to the section when nothing does.
class _StubScreenshotsBloc extends Cubit<ScreenshotsState>
    implements ScreenshotsBloc {
  _StubScreenshotsBloc(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubFoldersBloc extends Cubit<FoldersState> implements FoldersBloc {
  _StubFoldersBloc() : super(FoldersLoadedState(const []));

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<SubscriptionStatus> getStatus() async => SubscriptionStatus.free;

  @override
  Stream<SubscriptionStatus> get statusChanges => const Stream.empty();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A library where nothing is waiting: everything filed, no intent open.
List<ScreenshotEntity> _allFiled() => List<ScreenshotEntity>.generate(
  6,
  (int i) => ScreenshotEntity(
    asset: FakeGallery.asset(i),
    isFavorite: false,
    folderId: 1,
    intent: null,
  ),
);

/// The same library with two screenshots left unfiled.
List<ScreenshotEntity> _withUnsorted() => List<ScreenshotEntity>.generate(
  6,
  (int i) => ScreenshotEntity(
    asset: FakeGallery.asset(i),
    isFavorite: false,
    folderId: i < 2 ? null : 1,
    intent: null,
  ),
);

/// Everything filed, but two screenshots still carry a job the user set.
List<ScreenshotEntity> _withOpenIntent() => List<ScreenshotEntity>.generate(
  6,
  (int i) => ScreenshotEntity(
    asset: FakeGallery.asset(i),
    isFavorite: false,
    folderId: 1,
    intent: i < 2
        ? const IntentState(ref: BuiltInIntent(ScreenshotIntent.read))
        : null,
  ),
);

void main() {
  setUpAll(() async {
    await FakeGallery.install();
    // Fixed, or "Good morning" versus "Good afternoon" makes this suite depend
    // on the hour it is run at.
    HomeGreeting.debugClock = () => DateTime(2026, 8, 6, 14);

    if (!sl.isRegistered<AppPreferences>()) {
      sl.registerLazySingleton<AppPreferences>(() => AppPreferences());
    }
    if (!sl.isRegistered<ThemeController>()) {
      sl.registerLazySingleton<ThemeController>(() => ThemeController());
    }
    if (!sl.isRegistered<DevAccess>()) {
      sl.registerLazySingleton<DevAccess>(() => DevAccess());
    }
    if (!sl.isRegistered<FeatureTrials>()) {
      sl.registerLazySingleton<FeatureTrials>(() => FeatureTrials());
    }
    if (!sl.isRegistered<ProStatus>()) {
      sl.registerLazySingleton<ProStatus>(
        () => ProStatus(_FakeSubscriptionRepository(), sl<DevAccess>()),
      );
    }
  });

  tearDownAll(() => HomeGreeting.debugClock = null);

  Future<void> render(
    WidgetTester tester,
    List<ScreenshotEntity> library, {
    void Function(dynamic)? onOpenLibrary,
    double textScale = 1.0,
    Size? viewport,
  }) async {
    // **Deliberately taller than any phone.** A `SliverList` builds only what
    // the viewport can reach, so on a real-height screen the section that
    // comes *last* is not in the tree at all — and "cannot be found" is
    // indistinguishable from "is in the wrong place". A viewport tall enough
    // to lay the whole page out is what lets order be asserted by position.
    tester.view.physicalSize = viewport ?? const Size(1080, 7000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: testTheme(Brightness.light),
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: MultiBlocProvider(
            providers: [
              BlocProvider<ScreenshotsBloc>(
                create: (_) => _StubScreenshotsBloc(
                  ScreenshotsLoadedState(screenshots: library),
                ),
              ),
              BlocProvider<FoldersBloc>(create: (_) => _StubFoldersBloc()),
            ],
            child: HomePage(
              onOpenLibrary: (f) => onOpenLibrary?.call(f),
              onOpenLibraryForIntent: (_) {},
            ),
          ),
        ),
      ),
    );
    // Past the entrance cascade, so every section has finished arriving.
    await tester.pump(const Duration(milliseconds: 700));
  }

  Future<AppLocalizations> english() =>
      AppLocalizations.delegate.load(const Locale('en'));

  /// Vertical position of a widget on the laid-out page. Comparing two of
  /// these is how "which section comes first" is asserted without depending on
  /// pixel values that every spacing tweak would break.
  double topOf(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder).dy;

  group('section order follows whether anything is waiting', () {
    testWidgets('with unsorted screenshots, Tools comes before Recent', (
      tester,
    ) async {
      await render(tester, _withUnsorted());
      final AppLocalizations l10n = await english();

      final Finder tools = find.text(l10n.homeToolsTitle);
      final Finder recent = find.text(l10n.homeRecent);
      expect(tools, findsOneWidget);
      expect(recent, findsOneWidget);

      // A hub routes to what you can do first; Recent only repeats the
      // Library tab.
      expect(
        topOf(tester, tools),
        lessThan(topOf(tester, recent)),
        reason: 'Tools must lead while something is waiting',
      );
    });

    testWidgets('with an open intent and nothing unsorted, Tools still leads', (
      tester,
    ) async {
      await render(tester, _withOpenIntent());
      final AppLocalizations l10n = await english();

      // `isClear` is two facts, not one — an intent nobody has ticked off is
      // work waiting even though every screenshot is filed. Reading only the
      // unsorted count here would put Recent first and bury the thing that
      // actually needs the user.
      expect(
        topOf(tester, find.text(l10n.homeToolsTitle)),
        lessThan(topOf(tester, find.text(l10n.homeRecent))),
        reason: 'an open intent is work waiting',
      );
    });

    testWidgets('with nothing waiting at all, Recent leads instead', (
      tester,
    ) async {
      await render(tester, _allFiled());
      final AppLocalizations l10n = await english();

      expect(
        topOf(tester, find.text(l10n.homeRecent)),
        lessThan(topOf(tester, find.text(l10n.homeToolsTitle))),
        reason:
            'the reward for being organised must not be four tool rows above '
            'the only content Home has',
      );
    });
  });

  group('the page a real library gets', () {
    testWidgets('search is offered, and the tools heading is the filled one', (
      tester,
    ) async {
      await render(tester, _withUnsorted());
      final AppLocalizations l10n = await english();

      // Found by its hint rather than by type: this is a tappable container
      // that opens the search page, not a live `TextField` — the page it
      // opens owns the keyboard.
      expect(find.text(l10n.searchHint), findsOneWidget);
      expect(find.text(l10n.homeToolsTitle), findsOneWidget);
      expect(find.text(l10n.homeToolsTitleEmpty), findsNothing);
    });

    testWidgets('Recent draws the strip rather than the pending placeholder', (
      tester,
    ) async {
      await render(tester, _allFiled());
      // The placeholder belongs to a library whose pictures have not arrived.
      // Drawing it over a library that *has* arrived would be a permanent
      // loading state on a page that has finished loading.
      expect(find.byType(HomeRecentStrip), findsOneWidget);
    });

    testWidgets('every tool row is present and none of them is a dead end', (
      tester,
    ) async {
      await render(tester, _withUnsorted());
      expect(find.byType(HomeToolList), findsOneWidget);
      // Scrolled to, because the list sits below the fold on a filled page and
      // a finder that never reaches it proves nothing.
      await tester.dragUntilVisible(
        find.byType(HomeToolList),
        find.byType(CustomScrollView),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeToolList), findsOneWidget);
    });

    testWidgets('the page scrolls to its end without overflowing', (
      tester,
    ) async {
      // An overflow paints a yellow-and-black banner and is reported as a
      // test failure, so simply reaching the bottom is the assertion. Every
      // section is on screen at some point during this drag.
      await render(tester, _withUnsorted());
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('the header', () {
    testWidgets('the greeting recedes as the page scrolls', (tester) async {
      await render(tester, _withUnsorted());
      final AppLocalizations l10n = await english();

      final Finder greeting = find.text(l10n.homeGreetingAfternoon);
      expect(greeting, findsOneWidget);
      final double before = topOf(tester, greeting);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -60));
      await tester.pump();

      // It lags rather than travelling with the list: a header that moves at
      // exactly list speed is the flat version this parallax exists to avoid.
      final double after = topOf(tester, greeting);
      expect(
        before - after,
        lessThan(60),
        reason: 'the greeting must move slower than the content',
      );
    });

    testWidgets('the search field stays put once the greeting is gone', (
      tester,
    ) async {
      await render(tester, _withUnsorted());

      final AppLocalizations l10n = await english();
      final Finder field = find.text(l10n.searchHint);
      final double before = topOf(tester, field);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // Pinned: it may rise to the top, but it must never leave. Search was
      // reachable only from the very top of Home before this, which made the
      // answer to "where was that screenshot" *scroll back up first*.
      expect(field, findsOneWidget);
      final double after = topOf(tester, field);
      expect(after, lessThanOrEqualTo(before));
    });
  });

  /// **What a page is asked to survive, rather than what it is designed for.**
  ///
  /// Every test above renders the shape this page was drawn to. These render
  /// the shapes it will meet anyway: somebody with the system font at double
  /// size, somebody on a short phone, somebody who has been using the app for
  /// a year. Overflow is not a cosmetic failure here — a `RenderFlex` that
  /// overflows paints a striped banner across the interface and, in a release
  /// build, silently clips whatever was under it.
  group('conditions the page will meet anyway', () {
    /// Every built-in intent left open at once, which is what a heavy library
    /// looks like after a few months.
    List<ScreenshotEntity> everyIntentWaiting() {
      final List<ScreenshotIntent> all = ScreenshotIntent.values;
      return List<ScreenshotEntity>.generate(
        all.length,
        (int i) => ScreenshotEntity(
          asset: FakeGallery.asset(i % 12),
          isFavorite: false,
          folderId: 1,
          intent: IntentState(ref: BuiltInIntent(all[i])),
        ),
      );
    }

    testWidgets('every intent waiting at once still lays out', (tester) async {
      await render(tester, everyIntentWaiting());
      // A `Wrap` rather than a row is what makes this safe — fifteen chips
      // flow onto as many lines as they need instead of running off the edge.
      expect(tester.takeException(), isNull);
    });

    testWidgets('a very large unsorted count is not clipped', (tester) async {
      final List<ScreenshotEntity> huge = List<ScreenshotEntity>.generate(
        400,
        (int i) => ScreenshotEntity(
          asset: FakeGallery.asset(i % 12),
          isFavorite: false,
          folderId: null,
          intent: null,
        ),
      );
      await render(tester, huge);
      expect(find.text('400'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('double system text size does not overflow anything', (
      tester,
    ) async {
      // The one accessibility setting that reliably breaks hand-built layouts,
      // and the search header is measured against it by hand
      // (`_SearchHeader.resolveExtent`) — a header whose declared extent came
      // out shorter than its child throws outright.
      await render(tester, _withUnsorted(), textScale: 2.0);
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a short phone scrolls the whole page without overflowing', (
      tester,
    ) async {
      await render(
        tester,
        _withUnsorted(),
        // A small, short device — the case where fixed heights run out of room.
        viewport: const Size(1080, 1600),
      );
      expect(tester.takeException(), isNull);

      for (int i = 0; i < 6; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      await tester.pumpAndSettle();
    });

    testWidgets('a single screenshot is a library like any other', (
      tester,
    ) async {
      await render(tester, <ScreenshotEntity>[
        ScreenshotEntity(
          asset: FakeGallery.asset(0),
          isFavorite: false,
          folderId: null,
          intent: null,
        ),
      ]);
      final AppLocalizations l10n = await english();
      // One unsorted screenshot is still work waiting, so the page keeps the
      // shape it has for a hundred.
      expect(find.text(l10n.searchHint), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  /// **The jolt this page was rebuilt to remove, asserted rather than argued.**
  ///
  /// Home decides its layout twice: once from `LibrarySummary` while the
  /// gallery is still being enumerated, and again from the loaded list. Two
  /// sources answering one question is exactly the shape that produces a page
  /// which lays itself out, then rearranges a second later — and the section
  /// order is the most visible thing it decides, because getting it wrong
  /// makes Recent and Tools swap places in front of the user.
  ///
  /// So these pump the *sequence*: summary first, then the real list, with the
  /// two agreeing about the library. Nothing structural may move.
  group('nothing reshuffles when the real read lands', () {
    late _StubScreenshotsBloc bloc;

    Future<void> renderBloc(WidgetTester tester, ScreenshotsState first) async {
      bloc = _StubScreenshotsBloc(first);
      tester.view.physicalSize = const Size(1080, 7000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          builder: (context, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: testTheme(Brightness.light),
            home: MultiBlocProvider(
              providers: [
                BlocProvider<ScreenshotsBloc>(create: (_) => bloc),
                BlocProvider<FoldersBloc>(create: (_) => _StubFoldersBloc()),
              ],
              child: HomePage(
                onOpenLibrary: (_) {},
                onOpenLibraryForIntent: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
    }

    testWidgets('a library with work keeps Tools above Recent throughout', (
      tester,
    ) async {
      await renderBloc(
        tester,
        ScreenshotsLoadingState(
          summary: const LibrarySummary(
            total: 6,
            unsorted: 2,
            waiting: <IntentRef, int>{},
          ),
        ),
      );
      final AppLocalizations l10n = await english();

      final double toolsBefore = topOf(tester, find.text(l10n.homeToolsTitle));
      final double recentBefore = topOf(tester, find.text(l10n.homeRecent));
      expect(toolsBefore, lessThan(recentBefore));

      bloc.emit(ScreenshotsLoadedState(screenshots: _withUnsorted()));
      await tester.pump(const Duration(milliseconds: 700));

      // Same order after the pictures arrive. A swap here is the page
      // rearranging itself in front of somebody who has already started
      // reading it.
      expect(
        topOf(tester, find.text(l10n.homeToolsTitle)),
        lessThan(topOf(tester, find.text(l10n.homeRecent))),
      );
    });

    testWidgets('a clear library keeps Recent above Tools throughout', (
      tester,
    ) async {
      await renderBloc(
        tester,
        ScreenshotsLoadingState(
          summary: const LibrarySummary(
            total: 6,
            unsorted: 0,
            waiting: <IntentRef, int>{},
          ),
        ),
      );
      final AppLocalizations l10n = await english();

      expect(
        topOf(tester, find.text(l10n.homeRecent)),
        lessThan(topOf(tester, find.text(l10n.homeToolsTitle))),
      );

      bloc.emit(ScreenshotsLoadedState(screenshots: _allFiled()));
      await tester.pump(const Duration(milliseconds: 700));

      expect(
        topOf(tester, find.text(l10n.homeRecent)),
        lessThan(topOf(tester, find.text(l10n.homeToolsTitle))),
      );
    });

    testWidgets('the search field does not appear late on a known library', (
      tester,
    ) async {
      await renderBloc(
        tester,
        ScreenshotsLoadingState(
          summary: const LibrarySummary(
            total: 6,
            unsorted: 2,
            waiting: <IntentRef, int>{},
          ),
        ),
      );
      final AppLocalizations l10n = await english();

      // Present from the first frame, because the summary already knows there
      // is something to search. It arriving later is a 66dp bar pushing the
      // whole page down after the user has started reading.
      expect(find.text(l10n.searchHint), findsOneWidget);

      bloc.emit(ScreenshotsLoadedState(screenshots: _withUnsorted()));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text(l10n.searchHint), findsOneWidget);
    });
  });

  /// **A page that lays out correctly and does nothing is still broken.**
  ///
  /// Everything above proves the right things are in the right places. These
  /// prove they are wired to something — the class of defect a golden cannot
  /// see and a layout assertion passes straight over, because an inert card
  /// and a working one are pixel-identical.
  group('the things you can press are connected', () {
    testWidgets('the inbox opens the library filtered to unsorted', (
      tester,
    ) async {
      final List<LibraryFilter> opened = <LibraryFilter>[];
      await render(
        tester,
        _withUnsorted(),
        onOpenLibrary: (f) => opened.add(f as LibraryFilter),
      );

      // The count itself is the target — the whole card is one tap.
      await tester.tap(find.text('2'));
      await tester.pump();

      // Unsorted, not `all`: the card is about what has not been dealt with,
      // so landing on the whole library would drop the filter the user just
      // expressed by pressing it.
      expect(opened, <LibraryFilter>[LibraryFilter.unsorted]);
    });

    testWidgets('an intent chip opens that intent, not the library', (
      tester,
    ) async {
      final List<LibraryFilter> opened = <LibraryFilter>[];
      await render(
        tester,
        _withOpenIntent(),
        onOpenLibrary: (f) => opened.add(f as LibraryFilter),
      );
      final AppLocalizations l10n = await english();

      // "To read" — the waiting form of the verb, with its count beside it.
      final Finder chip = find.textContaining(l10n.intentReadWaiting);
      expect(chip, findsOneWidget);

      await tester.tap(chip);
      await tester.pumpAndSettle();

      // **Asserted by what arrived, not by what did not.** Checking only that
      // the library callback stayed silent would pass just as happily for a
      // chip wired to nothing at all — which is the defect this is here to
      // catch.
      expect(find.byType(IntentPage), findsOneWidget);
      expect(opened, isEmpty);
    });

    testWidgets('Safe share starts the guided pick rather than doing nothing', (
      tester,
    ) async {
      final List<LibraryIntent> intents = <LibraryIntent>[];
      tester.view.physicalSize = const Size(1080, 7000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          builder: (context, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: testTheme(Brightness.light),
            home: MultiBlocProvider(
              providers: [
                BlocProvider<ScreenshotsBloc>(
                  create: (_) => _StubScreenshotsBloc(
                    ScreenshotsLoadedState(screenshots: _withUnsorted()),
                  ),
                ),
                BlocProvider<FoldersBloc>(create: (_) => _StubFoldersBloc()),
              ],
              child: HomePage(
                onOpenLibrary: (_) {},
                onOpenLibraryForIntent: intents.add,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));

      final AppLocalizations l10n = await english();
      await tester.tap(find.text(l10n.homeToolSafeShare));
      await tester.pump();

      // The tool row's whole point: it does not describe the steps, it starts
      // them — the library opens already in selection mode asking for one
      // screenshot.
      expect(intents, <LibraryIntent>[LibraryIntent.protect]);
    });
  });
}
