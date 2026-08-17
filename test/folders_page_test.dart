import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/biometric_auth_service.dart';
import 'package:shoto/core/services/funnel_log.dart';
import 'package:shoto/features/folders/domain/entities/folder_seed.dart';
import 'package:shoto/features/folders/domain/repositories/folders_repository.dart';
import 'package:shoto/features/folders/domain/use_cases/get_folders_use_case.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:shoto/features/subscription/domain/use_cases/get_subscription_status_use_case.dart';
import 'package:shoto/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:shoto/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:shoto/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:shoto/features/subscription/presentation/pages/paywall_page.dart';
import 'package:shoto/core/theme/folder_appearance_controller.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/widgets/empty_state.dart';
import 'package:shoto/core/widgets/header_icon_button.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/presentation/bloc/folder_sort.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_event.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_state.dart';
import 'package:shoto/features/folders/presentation/pages/folders_page.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_card.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_search_field.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_theme.dart';

/// The Folders tab: which of its five states it draws, and what the search row
/// does to the grid.
///
/// The states are a sealed `switch` with no `default`, which is the codebase's
/// standing answer to "a state nobody drew is a blank screen". One of the five
/// deliberately *is* blank, and that exemption is the thing most likely to
/// spread by accident — so it is pinned here rather than left to a reading.
void main() {
  /// What the folder cap sees. Empty by default — these tests are about the
  /// page, and a gate that fired on every one of them would be testing the
  /// gate twice.
  final _GateFolders gateFolders = _GateFolders();
  setUp(() => gateFolders.count = 0);

  setUpAll(() {
    if (!sl.isRegistered<FolderAppearanceController>()) {
      sl.registerLazySingleton<FolderAppearanceController>(
        () => FolderAppearanceController(),
      );
    }
    if (!sl.isRegistered<AppPreferences>()) {
      sl.registerLazySingleton<AppPreferences>(() => AppPreferences());
    }
    if (!sl.isRegistered<BiometricAuthService>()) {
      sl.registerLazySingleton<BiometricAuthService>(
        () => BiometricAuthService(),
      );
    }
    if (!sl.isRegistered<ThemeController>()) {
      sl.registerLazySingleton<ThemeController>(() => ThemeController());
    }
    if (!sl.isRegistered<FunnelLog>()) {
      sl.registerLazySingleton<FunnelLog>(() => FunnelLog());
    }
    // Making a folder now passes the free tier's folder cap first, and the
    // gate counts for itself rather than trusting the grid — so the page
    // cannot open its editor without these two.
    if (!sl.isRegistered<GetFoldersUseCase>()) {
      sl.registerLazySingleton<GetFoldersUseCase>(
        () => GetFoldersUseCase(gateFolders),
      );
    }
    if (!sl.isRegistered<GetSubscriptionStatusUseCase>()) {
      sl.registerLazySingleton<GetSubscriptionStatusUseCase>(
        () => GetSubscriptionStatusUseCase(_FreeSubscription()),
      );
    }
    if (!sl.isRegistered<SubscriptionBloc>()) {
      sl.registerFactory<SubscriptionBloc>(() => _StubSubscriptionBloc());
    }
  });

  FolderEntity folder(int id, String name, {int count = 0}) => FolderEntity(
    id: id,
    name: name,
    color: 0xFF5B8DEF,
    createdAt: DateTime(2026, 1, id),
    screenshotCount: count,
    iconKey: 'folder',
  );

  late _StubFoldersBloc bloc;

  setUp(() => bloc = _StubFoldersBloc());
  tearDown(() => bloc.close());

  Future<void> pumpPage(WidgetTester tester, FoldersState state) async {
    bloc.push(state);

    tester.view.physicalSize = const Size(1080, 1920);
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
          home: BlocProvider<FoldersBloc>.value(
            value: bloc,
            child: const FoldersPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The header button behind a tooltip. `find.byTooltip` lands on the tooltip
  /// itself, which is two widgets below the one holding the state.
  HeaderIconButton buttonAt(WidgetTester tester, String tooltip) =>
      tester.widget<HeaderIconButton>(
        find.ancestor(
          of: find.byTooltip(tooltip),
          matching: find.byType(HeaderIconButton),
        ),
      );

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(FolderSearchField), query);
    await tester.pumpAndSettle();
  }

  group('the five states', () {
    testWidgets('nothing is drawn while the folders are being read', (
      WidgetTester tester,
    ) async {
      // The one branch in the app allowed to draw nothing, and it is written
      // out so the next state added here cannot inherit the exemption by
      // accident. Reading the table is a local query measured in
      // milliseconds; a spinner here is a flash, dozens of times a session.
      await pumpPage(tester, FoldersLoadingState());

      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(FolderCard), findsNothing);
      // The title stays: the page is not blank, its *body* is.
      expect(find.text('Folders'), findsOneWidget);
    });

    testWidgets('the same is true before anything has been asked for', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, FoldersInitialState());

      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a failed read says so in words', (WidgetTester tester) async {
      await pumpPage(tester, FoldersErrorState(AppMessage.loadFolders));

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      // The message resolves against the locale rather than arriving
      // pre-translated from the bloc.
      expect(find.text('Could not load your folders.'), findsOneWidget);
    });

    testWidgets('an empty grid asks for the first folder and nothing else', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, FoldersLoadedState(const <FolderEntity>[]));

      expect(find.text('No folders yet'), findsOneWidget);
      expect(find.text('New folder'), findsOneWidget);
      // **The controls go with the grid.** A search field over an empty
      // screen is furniture for a job there is nothing to do.
      expect(find.byType(FolderSearchField), findsNothing);
      expect(find.byTooltip('Sort folders'), findsNothing);
    });

    testWidgets('a full grid draws a card each, with the controls', (
      WidgetTester tester,
    ) async {
      await pumpPage(
        tester,
        FoldersLoadedState(<FolderEntity>[
          folder(1, 'Recipes', count: 4),
          folder(2, 'Trips'),
          folder(3, 'Money'),
        ]),
      );

      expect(find.byType(FolderCard), findsNWidgets(3));
      expect(find.byType(FolderSearchField), findsOneWidget);
      expect(find.byTooltip('Sort folders'), findsOneWidget);
      expect(find.byType(EmptyState), findsNothing);
    });
  });

  group('searching', () {
    Future<void> pumpThree(WidgetTester tester) => pumpPage(
      tester,
      FoldersLoadedState(<FolderEntity>[
        folder(1, 'Recipes'),
        folder(2, 'Receipts'),
        folder(3, 'Trips'),
      ]),
    );

    testWidgets('typing narrows the grid', (WidgetTester tester) async {
      await pumpThree(tester);

      await search(tester, 'Rec');

      expect(find.byType(FolderCard), findsNWidgets(2));
      expect(find.text('Trips'), findsNothing);
    });

    testWidgets('case does not matter', (WidgetTester tester) async {
      await pumpThree(tester);

      await search(tester, 'TRIPS');

      expect(find.byType(FolderCard), findsOneWidget);
      expect(find.text('Trips'), findsOneWidget);
    });

    testWidgets('it matches the middle of a name, not only the start', (
      WidgetTester tester,
    ) async {
      await pumpThree(tester);

      await search(tester, 'cip');

      expect(find.text('Recipes'), findsOneWidget);
      expect(find.byType(FolderCard), findsOneWidget);
    });

    testWidgets('surrounding spaces are ignored', (WidgetTester tester) async {
      await pumpThree(tester);

      await search(tester, '  trips  ');

      expect(find.byType(FolderCard), findsOneWidget);
    });

    testWidgets('a search that matches nothing quotes what was asked for', (
      WidgetTester tester,
    ) async {
      await pumpThree(tester);

      await search(tester, 'zzz');

      expect(find.byType(FolderCard), findsNothing);
      expect(find.text('No folder matches'), findsOneWidget);
      expect(
        find.text('Nothing here is called "zzz". Try part of the name.'),
        findsOneWidget,
      );
    });

    testWidgets('an accented name is found by its plain spelling', (
      WidgetTester tester,
    ) async {
      // Six of the seven shipped languages have accents, and typing one costs
      // two presses — so "cafe" is how somebody looks for "Café" on the phone
      // they already own.
      await pumpPage(
        tester,
        FoldersLoadedState(<FolderEntity>[folder(1, 'Café')]),
      );

      await search(tester, 'cafe');
      expect(find.byType(FolderCard), findsOneWidget);

      await search(tester, 'café');
      expect(find.byType(FolderCard), findsOneWidget);
    });

    testWidgets('and a plain name is found by an accented query', (
      WidgetTester tester,
    ) async {
      // The fold runs on both sides, so it is not a trick that only works one
      // way — somebody with an accented keyboard finds the folder they typed
      // without one.
      await pumpPage(
        tester,
        FoldersLoadedState(<FolderEntity>[folder(1, 'Cafe')]),
      );

      await search(tester, 'café');

      expect(find.byType(FolderCard), findsOneWidget);
    });

    testWidgets('German eszett matches the way German spells it', (
      WidgetTester tester,
    ) async {
      await pumpPage(
        tester,
        FoldersLoadedState(<FolderEntity>[folder(1, 'Straße 12')]),
      );

      await search(tester, 'strasse');

      expect(find.byType(FolderCard), findsOneWidget);
    });

    testWidgets('clearing the field brings the whole grid back', (
      WidgetTester tester,
    ) async {
      await pumpThree(tester);
      await search(tester, 'Trips');
      expect(find.byType(FolderCard), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(FolderCard), findsNWidgets(3));
    });

    testWidgets('the clear button is only there while there is text', (
      WidgetTester tester,
    ) async {
      await pumpThree(tester);
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      await search(tester, 'a');

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('a narrowed grid does not narrow what is stored', (
      WidgetTester tester,
    ) async {
      // Searching is a view over the state, not an event. If it ever became
      // one, walking to Library and back would come home to a filtered grid.
      await pumpThree(tester);

      await search(tester, 'Trips');

      expect(bloc.events, isEmpty);
    });
  });

  group('a write that failed', () {
    testWidgets('is said out loud, over a grid that stays put', (
      WidgetTester tester,
    ) async {
      // The bloc reloads either way and carries the message on the loaded
      // state — see `FoldersLoadedState.failure`. What the page owes it is one
      // passing sentence, not the error panel: replacing the grid would answer
      // "that folder could not be made" with "your folders are gone".
      await pumpPage(
        tester,
        FoldersLoadedState(<FolderEntity>[folder(1, 'Recipes')]),
      );

      bloc.push(
        FoldersLoadedState(<FolderEntity>[
          folder(1, 'Recipes'),
        ], failure: AppMessage.saveFolder),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not save that folder.'), findsOneWidget);
      expect(find.byType(FolderCard), findsOneWidget);
      expect(find.byType(EmptyState), findsNothing);
    });

    testWidgets('a failed delete says the other sentence', (
      WidgetTester tester,
    ) async {
      await pumpPage(
        tester,
        FoldersLoadedState(<FolderEntity>[folder(1, 'Recipes')]),
      );

      bloc.push(
        FoldersLoadedState(<FolderEntity>[
          folder(1, 'Recipes'),
        ], failure: AppMessage.deleteFolder),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not delete that folder.'), findsOneWidget);
    });

    testWidgets('an ordinary state says nothing', (WidgetTester tester) async {
      await pumpPage(
        tester,
        FoldersLoadedState(<FolderEntity>[folder(1, 'Recipes')]),
      );

      bloc.push(FoldersLoadedState(<FolderEntity>[folder(1, 'Recipes')]));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('the sort control', () {
    testWidgets('it carries no dot while the grid is in its default order', (
      WidgetTester tester,
    ) async {
      await pumpPage(
        tester,
        FoldersLoadedState(<FolderEntity>[folder(1, 'Recipes')]),
      );

      expect(buttonAt(tester, 'Sort folders').isMarked, isFalse);
    });

    testWidgets('a chosen order lights it', (WidgetTester tester) async {
      // A control that hides a setting and looks identical either way is
      // worse than no control.
      await pumpPage(
        tester,
        FoldersLoadedState(<FolderEntity>[
          folder(1, 'Recipes'),
        ], sort: FolderSort.name),
      );

      expect(buttonAt(tester, 'Sort folders').isMarked, isTrue);
    });

    testWidgets('picking an order raises it as an event', (
      WidgetTester tester,
    ) async {
      await pumpPage(
        tester,
        FoldersLoadedState(<FolderEntity>[folder(1, 'Recipes')]),
      );

      await tester.tap(find.byTooltip('Sort folders'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Most screenshots'));
      await tester.pumpAndSettle();

      expect(bloc.events.whereType<SetFolderSortEvent>(), hasLength(1));
      expect(
        bloc.events.whereType<SetFolderSortEvent>().single.sort,
        FolderSort.fullest,
      );
    });

    testWidgets('picking the order it is already in raises nothing', (
      WidgetTester tester,
    ) async {
      await pumpPage(
        tester,
        FoldersLoadedState(<FolderEntity>[
          folder(1, 'Recipes'),
        ], sort: FolderSort.name),
      );

      await tester.tap(find.byTooltip('Sort folders'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Name (A–Z)'));
      await tester.pumpAndSettle();

      expect(bloc.events, isEmpty);
    });
  });

  group('making one', () {
    testWidgets('the header button opens the editor and files the result', (
      WidgetTester tester,
    ) async {
      await pumpPage(
        tester,
        FoldersLoadedState(<FolderEntity>[folder(1, 'Recipes')]),
      );

      await tester.tap(find.byTooltip('Create folder'));
      await tester.pumpAndSettle();
      // Scoped to the sheet: the search row behind it holds a text field too,
      // and this is the one place in the app where both are on screen at once.
      await tester.enterText(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(TextField),
        ),
        'Boarding passes',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create folder').last);
      await tester.pumpAndSettle();

      final Iterable<CreateFolderEvent> created = bloc.events
          .whereType<CreateFolderEvent>();
      expect(created, hasLength(1));
      expect(created.single.name, 'Boarding passes');
    });

    testWidgets('so does the button on the empty state', (
      WidgetTester tester,
    ) async {
      // Two entry points, one of which is the only one a brand-new install
      // ever sees.
      await pumpPage(tester, FoldersLoadedState(const <FolderEntity>[]));

      await tester.tap(find.text('New folder'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Recipes');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create folder'));
      await tester.pumpAndSettle();

      expect(bloc.events.whereType<CreateFolderEvent>().single.name, 'Recipes');
    });

    testWidgets('the cap is asked before the editor opens', (
      WidgetTester tester,
    ) async {
      // Refusing *after* somebody has named, coloured and drawn a folder
      // spends their attention and then throws the result away — so the
      // question is asked first, and what they meet is the paywall rather
      // than a sheet that will not save.
      gateFolders.count = 3;
      await pumpPage(
        tester,
        FoldersLoadedState(<FolderEntity>[
          folder(1, 'A'),
          folder(2, 'B'),
          folder(3, 'C'),
        ]),
      );

      await tester.tap(find.byTooltip('Create folder'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(PaywallPage), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(bloc.events, isEmpty);
    });

    testWidgets('dismissing the editor makes no folder', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, FoldersLoadedState(const <FolderEntity>[]));

      await tester.tap(find.text('New folder'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Half a thought');
      await tester.pumpAndSettle();
      // Out through the barrier, which is how most sheets are actually left.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(bloc.events, isEmpty);
    });
  });
}

/// The folder list the cap counts, sized per test.
class _GateFolders implements FoldersRepository {
  int count = 0;

  @override
  Future<List<FolderEntity>> getFolders() async => <FolderEntity>[
    for (int i = 1; i <= count; i++)
      FolderEntity(
        id: i,
        name: 'Folder $i',
        color: 0xFF5B8DEF,
        createdAt: DateTime(2026, 1, i),
      ),
  ];

  @override
  Future<bool> seedDefaultFolders(List<FolderSeed> seeds) async => false;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FreeSubscription implements SubscriptionRepository {
  @override
  Future<SubscriptionStatus> getStatus() async => SubscriptionStatus.free;

  @override
  Stream<SubscriptionStatus> get statusChanges => const Stream.empty();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubSubscriptionBloc extends Cubit<SubscriptionState>
    implements SubscriptionBloc {
  _StubSubscriptionBloc() : super(SubscriptionLoadingState());

  @override
  void add(SubscriptionEvent event) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A [FoldersBloc] whose state the test sets by hand, recording what the page
/// asks it to do.
///
/// `implements` rather than a real bloc with fake use cases: this file is
/// about what the page draws for a given state, and building the state
/// directly is the only way to reach the two it is hard to provoke — the
/// blank one and the failed read.
class _StubFoldersBloc extends Cubit<FoldersState> implements FoldersBloc {
  _StubFoldersBloc() : super(FoldersInitialState());

  final List<FoldersEvent> events = <FoldersEvent>[];

  void push(FoldersState state) => emit(state);

  @override
  void add(FoldersEvent event) => events.add(event);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
