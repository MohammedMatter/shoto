import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/core/services/feature_trials.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/core/theme/grid_density_controller.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/utils/content_traits.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/widgets/date_section_header.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshots_body.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/fake_gallery.dart';
import 'support/test_theme.dart';

/// **Browsing the Library — the other half of `ScreenshotsBody`.**
///
/// `library_selection_test.dart` covers the mode you enter by long-pressing.
/// This covers the state you are in the rest of the time, and in particular
/// the four different ways the grid can come back with nothing in it.
///
/// Those four are worth separating because they are four different claims and
/// only one of them is usually true: an empty *library* is a first run, an
/// empty *Unsorted* is the best possible outcome, an empty *Favourites* is a
/// feature nobody has used, and an empty *lens* is either "you have none of
/// these" or "nothing that has been read has these" — which are not the same
/// sentence and the app must not guess between them.
class _StubScreenshotsBloc extends Cubit<ScreenshotsState>
    implements ScreenshotsBloc {
  _StubScreenshotsBloc(super.initialState);

  final List<ScreenshotsEvent> events = <ScreenshotsEvent>[];

  @override
  void add(ScreenshotsEvent event) => events.add(event);

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

/// An asset captured on a chosen day, which `FakeGallery.asset` cannot express
/// — and the date is the whole subject of the grouping tests below.
AssetEntity _asset(int id, DateTime taken) => AssetEntity(
  id: '$id',
  typeInt: AssetType.image.index,
  width: 1080,
  height: 2340,
  createDateSecond: taken.millisecondsSinceEpoch ~/ 1000,
);

ScreenshotEntity _shot(
  int id, {
  bool favorite = false,
  int? folder,
  DateTime? taken,
}) => ScreenshotEntity(
  asset: taken == null ? FakeGallery.asset(id) : _asset(id, taken),
  isFavorite: favorite,
  folderId: folder,
);

void main() {
  setUpAll(() async {
    await FakeGallery.install();
    if (!sl.isRegistered<AppPreferences>()) {
      sl.registerLazySingleton<AppPreferences>(() => AppPreferences());
    }
    if (!sl.isRegistered<ThemeController>()) {
      sl.registerLazySingleton<ThemeController>(() => ThemeController());
    }
    if (!sl.isRegistered<GridDensityController>()) {
      sl.registerLazySingleton<GridDensityController>(
        () => GridDensityController(),
      );
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

  late _StubScreenshotsBloc bloc;

  Future<void> render(
    WidgetTester tester,
    ScreenshotsState state, {
    bool groupByDate = true,
  }) async {
    bloc = _StubScreenshotsBloc(state);
    tester.view.physicalSize = const Size(1080, 2400);
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
          home: BlocProvider<ScreenshotsBloc>.value(
            value: bloc,
            child: Scaffold(
              body: ScreenshotsBody(
                emptyTitle: 'Nothing kept yet',
                emptyMessage: 'Share a screenshot into Shoto',
                groupByDate: groupByDate,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<AppLocalizations> english() =>
      AppLocalizations.delegate.load(const Locale('en'));

  group('the four different ways to come back empty', () {
    testWidgets('an empty library uses the words the host supplied', (
      tester,
    ) async {
      await render(tester, ScreenshotsLoadedState(screenshots: const []));
      // The Library tab and a folder say different things here, which is why
      // the copy is a parameter rather than a constant.
      expect(find.text('Nothing kept yet'), findsOneWidget);
      expect(find.text('Share a screenshot into Shoto'), findsOneWidget);
    });

    testWidgets('an empty Unsorted is congratulated, not apologised for', (
      tester,
    ) async {
      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: <ScreenshotEntity>[
            _shot(0, folder: 1),
            _shot(1, favorite: true),
          ],
          filter: LibraryFilter.unsorted,
        ),
      );
      final AppLocalizations l10n = await english();

      // Everything is filed. That is the best possible outcome, and the
      // library's own empty sentence would call it a failure.
      expect(find.text(l10n.libraryNoUnsortedTitle), findsOneWidget);
      expect(find.text('Nothing kept yet'), findsNothing);
    });

    testWidgets('an empty Favourites says nobody has starred anything', (
      tester,
    ) async {
      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: <ScreenshotEntity>[_shot(0, folder: 1), _shot(1)],
          filter: LibraryFilter.favorites,
        ),
      );
      final AppLocalizations l10n = await english();

      expect(find.text(l10n.libraryNoFavoritesTitle), findsOneWidget);
      expect(find.text(l10n.libraryNoUnsortedTitle), findsNothing);
    });

    testWidgets('a lens that matched nothing offers a way back out', (
      tester,
    ) async {
      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: <ScreenshotEntity>[_shot(0, folder: 1)],
          lens: ContentTrait.link,
          // Everything has been read, so "you have none of these" is the true
          // sentence.
          traits: <String, Set<ContentTrait>>{
            '0': <ContentTrait>{},
          },
          traitsReady: true,
        ),
      );
      final AppLocalizations l10n = await english();

      expect(find.text(l10n.libraryNoTraitMessage), findsOneWidget);
      // A dead end is the failure mode here: the only route back is a control
      // the empty state has to supply itself.
      expect(find.text(l10n.libraryShowAll), findsOneWidget);
    });

    testWidgets('a lens over unread screenshots admits it has not looked', (
      tester,
    ) async {
      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: <ScreenshotEntity>[_shot(0, folder: 1), _shot(1)],
          lens: ContentTrait.link,
          // Nothing has been read, so no trait can be seen — and claiming the
          // library has no links would be a false negative dressed as a fact.
          traits: const <String, Set<ContentTrait>>{},
          traitsReady: true,
        ),
      );
      final AppLocalizations l10n = await english();

      expect(find.text(l10n.libraryNoTraitUnreadMessage(2)), findsOneWidget);
      expect(find.text(l10n.libraryNoTraitMessage), findsNothing);
    });

    testWidgets('leaving the lens is wired to the event that clears it', (
      tester,
    ) async {
      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: <ScreenshotEntity>[_shot(0, folder: 1)],
          lens: ContentTrait.link,
          traits: <String, Set<ContentTrait>>{
            '0': <ContentTrait>{},
          },
          traitsReady: true,
        ),
      );
      final AppLocalizations l10n = await english();

      await tester.tap(find.text(l10n.libraryShowAll));
      await tester.pump();

      expect(bloc.events.whereType<SetLibraryLensEvent>(), isNotEmpty);
    });
  });

  group('dated headings earn their place', () {
    testWidgets('one day of captures gets no heading at all', (tester) async {
      final DateTime day = DateTime(2026, 8, 13, 10);
      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: <ScreenshotEntity>[
            for (int i = 0; i < 6; i++)
              _shot(i, folder: 1, taken: day.add(Duration(minutes: i))),
          ],
        ),
      );

      // A heading over the only section on screen divides nothing from
      // nothing — it just moves the first row down by its own height.
      expect(find.byType(DateSectionHeader), findsNothing);
    });

    testWidgets('two days of captures get them', (tester) async {
      // **Relative to the clock, because the buckets are.**
      //
      // These were two fixed dates two days apart, which is a *different*
      // number of groups depending on when the suite runs: 13 and 11 August
      // are "this week" and "earlier this week" for a few days after them, and
      // then one single "this week" run — one group, no headings, red test. It
      // failed on 16 August 2026 for exactly that reason and would have gone
      // green again on its own two days later.
      //
      // The grid reads `DateTime.now()` itself, so the fixture cannot inject a
      // clock; what it can do is pick two moments that no clock can put in the
      // same bucket. Today and forty days ago are always two groups.
      final DateTime today = DateTime.now();
      final DateTime longAgo = today.subtract(const Duration(days: 40));
      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: <ScreenshotEntity>[
            for (int i = 0; i < 3; i++)
              _shot(i, folder: 1, taken: today.subtract(Duration(minutes: i))),
            for (int i = 3; i < 6; i++)
              _shot(
                i,
                folder: 1,
                taken: longAgo.subtract(Duration(minutes: i)),
              ),
          ],
        ),
      );

      expect(find.byType(DateSectionHeader), findsWidgets);
    });

    testWidgets('a host that asked for no grouping never gets headings', (
      tester,
    ) async {
      // A folder holds one subject rather than one stretch of time, so dated
      // headings there slice a small curated set into runs of one.
      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: <ScreenshotEntity>[
            for (int i = 0; i < 3; i++)
              _shot(i, folder: 1, taken: DateTime(2026, 8, 13, 10 + i)),
            for (int i = 3; i < 6; i++)
              _shot(i, folder: 1, taken: DateTime(2026, 8, 11, 10 + i - 3)),
          ],
        ),
        groupByDate: false,
      );

      expect(find.byType(DateSectionHeader), findsNothing);
    });
  });

  group('the filter row is a control, not a label', () {
    testWidgets('tapping a pill asks the bloc to narrow the grid', (
      tester,
    ) async {
      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: <ScreenshotEntity>[
            _shot(0, folder: 1),
            _shot(1, favorite: true),
            _shot(2),
          ],
        ),
      );
      final AppLocalizations l10n = await english();

      await tester.tap(find.textContaining(l10n.libraryFilterUnsorted).first);
      await tester.pump();

      final Iterable<SetLibraryFilterEvent> asked = bloc.events
          .whereType<SetLibraryFilterEvent>();
      expect(asked, isNotEmpty);
      expect(asked.last.filter, LibraryFilter.unsorted);
    });
  });
}
