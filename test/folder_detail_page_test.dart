import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart' show BiometricType;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/biometric_auth_service.dart';
import 'package:shoto/core/theme/grid_density_controller.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_event.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_state.dart';
import 'package:shoto/features/folders/presentation/pages/folder_detail_page.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshots_body.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_theme.dart';

/// A folder's own page, and the lock in front of it.
///
/// The lock is the part worth testing hardest. A private folder is the one
/// place in Shoto where the app has promised something it cannot take back if
/// it gets it wrong: that what is inside is not visible until a fingerprint
/// says so. "Not visible" has to mean the grid is never built — not that it is
/// built and covered — because a page that loads a locked folder's screenshots
/// behind its own lock screen has already put them in memory, in a hero tag,
/// and one dropped `if` away from the screen.
void main() {
  late _FakeBiometricAuthService biometrics;
  late _StubScreenshotsBloc screenshots;

  setUpAll(() {
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
  });

  setUp(() {
    biometrics = _FakeBiometricAuthService();
    screenshots = _StubScreenshotsBloc();
    // Registered fresh per test: what the fake is told to answer is the whole
    // subject of half this file.
    if (sl.isRegistered<BiometricAuthService>()) {
      sl.unregister<BiometricAuthService>();
    }
    sl.registerSingleton<BiometricAuthService>(biometrics);
    if (sl.isRegistered<ScreenshotsBloc>()) sl.unregister<ScreenshotsBloc>();
    sl.registerFactory<ScreenshotsBloc>(() => screenshots);
  });

  // Deliberately **not** closed here. The page owns this bloc — it builds it
  // through `BlocProvider(create:)` and closes it on dispose — so a second
  // close from the test hangs the tear-down. The folders bloc below is handed
  // over with `.value` and therefore is the test's to close.

  FolderEntity folder({bool isPrivate = false, String name = 'Recipes'}) =>
      FolderEntity(
        id: 3,
        name: name,
        color: 0xFF5B8DEF,
        createdAt: DateTime(2026),
        screenshotCount: 7,
        isPrivate: isPrivate,
        iconKey: 'food',
      );

  late _StubFoldersBloc foldersBloc;

  setUp(() => foldersBloc = _StubFoldersBloc());
  tearDown(() => foldersBloc.close());

  /// Bounded pumps rather than `pumpAndSettle`, matching what the library's
  /// own tests do: `ScreenshotsBody` keeps a frame callback alive, so settling
  /// on this page never returns. 600ms is past every entrance on it — the
  /// sheet, the dialog and the empty state included.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> pumpPage(WidgetTester tester, FolderEntity on) async {
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
            value: foldersBloc,
            child: FolderDetailPage(folder: on),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  group('an ordinary folder', () {
    testWidgets('opens straight onto its screenshots', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, folder());

      expect(find.byType(ScreenshotsBody), findsOneWidget);
      expect(find.text('Unlock'), findsNothing);
    });

    testWidgets('asks for exactly the screenshots in that folder', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, folder());

      final Iterable<LoadScreenshotsEvent> loads = screenshots.events
          .whereType<LoadScreenshotsEvent>();
      expect(loads, hasLength(1));
      expect(loads.single.folderId, 3);
    });

    testWidgets('the header names the folder and counts what is in it', (
      WidgetTester tester,
    ) async {
      // The count is read live from the grid's own bloc rather than from the
      // entity, which was counted when the *folders* grid loaded and is stale
      // the moment anything here is moved out.
      screenshots.push(
        ScreenshotsLoadedState(screenshots: const <ScreenshotEntity>[]),
      );
      await pumpPage(tester, folder());

      expect(find.text('Recipes'), findsWidgets);
      expect(
        find.text('No screenshots'),
        findsWidgets,
        reason: 'the header reported the stale count from the tile',
      );
    });
  });

  group('a private folder', () {
    testWidgets('opens locked, and offers the way in', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, folder(isPrivate: true, name: 'Bank'));

      expect(find.text('Bank'), findsOneWidget);
      expect(
        find.text('This folder is protected. Authenticate to view it.'),
        findsOneWidget,
      );
      expect(find.text('Unlock'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('its screenshots are never asked for while it is locked', (
      WidgetTester tester,
    ) async {
      // The load must not be in flight behind the lock screen. Nothing about
      // the folder's contents may exist before the fingerprint.
      await pumpPage(tester, folder(isPrivate: true));

      expect(find.byType(ScreenshotsBody), findsNothing);
      expect(screenshots.events, isEmpty);
    });

    testWidgets('a refused fingerprint leaves it locked', (
      WidgetTester tester,
    ) async {
      biometrics.succeeds = false;
      await pumpPage(tester, folder(isPrivate: true));

      await tester.tap(find.text('Unlock'));
      await settle(tester);

      expect(find.text('Unlock'), findsOneWidget);
      expect(find.byType(ScreenshotsBody), findsNothing);
      expect(screenshots.events, isEmpty);
    });

    testWidgets('a refusal can be answered by trying again', (
      WidgetTester tester,
    ) async {
      biometrics.succeeds = false;
      await pumpPage(tester, folder(isPrivate: true));
      await tester.tap(find.text('Unlock'));
      await settle(tester);

      biometrics.succeeds = true;
      await tester.tap(find.text('Unlock'));
      await settle(tester);

      expect(find.byType(ScreenshotsBody), findsOneWidget);
    });

    testWidgets('an accepted fingerprint opens it', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, folder(isPrivate: true));

      await tester.tap(find.text('Unlock'));
      await settle(tester);

      expect(find.text('Unlock'), findsNothing);
      expect(find.byType(ScreenshotsBody), findsOneWidget);
      expect(
        screenshots.events.whereType<LoadScreenshotsEvent>().single.folderId,
        3,
      );
    });

    testWidgets('the prompt says which folder is being opened', (
      WidgetTester tester,
    ) async {
      await pumpPage(tester, folder(isPrivate: true, name: 'Bank'));

      await tester.tap(find.text('Unlock'));
      await settle(tester);

      expect(biometrics.reasons, <String>['Unlock "Bank"']);
    });

    testWidgets('the button names the gesture this phone actually asks for', (
      WidgetTester tester,
    ) async {
      // A fingerprint glyph on a phone that unlocks by face is a small lie
      // about what the next tap will do.
      biometrics.kind = BiometricKind.face;
      await pumpPage(tester, folder(isPrivate: true));

      expect(find.byIcon(Icons.face_rounded), findsOneWidget);
      expect(find.byIcon(Icons.fingerprint_rounded), findsNothing);
    });

    testWidgets('and falls back to the fingerprint when Android will not say', (
      WidgetTester tester,
    ) async {
      biometrics.kind = BiometricKind.unknown;
      await pumpPage(tester, folder(isPrivate: true));

      expect(find.byIcon(Icons.fingerprint_rounded), findsOneWidget);
    });
  });

  group('the count on the tile behind', () {
    ScreenshotEntity shot(String id) => ScreenshotEntity(
      asset: AssetEntity(id: id, typeInt: 1, width: 100, height: 100),
      isFavorite: false,
      folderId: 3,
    );

    testWidgets('follows screenshots leaving the folder', (
      WidgetTester tester,
    ) async {
      // **The bug this exists for.** The page runs its own `ScreenshotsBloc`
      // — the DI registers a factory — so moving screenshots out of a folder,
      // or deleting them, was invisible to the grid underneath. The grid
      // reloads on tab select and on app resume, and neither happens on the
      // way back from here, so a folder you had just emptied went on saying
      // "24 screenshots".
      screenshots.push(
        ScreenshotsLoadedState(
          screenshots: <ScreenshotEntity>[shot('a'), shot('b'), shot('c')],
        ),
      );
      await pumpPage(tester, folder());
      foldersBloc.events.clear();

      // Two moved out, the way `MoveSelectedToFolderEvent` leaves this list:
      // the bloc re-filters on its own folder id, so they are simply gone.
      screenshots.push(
        ScreenshotsLoadedState(screenshots: <ScreenshotEntity>[shot('c')]),
      );
      await settle(tester);

      expect(foldersBloc.events.whereType<LoadFoldersEvent>(), hasLength(1));
    });

    testWidgets('and screenshots being deleted', (WidgetTester tester) async {
      screenshots.push(
        ScreenshotsLoadedState(
          screenshots: <ScreenshotEntity>[shot('a'), shot('b')],
        ),
      );
      await pumpPage(tester, folder());
      foldersBloc.events.clear();

      screenshots.push(
        ScreenshotsLoadedState(screenshots: const <ScreenshotEntity>[]),
      );
      await settle(tester);

      expect(foldersBloc.events.whereType<LoadFoldersEvent>(), hasLength(1));
    });

    testWidgets('but not for a visit that changed no count', (
      WidgetTester tester,
    ) async {
      // Favouriting, selecting, scrolling: all of them emit, none of them
      // changes what the tile says. Reloading the grid for those would put a
      // database read behind every tap on a thumbnail.
      screenshots.push(
        ScreenshotsLoadedState(
          screenshots: <ScreenshotEntity>[shot('a'), shot('b')],
        ),
      );
      await pumpPage(tester, folder());
      foldersBloc.events.clear();

      screenshots.push(
        ScreenshotsLoadedState(
          screenshots: <ScreenshotEntity>[shot('a'), shot('b')],
          selectedIds: <String>{'a'},
        ),
      );
      await settle(tester);

      expect(foldersBloc.events, isEmpty);
    });

    testWidgets('and not merely for opening the folder', (
      WidgetTester tester,
    ) async {
      // The first load goes from nothing to N, which is a change in length
      // and is not a change in the world.
      screenshots.push(
        ScreenshotsLoadedState(screenshots: const <ScreenshotEntity>[]),
      );
      await pumpPage(tester, folder());

      expect(foldersBloc.events, isEmpty);
    });
  });

  group('editing from inside the folder', () {
    testWidgets('a rename retitles the page without leaving it', (
      WidgetTester tester,
    ) async {
      // Held in state rather than read off the widget, so the header does not
      // show the old name until you navigate away and back.
      await pumpPage(tester, folder());

      await tester.tap(find.byTooltip('Folder options'));
      await settle(tester);
      await tester.tap(find.text('Edit folder'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'Recipes & bakes');
      await settle(tester);
      await tester.tap(find.text('Save'));
      await settle(tester);

      expect(find.text('Recipes & bakes'), findsWidgets);
      expect(find.text('Recipes'), findsNothing);
      expect(foldersBloc.events.whereType<UpdateFolderEvent>(), hasLength(1));
    });

    testWidgets('a delete steps back to the grid', (WidgetTester tester) async {
      // The folder this page exists to show is gone; there is nothing left to
      // display.
      await pumpPage(tester, folder());

      await tester.tap(find.byTooltip('Folder options'));
      await settle(tester);
      await tester.tap(find.text('Delete folder'));
      await settle(tester);
      await tester.tap(find.text('Delete').last);
      await settle(tester);

      expect(foldersBloc.events.whereType<DeleteFolderEvent>(), hasLength(1));
      // Popped: with nothing beneath it in this test's navigator, the page
      // itself is what leaves.
      expect(find.byType(FolderDetailPage), findsNothing);
    });
  });
}

/// A biometric prompt that answers however the test tells it to.
class _FakeBiometricAuthService implements BiometricAuthService {
  bool succeeds = true;
  BiometricKind kind = BiometricKind.fingerprint;

  /// Every reason string the prompt was raised with — this is the line the
  /// user reads on the system dialog.
  final List<String> reasons = <String>[];

  @override
  Future<bool> authenticate({required String reason}) async {
    reasons.add(reason);
    return succeeds;
  }

  @override
  Future<BiometricKind> enrolledKind() async => kind;

  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<List<BiometricType>> availableBiometrics() async =>
      const <BiometricType>[];

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

class _StubFoldersBloc extends Cubit<FoldersState> implements FoldersBloc {
  _StubFoldersBloc() : super(FoldersLoadedState(const <FolderEntity>[]));

  final List<FoldersEvent> events = <FoldersEvent>[];

  @override
  void add(FoldersEvent event) => events.add(event);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
