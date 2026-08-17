import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/biometric_auth_service.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/domain/entities/folder_seed.dart';
import 'package:shoto/features/folders/domain/repositories/folders_repository.dart';
import 'package:shoto/features/folders/domain/use_cases/get_folders_use_case.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_event.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_state.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_actions_sheet.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_mark.dart';
import 'package:shoto/features/folders/presentation/widgets/move_to_folder_sheet.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_theme.dart';

/// The two sheets that act on a folder from outside the editor: the one that
/// offers to edit or delete it, and the one that files a screenshot into it.
///
/// Both are shared surfaces — the actions sheet is opened from the grid *and*
/// from a folder's own page, the picker from the library, the detail page and
/// the share flow — so a mistake in either shows up in several places at once
/// and is attributed to none of them.
void main() {
  late _FakeFoldersRepository repository;

  setUpAll(() {
    repository = _FakeFoldersRepository();
    if (!sl.isRegistered<AppPreferences>()) {
      sl.registerLazySingleton<AppPreferences>(() => AppPreferences());
    }
    if (!sl.isRegistered<BiometricAuthService>()) {
      sl.registerLazySingleton<BiometricAuthService>(
        () => BiometricAuthService(),
      );
    }
    // The picker reads the folder list straight from the locator rather than
    // from a bloc — it is opened from places that have no folders bloc above
    // them.
    if (!sl.isRegistered<GetFoldersUseCase>()) {
      sl.registerLazySingleton<GetFoldersUseCase>(
        () => GetFoldersUseCase(repository),
      );
    }
  });

  setUp(() {
    repository.folders = <FolderEntity>[];
    repository.delay = Duration.zero;
  });

  FolderEntity folder(int id, String name, {bool isPrivate = false}) =>
      FolderEntity(
        id: id,
        name: name,
        color: 0xFF5B8DEF,
        createdAt: DateTime(2026, 1, id),
        screenshotCount: 4,
        isPrivate: isPrivate,
        iconKey: 'folder',
      );

  /// Pumps a screen whose only content is a button that opens [open].
  Future<void> pumpOpener(
    WidgetTester tester,
    void Function(BuildContext context) open, {
    FoldersBloc? bloc,

    /// Off for the one test that has to look at the sheet mid-load —
    /// `pumpAndSettle` runs the clock forward until every timer has fired,
    /// which includes the read it is trying to catch in flight.
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final Widget app = ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (BuildContext context, Widget? _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: testTheme(Brightness.dark),
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => open(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      bloc == null
          ? app
          : BlocProvider<FoldersBloc>.value(value: bloc, child: app),
    );
    await tester.tap(find.text('open'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // Long enough for the sheet to have finished arriving, and no longer.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  group('the actions sheet', () {
    late _StubFoldersBloc bloc;
    late List<String> renamed;
    late int deletedCalls;

    setUp(() {
      bloc = _StubFoldersBloc();
      renamed = <String>[];
      deletedCalls = 0;
    });

    tearDown(() => bloc.close());

    Future<void> openActions(WidgetTester tester, {FolderEntity? on}) =>
        pumpOpener(
          tester,
          (BuildContext context) => showFolderActionsSheet(
            context,
            folder: on ?? folder(3, 'Recipes'),
            bloc: bloc,
            onRenamed: renamed.add,
            onDeleted: () => deletedCalls++,
          ),
          bloc: bloc,
        );

    testWidgets('it names the folder it is about', (WidgetTester tester) async {
      // The sheet exists to confirm *which* folder is about to be edited or
      // deleted, and the grid it was opened from tells folders apart by colour
      // and picture — so the same badge comes with the name.
      await openActions(tester);

      expect(find.text('Recipes'), findsOneWidget);
      expect(find.byType(FolderMark), findsOneWidget);
    });

    testWidgets('it says the screenshots inside are kept', (
      WidgetTester tester,
    ) async {
      // The promise the schema keeps with `ON DELETE SET NULL`. If the words
      // ever leave this sheet, deleting a folder becomes a much bigger
      // decision than it looks.
      await openActions(tester);

      expect(find.text('Delete folder'), findsOneWidget);
      expect(find.text('Screenshots inside are kept'), findsOneWidget);
    });

    testWidgets(
      'editing opens the editor on that folder and files the result',
      (WidgetTester tester) async {
        await openActions(tester);

        await tester.tap(find.text('Edit folder'));
        await tester.pumpAndSettle();
        // Opened on the folder: the field already holds its name.
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller?.text,
          'Recipes',
        );

        await tester.enterText(find.byType(TextField), 'Recipes & bakes');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        final Iterable<UpdateFolderEvent> updates = bloc.events
            .whereType<UpdateFolderEvent>();
        expect(updates, hasLength(1));
        expect(updates.single.folderId, 3);
        expect(updates.single.name, 'Recipes & bakes');
        // The detail page uses this to retitle itself.
        expect(renamed, <String>['Recipes & bakes']);
      },
    );

    testWidgets('a save that changed nothing still reports the name', (
      WidgetTester tester,
    ) async {
      // Fired on every save rather than only when the text changed: handing
      // the name over unconditionally is both simpler and correct, and
      // re-titling to the same string costs one `Text` rebuild.
      await openActions(tester);

      await tester.tap(find.text('Edit folder'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(renamed, <String>['Recipes']);
    });

    testWidgets('deleting asks first, naming the folder', (
      WidgetTester tester,
    ) async {
      await openActions(tester);

      await tester.tap(find.text('Delete folder'));
      await tester.pumpAndSettle();

      expect(find.text('Delete "Recipes"?'), findsOneWidget);
      expect(
        find.text(
          'The folder is removed but the screenshots inside stay in your '
          'library.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('backing out of the confirmation deletes nothing', (
      WidgetTester tester,
    ) async {
      await openActions(tester);
      await tester.tap(find.text('Delete folder'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(bloc.events, isEmpty);
      expect(deletedCalls, 0);
    });

    testWidgets('confirming removes it and tells the caller', (
      WidgetTester tester,
    ) async {
      await openActions(tester);
      await tester.tap(find.text('Delete folder'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      final Iterable<DeleteFolderEvent> deletes = bloc.events
          .whereType<DeleteFolderEvent>();
      expect(deletes, hasLength(1));
      expect(deletes.single.folderId, 3);
      // The page showing the folder has to step back — what it displays no
      // longer exists.
      expect(deletedCalls, 1);
    });

    testWidgets('a locked folder is still shown as locked', (
      WidgetTester tester,
    ) async {
      await openActions(tester, on: folder(9, 'Bank', isPrivate: true));

      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });
  });

  group('the folder picker', () {
    late List<int?> chosen;

    setUp(() => chosen = <int?>[]);

    Future<void> openPicker(
      WidgetTester tester, {
      int? currentFolderId,
      bool showNoFolderOption = true,
      String? title,
      String? noFolderLabel,
    }) => pumpOpener(
      tester,
      (BuildContext context) => showMoveToFolderSheet(
        context,
        onSelected: chosen.add,
        currentFolderId: currentFolderId,
        showNoFolderOption: showNoFolderOption,
        title: title,
        noFolderLabel: noFolderLabel,
      ),
    );

    testWidgets('it lists every folder', (WidgetTester tester) async {
      repository.folders = <FolderEntity>[
        folder(1, 'Recipes'),
        folder(2, 'Trips'),
      ];

      await openPicker(tester);

      expect(find.text('Move to folder'), findsOneWidget);
      expect(find.text('Recipes'), findsOneWidget);
      expect(find.text('Trips'), findsOneWidget);
    });

    testWidgets('the folder it is already in is ticked', (
      WidgetTester tester,
    ) async {
      repository.folders = <FolderEntity>[
        folder(1, 'Recipes'),
        folder(2, 'Trips'),
      ];

      await openPicker(tester, currentFolderId: 2);

      // One tick, and it belongs to the row it is on.
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byIcon(Icons.check_rounded),
          matching: find.widgetWithText(ListTile, 'Trips'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a screenshot in no folder ticks the removal row instead', (
      WidgetTester tester,
    ) async {
      repository.folders = <FolderEntity>[folder(1, 'Recipes')];

      await openPicker(tester);

      expect(
        find.ancestor(
          of: find.byIcon(Icons.check_rounded),
          matching: find.widgetWithText(ListTile, 'Remove from folder'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('choosing a folder reports its id and closes', (
      WidgetTester tester,
    ) async {
      repository.folders = <FolderEntity>[
        folder(1, 'Recipes'),
        folder(2, 'Trips'),
      ];

      await openPicker(tester);
      await tester.tap(find.text('Trips'));
      await tester.pumpAndSettle();

      expect(chosen, <int?>[2]);
      expect(find.text('Move to folder'), findsNothing);
    });

    testWidgets('choosing removal reports null', (WidgetTester tester) async {
      repository.folders = <FolderEntity>[folder(1, 'Recipes')];

      await openPicker(tester);
      await tester.tap(find.text('Remove from folder'));
      await tester.pumpAndSettle();

      expect(chosen, <int?>[null]);
    });

    testWidgets('the removal row can be withheld', (WidgetTester tester) async {
      // Filing something for the first time — from the share sheet, say —
      // has nothing to remove it from.
      repository.folders = <FolderEntity>[folder(1, 'Recipes')];

      await openPicker(tester, showNoFolderOption: false);

      expect(find.text('Remove from folder'), findsNothing);
      expect(find.text('Recipes'), findsOneWidget);
    });

    testWidgets('a caller may name the sheet and the removal row itself', (
      WidgetTester tester,
    ) async {
      repository.folders = <FolderEntity>[folder(1, 'Recipes')];

      await openPicker(
        tester,
        title: 'File this screenshot',
        noFolderLabel: 'Keep it loose',
      );

      expect(find.text('File this screenshot'), findsOneWidget);
      expect(find.text('Keep it loose'), findsOneWidget);
      expect(find.text('Move to folder'), findsNothing);
    });

    testWidgets('with no folders it says where to make one', (
      WidgetTester tester,
    ) async {
      await openPicker(tester);

      expect(
        find.text('No folders yet. Create one from the Folders tab.'),
        findsOneWidget,
      );
    });

    testWidgets('it waits visibly while the folders are read', (
      WidgetTester tester,
    ) async {
      // Unlike the grid, this sheet has just been opened by a deliberate tap
      // and has nothing else on it — an empty panel would read as "no
      // folders", which is a different answer.
      repository.delay = const Duration(seconds: 2);
      repository.folders = <FolderEntity>[folder(1, 'Recipes')];

      await pumpOpener(
        tester,
        (BuildContext context) =>
            showMoveToFolderSheet(context, onSelected: chosen.add),
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Recipes'), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Recipes'), findsOneWidget);
    });

    testWidgets('a long list scrolls instead of running off the screen', (
      WidgetTester tester,
    ) async {
      // The yellow overflow stripe this sheet used to show once the library
      // had a dozen folders. The title and the removal row stay put; only the
      // list moves.
      repository.folders = <FolderEntity>[
        for (int i = 1; i <= 30; i++) folder(i, 'Folder $i'),
      ];

      await openPicker(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Move to folder'), findsOneWidget);

      await tester.drag(find.byType(ListTile).first, const Offset(0, -400));
      await tester.pumpAndSettle();

      // The header did not scroll away with the rows.
      expect(find.text('Move to folder'), findsOneWidget);
    });
  });
}

class _StubFoldersBloc extends Cubit<FoldersState> implements FoldersBloc {
  _StubFoldersBloc() : super(FoldersLoadedState(const <FolderEntity>[]));

  final List<FoldersEvent> events = <FoldersEvent>[];

  @override
  void add(FoldersEvent event) => events.add(event);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFoldersRepository implements FoldersRepository {
  List<FolderEntity> folders = <FolderEntity>[];
  Duration delay = Duration.zero;

  @override
  Future<List<FolderEntity>> getFolders() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return folders;
  }

  @override
  Future<FolderEntity> createFolder(
    String name,
    int color, {
    bool isPrivate = false,
    String? iconKey,
  }) => throw UnimplementedError();

  @override
  Future<void> updateFolder(
    int folderId, {
    required String name,
    required int color,
    String? iconKey,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteFolder(int folderId) => throw UnimplementedError();

  @override
  Future<bool> seedDefaultFolders(List<FolderSeed> seeds) =>
      throw UnimplementedError();
}
