import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/core/services/feature_trials.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/core/theme/grid_density_controller.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:shoto/features/screenshots/domain/use_cases/create_custom_intent_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/delete_custom_intent_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_custom_intents_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_intent_ids_by_recent_use_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/update_custom_intent_use_case.dart';
import 'package:shoto/features/screenshots/presentation/bloc/intent_catalog.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_intent.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshot_thumbnail.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshots_body.dart';
import 'package:shoto/features/screenshots/presentation/widgets/selection_toolbar.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/fake_gallery.dart';
import 'support/test_theme.dart';

/// **The Library's selection layer, which had no test at all.**
///
/// `ScreenshotsBody` is the widget behind both the Library tab and every
/// folder, and nothing rendered it. That was survivable while it was stable
/// and stopped being survivable the moment it was rewritten: the selection bar
/// moved from a permanent strip at the top of the page to a card floating over
/// the grid, which hides itself on scroll, and the page header — which used to
/// be torn out for the duration — now stays.
///
/// Each of those is a claim about what is on screen in a state the app reaches
/// dozens of times a day, and every one of them was held up by prose.
class _StubScreenshotsBloc extends Cubit<ScreenshotsState>
    implements ScreenshotsBloc {
  _StubScreenshotsBloc(super.initialState);

  /// Every event the page dispatched, so a control can be proved to be wired
  /// to the right one rather than merely to something.
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

/// Only the three the intent catalog reads at build time.
///
/// The quick-actions sheet a long-press now opens leads with [IntentSection],
/// which stands on the catalog — so without this the sheet throws on the way
/// up and the gesture looks broken for a reason that has nothing to do with
/// the gesture.
class _FakeScreenshotRepository implements ScreenshotRepository {
  @override
  Future<List<CustomIntent>> getCustomIntents() async => const <CustomIntent>[];

  @override
  Future<List<String>> getIntentIdsByRecentUse() async => const <String>[];

  @override
  Future<String?> findLibraryAsset(String assetId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'ScreenshotRepository.${invocation.memberName} was not expected here',
  );
}

ScreenshotEntity _shot(int id, {bool favorite = false, int? folder}) =>
    ScreenshotEntity(
      asset: FakeGallery.asset(id),
      isFavorite: favorite,
      folderId: folder,
    );

/// A library with a filed screenshot and a starred one, so the filter row has
/// a reason to exist — see `small_library_test.dart` for that rule.
List<ScreenshotEntity> _library() => <ScreenshotEntity>[
  _shot(0, folder: 1),
  _shot(1, favorite: true),
  _shot(2),
  _shot(3),
  _shot(4),
  _shot(5),
];

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
    if (!sl.isRegistered<IntentCatalog>()) {
      final _FakeScreenshotRepository repository = _FakeScreenshotRepository();
      sl.registerLazySingleton<IntentCatalog>(
        () => IntentCatalog(
          getCustomIntentsUseCase: GetCustomIntentsUseCase(repository),
          getIntentIdsByRecentUseUseCase: GetIntentIdsByRecentUseUseCase(
            repository,
          ),
          createCustomIntentUseCase: CreateCustomIntentUseCase(repository),
          updateCustomIntentUseCase: UpdateCustomIntentUseCase(repository),
          deleteCustomIntentUseCase: DeleteCustomIntentUseCase(repository),
        ),
      );
    }
  });

  late _StubScreenshotsBloc bloc;

  /// The page header a real host hands down, so "does the header survive
  /// selection" can be asked at all.
  const String headerText = 'Library';

  Future<void> render(WidgetTester tester, ScreenshotsLoadedState state) async {
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
            child: const Scaffold(
              body: ScreenshotsBody(
                emptyTitle: 'Nothing here',
                emptyMessage: 'Share a screenshot in',
                groupByDate: true,
                leadingSlivers: <Widget>[
                  SliverAppBar(pinned: true, title: Text(headerText)),
                ],
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

  group('entering and leaving selection', () {
    testWidgets('with nothing selected there is no toolbar', (tester) async {
      await render(tester, ScreenshotsLoadedState(screenshots: _library()));
      // The bar leaves the tree entirely rather than sitting there invisible —
      // it is frosted, and a `BackdropFilter` over a scrolling grid costs a
      // re-blur every frame whether or not anyone can see it.
      expect(find.byType(SelectionToolbar), findsOneWidget);
      final AppLocalizations l10n = await english();
      expect(find.text(l10n.librarySelectAll), findsNothing);
    });

    testWidgets('selecting one screenshot raises the bar', (tester) async {
      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: _library(),
          selectedIds: <String>{_library().first.id},
        ),
      );
      final AppLocalizations l10n = await english();

      expect(find.text(l10n.librarySelectedCount(1)), findsOneWidget);
      expect(find.text(l10n.librarySelectAll), findsOneWidget);
    });

    testWidgets('the page header stays put while a selection is on', (
      tester,
    ) async {
      // **The regression this test exists for.** Selection used to remove the
      // host's leading slivers, and a `SliverAppBar` is also what holds the
      // first row of thumbnails clear of the status bar — so long-pressing a
      // tile slid the grid up under the clock and read as the page collapsing.
      await render(tester, ScreenshotsLoadedState(screenshots: _library()));
      expect(find.text(headerText), findsOneWidget);

      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: _library(),
          selectedIds: <String>{_library().first.id},
        ),
      );
      expect(
        find.text(headerText),
        findsOneWidget,
        reason: 'the header must survive selection, not be torn out',
      );
    });

    testWidgets('the filter row does leave, because it can hide a selection', (
      tester,
    ) async {
      final AppLocalizations l10n = await english();
      await render(tester, ScreenshotsLoadedState(screenshots: _library()));
      // Present when browsing: this library has a filed and a starred
      // screenshot, so the pills can narrow something.
      expect(find.textContaining(l10n.libraryFilterAll), findsWidgets);

      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: _library(),
          selectedIds: <String>{_library().first.id},
        ),
      );
      // Gone: narrowing to Favourites while three unfiled screenshots are
      // selected hides tiles that are still picked.
      expect(find.textContaining(l10n.libraryFilterAll), findsNothing);
    });
  });

  group('the gesture on a tile', () {
    testWidgets('nothing is drawn on the picture for you to press', (
      tester,
    ) async {
      await render(tester, ScreenshotsLoadedState(screenshots: _library()));

      // **The regression this exists for.** Every tile carried a 17dp "⋯"
      // disc, bottom-right, opening this same sheet. `PressableScale`
      // hit-tests the box it draws, so 17dp was the whole target — under the
      // 48dp Material minimum, the 44pt Apple one and the 24dp floor in WCAG
      // 2.5.8 — and a miss landed on the tile and pushed the full-screen
      // viewer.
      expect(
        find.descendant(
          of: find.byType(ScreenshotThumbnail),
          matching: find.byIcon(Icons.more_horiz_rounded),
        ),
        findsNothing,
        reason: 'a control on a photograph has to be a legal size, or go',
      );
    });

    testWidgets("browsing, a long-press opens that screenshot's own actions", (
      tester,
    ) async {
      await render(tester, ScreenshotsLoadedState(screenshots: _library()));
      final AppLocalizations l10n = await english();

      await tester.longPress(find.byType(ScreenshotThumbnail).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // What the "⋯" used to reach, now on the gesture every photo grid
      // already uses for it.
      expect(find.text(l10n.commonShare), findsOneWidget);
      expect(find.text(l10n.foldersMoveTitle), findsOneWidget);
      expect(find.text(l10n.commonDelete), findsOneWidget);

      // And emphatically *not* the old meaning. A long-press that both opened
      // a sheet and picked the tile underneath it would be two answers to one
      // gesture.
      expect(bloc.events.whereType<ToggleSelectItemEvent>(), isEmpty);
    });

    testWidgets('selecting, a long-press picks instead of opening a sheet', (
      tester,
    ) async {
      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: _library(),
          selectedIds: <String>{_library().first.id},
        ),
      );
      final AppLocalizations l10n = await english();

      await tester.longPress(find.byType(ScreenshotThumbnail).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // A sheet about one screenshot, opened out of a live selection of
      // several, answers a question nobody in that mode is asking.
      expect(find.text(l10n.commonShare), findsNothing);
      expect(bloc.events.whereType<ToggleSelectItemEvent>(), isNotEmpty);
    });
  });

  group('selection the user asked for, before they have picked anything', () {
    testWidgets('says what to do rather than counting to zero', (tester) async {
      await render(
        tester,
        ScreenshotsLoadedState(screenshots: _library(), isSelecting: true),
      );
      final AppLocalizations l10n = await english();

      // Reachable for the first time: the mode used to begin with a
      // long-press, which picks a tile in the same motion, so "in the mode"
      // and "has something selected" could never disagree. The header's
      // Select button separates them.
      expect(find.text(l10n.librarySelectPrompt), findsOneWidget);
      expect(find.text(l10n.librarySelectedCount(0)), findsNothing);
    });

    testWidgets('offers no action it would refuse to perform', (tester) async {
      await render(
        tester,
        ScreenshotsLoadedState(screenshots: _library(), isSelecting: true),
      );
      final AppLocalizations l10n = await english();

      // All three act on the selected set and the bloc refuses each of them on
      // an empty one. Buttons that look ready and do nothing is how somebody
      // concludes the app is broken rather than that they missed a step.
      expect(find.text(l10n.libraryActionMove), findsNothing);
      expect(find.text(l10n.libraryActionDelete), findsNothing);
      expect(find.text(l10n.intentSelectionAction), findsNothing);

      // The two that are not actions on the selection stay: one takes
      // everything, the other is the way out.
      expect(find.text(l10n.librarySelectAll), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });

  group('which actions the bar offers', () {
    testWidgets('one screenshot offers covering, and not merging', (
      tester,
    ) async {
      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: _library(),
          selectedIds: <String>{_library()[0].id},
        ),
      );
      final AppLocalizations l10n = await english();

      // Safe share works on exactly one; merging needs two to have anything
      // to join. An action that cannot run must not be on screen looking like
      // it can.
      expect(find.text(l10n.libraryActionProtect), findsOneWidget);
      expect(find.text(l10n.libraryActionMerge), findsNothing);
      expect(find.text(l10n.libraryActionMove), findsOneWidget);
      expect(find.text(l10n.libraryActionDelete), findsOneWidget);
      expect(find.text(l10n.intentSelectionAction), findsOneWidget);
    });

    testWidgets('two screenshots offer merging, and not covering', (
      tester,
    ) async {
      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: _library(),
          selectedIds: <String>{_library()[0].id, _library()[1].id},
        ),
      );
      final AppLocalizations l10n = await english();

      expect(find.text(l10n.libraryActionMerge), findsOneWidget);
      expect(find.text(l10n.libraryActionProtect), findsNothing);
    });

    testWidgets('a guided job asks for what it needs and offers nothing else', (
      tester,
    ) async {
      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: _library(),
          selectedIds: const <String>{},
          intent: LibraryIntent.protect,
        ),
      );
      final AppLocalizations l10n = await english();

      // Sent here by Home to pick one screenshot to clean. The count answers a
      // question nobody asked; what they need is what to pick.
      expect(find.text(l10n.libraryPickForProtect), findsOneWidget);

      // And none of the actions that belong to selection the user started
      // themselves — one of which is destructive.
      expect(find.text(l10n.librarySelectAll), findsNothing);
      expect(find.text(l10n.libraryActionDelete), findsNothing);
      expect(find.text(l10n.libraryActionMove), findsNothing);
    });

    testWidgets('a guided merge stops asking once it has enough', (
      tester,
    ) async {
      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: _library(),
          selectedIds: <String>{_library()[0].id, _library()[1].id},
          intent: LibraryIntent.merge,
        ),
      );
      final AppLocalizations l10n = await english();

      // Two is enough to merge, so the prompt gives way to the count.
      expect(find.text(l10n.libraryPickForMerge), findsNothing);
      expect(find.text(l10n.librarySelectedCount(2)), findsOneWidget);
      expect(find.text(l10n.libraryActionMerge), findsOneWidget);
    });
  });

  group('the bar gets out of the way', () {
    testWidgets('scrolling down hides it and scrolling back up returns it', (
      tester,
    ) async {
      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: List<ScreenshotEntity>.generate(
            40,
            (int i) => _shot(i % 12, folder: i == 0 ? 1 : null),
          ),
          selectedIds: <String>{_shot(0).id},
        ),
      );
      final AppLocalizations l10n = await english();
      final Finder count = find.text(l10n.librarySelectedCount(1));
      expect(count, findsOneWidget);

      // Past the 26px it takes to mean it. Selecting is a task made of
      // scrolling, and the actions are the one thing nobody needs while
      // looking for the next thing to pick.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(count, findsNothing, reason: 'the bar should stand aside');

      // And back on a nudge — 8px, deliberately less than it took to dismiss,
      // because this bar carries the only way out of the mode.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 60));
      await tester.pumpAndSettle();
      expect(count, findsOneWidget, reason: 'and come straight back');
    });

    testWidgets('picking another screenshot brings it back immediately', (
      tester,
    ) async {
      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: List<ScreenshotEntity>.generate(
            40,
            (int i) => _shot(i % 12, folder: i == 0 ? 1 : null),
          ),
          selectedIds: <String>{_shot(0).id},
        ),
      );
      final AppLocalizations l10n = await english();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(find.text(l10n.librarySelectedCount(1)), findsNothing);

      // A changed selection is the clearest statement that the user is still
      // in the middle of this job, so the bar returns without being scrolled
      // back to.
      bloc.emit(
        ScreenshotsLoadedState(
          screenshots: List<ScreenshotEntity>.generate(
            40,
            (int i) => _shot(i % 12, folder: i == 0 ? 1 : null),
          ),
          selectedIds: <String>{_shot(0).id, _shot(1).id},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.librarySelectedCount(2)), findsOneWidget);
    });
  });

  group('leaving the mode', () {
    testWidgets('the close button clears the selection', (tester) async {
      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: _library(),
          selectedIds: <String>{_library().first.id},
        ),
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(bloc.events.whereType<ClearSelectionEvent>(), isNotEmpty);
    });

    testWidgets('select all asks for every visible screenshot', (tester) async {
      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: _library(),
          selectedIds: <String>{_library().first.id},
        ),
      );
      final AppLocalizations l10n = await english();

      await tester.tap(find.text(l10n.librarySelectAll));
      await tester.pump();

      expect(bloc.events.whereType<SelectAllEvent>(), isNotEmpty);
    });

    testWidgets('the back gesture leaves selection instead of the screen', (
      tester,
    ) async {
      await render(
        tester,
        ScreenshotsLoadedState(
          screenshots: _library(),
          selectedIds: <String>{_library().first.id},
        ),
      );

      // Selection is a state the page is in, and on Android the gesture for
      // "undo the state I just entered" is back. Without the `PopScope` it
      // closed the folder — or dropped out of the app from the library tab —
      // with a live selection nobody had done anything with.
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pump();

      expect(bloc.events.whereType<ClearSelectionEvent>(), isNotEmpty);
    });
  });
}
