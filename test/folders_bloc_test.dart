import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/domain/entities/folder_seed.dart';
import 'package:shoto/features/folders/domain/repositories/folders_repository.dart';
import 'package:shoto/features/folders/domain/use_cases/create_folder_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/delete_folder_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/get_folders_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/seed_default_folders_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/update_folder_use_case.dart';
import 'package:shoto/features/folders/presentation/bloc/folder_sort.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_event.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_state.dart';

/// [FoldersBloc], against a repository that answers from memory.
///
/// Three things here are load-bearing and none of them is obvious from reading
/// the class:
///
/// * **the grid must not blank.** The shell fires `LoadFoldersEvent` on every
///   visit to the Folders tab, and creating, renaming and deleting all end in a
///   reload too. `FoldersLoadingState` draws *nothing at all* on the page, so
///   emitting it on a reload makes making one folder read as the whole grid
///   vanishing and coming back;
/// * **the sort outlives the reload.** It is held on the bloc precisely because
///   the shell reloads on every tab select, and a sort that resets is a setting
///   the user has to make again every time they look at Library;
/// * **seeding is silent.** It is an offer Shoto made, not a task the user
///   started, so a failure must reach no error state.
void main() {
  FolderEntity folder(
    int id,
    String name, {
    int count = 0,
    DateTime? createdAt,
  }) => FolderEntity(
    id: id,
    name: name,
    color: 0xFF5B8DEF,
    createdAt: createdAt ?? DateTime(2026, 1, id),
    screenshotCount: count,
  );

  late _FakeFoldersRepository repository;

  FoldersBloc buildBloc() => FoldersBloc(
    getFoldersUseCase: GetFoldersUseCase(repository),
    createFolderUseCase: CreateFolderUseCase(repository),
    updateFolderUseCase: UpdateFolderUseCase(repository),
    deleteFolderUseCase: DeleteFolderUseCase(repository),
    seedDefaultFoldersUseCase: SeedDefaultFoldersUseCase(repository),
  );

  setUp(() => repository = _FakeFoldersRepository());

  /// Runs [act] and returns every state the bloc emitted while it ran.
  Future<List<FoldersState>> statesFrom(
    FoldersBloc bloc,
    FutureOr<void> Function() act,
  ) async {
    final List<FoldersState> emitted = <FoldersState>[];
    final StreamSubscription<FoldersState> sub = bloc.stream.listen(
      emitted.add,
    );
    await act();
    // Two turns: the handler awaits the repository, and the reload it chains
    // into awaits it again.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    return emitted;
  }

  group('loading', () {
    test('the very first load announces itself', () async {
      repository.folders = <FolderEntity>[folder(1, 'Recipes')];
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);

      expect(bloc.state, isA<FoldersInitialState>());
      final List<FoldersState> emitted = await statesFrom(
        bloc,
        () => bloc.add(LoadFoldersEvent()),
      );

      expect(emitted.map((FoldersState s) => s.runtimeType), <Type>[
        FoldersLoadingState,
        FoldersLoadedState,
      ]);
      expect((emitted.last as FoldersLoadedState).folders, hasLength(1));
    });

    test('a reload behind a grid that is already right does not', () async {
      // The regression this bloc's longest comment is about: with a
      // `FoldersLoadingState` here, every tab visit and every folder created
      // blanks the page for a frame.
      repository.folders = <FolderEntity>[folder(1, 'Recipes')];
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);
      await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));

      final List<FoldersState> emitted = await statesFrom(
        bloc,
        () => bloc.add(LoadFoldersEvent()),
      );

      expect(emitted.whereType<FoldersLoadingState>(), isEmpty);
      expect(emitted.single, isA<FoldersLoadedState>());
    });

    test('a read that throws becomes an error the page can draw', () async {
      repository.failGet = true;
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);

      final List<FoldersState> emitted = await statesFrom(
        bloc,
        () => bloc.add(LoadFoldersEvent()),
      );

      expect(emitted.last, isA<FoldersErrorState>());
    });

    test('an error state can be recovered from by loading again', () async {
      repository.failGet = true;
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);
      await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));

      repository.failGet = false;
      repository.folders = <FolderEntity>[folder(1, 'Recipes')];
      final List<FoldersState> emitted = await statesFrom(
        bloc,
        () => bloc.add(LoadFoldersEvent()),
      );

      // Not loaded, so the loading state is allowed back — there is genuinely
      // nothing on screen to keep.
      expect(emitted.map((FoldersState s) => s.runtimeType), <Type>[
        FoldersLoadingState,
        FoldersLoadedState,
      ]);
    });
  });

  group('writing', () {
    test('creating carries every choice down and then reloads', () async {
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);

      await statesFrom(
        bloc,
        () => bloc.add(
          CreateFolderEvent(
            'Recipes',
            0xFFF5883C,
            isPrivate: true,
            iconKey: 'food',
          ),
        ),
      );

      expect(repository.created, hasLength(1));
      expect(repository.created.single, <Object?>[
        'Recipes',
        0xFFF5883C,
        true,
        'food',
      ]);
      expect(bloc.state, isA<FoldersLoadedState>());
      expect((bloc.state as FoldersLoadedState).folders, hasLength(1));
    });

    test('editing carries the name, the colour and the glyph', () async {
      repository.folders = <FolderEntity>[folder(7, 'Before')];
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);

      await statesFrom(
        bloc,
        () => bloc.add(
          UpdateFolderEvent(
            7,
            name: 'After',
            color: 0xFF33E0C2,
            iconKey: 'map',
          ),
        ),
      );

      expect(repository.updated.single, <Object?>[
        7,
        'After',
        0xFF33E0C2,
        'map',
      ]);
    });

    test('deleting removes it and the grid follows', () async {
      repository.folders = <FolderEntity>[folder(1, 'Keep'), folder(2, 'Drop')];
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);
      await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));

      await statesFrom(bloc, () => bloc.add(DeleteFolderEvent(2)));

      expect(repository.deleted, <int>[2]);
      expect(
        (bloc.state as FoldersLoadedState).folders.map(
          (FolderEntity f) => f.id,
        ),
        <int>[1],
      );
    });

    test('a failed create is reported, and nothing escapes', () async {
      // The three writes had no `catch` at all: a failure escaped to the
      // bloc's error channel and the page was left as it was, so the folder
      // the user had just named, coloured and drawn simply never appeared.
      repository.folders = <FolderEntity>[folder(1, 'Recipes')];
      final List<Object> escaped = <Object>[];
      late FoldersBloc bloc;

      await runZonedGuarded(() async {
        bloc = buildBloc();
        await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));
        repository.failWrite = true;
        await statesFrom(
          bloc,
          () => bloc.add(CreateFolderEvent('Doomed', 0xFF5B8DEF)),
        );
      }, (Object error, StackTrace stack) => escaped.add(error));
      addTearDown(bloc.close);

      expect(escaped, isEmpty);
      final FoldersLoadedState state = bloc.state as FoldersLoadedState;
      expect(state.failure, AppMessage.saveFolder);
      // **And the grid is still the grid.** The error *state* would have
      // replaced every folder the user has with a panel saying something went
      // wrong, which answers "that folder could not be made" with "your
      // folders are gone".
      expect(state.folders.single.name, 'Recipes');
    });

    test('a failed rename says so too', () async {
      repository.folders = <FolderEntity>[folder(1, 'Recipes')];
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);
      await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));

      repository.failWrite = true;
      await statesFrom(
        bloc,
        () => bloc.add(UpdateFolderEvent(1, name: 'Nope', color: 1)),
      );

      final FoldersLoadedState state = bloc.state as FoldersLoadedState;
      expect(state.failure, AppMessage.saveFolder);
      expect(state.folders.single.name, 'Recipes');
    });

    test('a failed delete says something different', () async {
      // Two sentences rather than one: "could not be saved" is the wrong
      // answer to a folder that is still there.
      repository.folders = <FolderEntity>[folder(1, 'Recipes')];
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);
      await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));

      repository.failWrite = true;
      await statesFrom(bloc, () => bloc.add(DeleteFolderEvent(1)));

      final FoldersLoadedState state = bloc.state as FoldersLoadedState;
      expect(state.failure, AppMessage.deleteFolder);
      expect(state.folders, hasLength(1));
    });

    test('the failure is said once and not again', () async {
      // It rides on exactly the state that follows the failure. A trip to
      // Library and back — which reloads this bloc — must not replay a message
      // about something that went wrong ten minutes ago.
      repository.folders = <FolderEntity>[folder(1, 'Recipes')];
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);
      await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));
      repository.failWrite = true;
      await statesFrom(bloc, () => bloc.add(DeleteFolderEvent(1)));

      repository.failWrite = false;
      await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));
      expect((bloc.state as FoldersLoadedState).failure, isNull);

      // Re-ordering the grid carries nothing over either.
      await statesFrom(bloc, () => bloc.add(DeleteFolderEvent(99)));
      await statesFrom(
        bloc,
        () => bloc.add(SetFolderSortEvent(FolderSort.name)),
      );
      expect((bloc.state as FoldersLoadedState).failure, isNull);
    });

    test('a write that fails still leaves the grid honest', () async {
      // The reload happens either way, so what is on screen is what is
      // actually in the database — not what the user was hoping for.
      repository.folders = <FolderEntity>[folder(1, 'Recipes')];
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);
      await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));
      final int readsBefore = repository.reads;

      repository.failWrite = true;
      await statesFrom(bloc, () => bloc.add(CreateFolderEvent('Doomed', 1)));

      expect(repository.reads, readsBefore + 1);
      expect(
        (bloc.state as FoldersLoadedState).folders.map(
          (FolderEntity f) => f.name,
        ),
        <String>['Recipes'],
      );
    });
  });

  group('the order the grid is in', () {
    final List<FolderEntity> unordered = <FolderEntity>[
      folder(1, 'banking', count: 2, createdAt: DateTime(2026, 1, 5)),
      folder(2, 'Archive', count: 9, createdAt: DateTime(2026, 1, 1)),
      folder(3, 'Zoo', count: 2, createdAt: DateTime(2026, 1, 9)),
    ];

    List<String> namesIn(FoldersBloc bloc) => (bloc.state as FoldersLoadedState)
        .folders
        .map((FolderEntity f) => f.name)
        .toList();

    test('newest first is the default', () async {
      repository.folders = unordered;
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);

      await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));

      expect((bloc.state as FoldersLoadedState).sort, FolderSort.recent);
      expect(namesIn(bloc), <String>['Zoo', 'banking', 'Archive']);
    });

    test('by name ignores case', () async {
      // The reason it is sorted in Dart at all: SQLite's own ordering is by
      // code point, so a lower-case folder would sort after every capitalised
      // one and "banking" would land at the bottom of the grid.
      repository.folders = unordered;
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);
      await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));

      await statesFrom(
        bloc,
        () => bloc.add(SetFolderSortEvent(FolderSort.name)),
      );

      expect(namesIn(bloc), <String>['Archive', 'banking', 'Zoo']);
    });

    test('an accented name sorts where the letter is, not after z', () async {
      // The case this order exists for, and the one it used to get wrong: the
      // bloc's own comment gives "`COLLATE NOCASE` would put 'École' after
      // 'Zoo' on a French phone" as the reason sorting happens in Dart — and
      // `toLowerCase().compareTo(…)` did exactly that, because é is U+00E9.
      repository.folders = <FolderEntity>[
        folder(1, 'Zoo'),
        folder(2, 'École'),
        folder(3, 'Apple'),
        folder(4, 'Über alles'),
        folder(5, 'Straße'),
      ];
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);
      await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));

      await statesFrom(
        bloc,
        () => bloc.add(SetFolderSortEvent(FolderSort.name)),
      );

      expect(namesIn(bloc), <String>[
        'Apple',
        'École',
        'Straße',
        'Über alles',
        'Zoo',
      ]);
    });

    test(
      'two names that differ only in their accents keep a stable order',
      () async {
        // They fold to one string, and `List.sort` is not stable — without the
        // tie-break the two swap places between rebuilds, on a screen that is
        // rebuilt on every tab visit.
        repository.folders = <FolderEntity>[
          folder(1, 'Cafe', createdAt: DateTime(2026, 1, 1)),
          folder(2, 'Café', createdAt: DateTime(2026, 1, 9)),
        ];
        final FoldersBloc bloc = buildBloc();
        addTearDown(bloc.close);
        await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));
        await statesFrom(
          bloc,
          () => bloc.add(SetFolderSortEvent(FolderSort.name)),
        );

        // Newest first among the tied, matching how `fullest` breaks its own.
        expect(namesIn(bloc), <String>['Café', 'Cafe']);

        // And it is the same answer every time the page comes back.
        await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));
        expect(namesIn(bloc), <String>['Café', 'Cafe']);
      },
    );

    test('fullest first, and ties fall back to newest', () async {
      repository.folders = unordered;
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);
      await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));

      await statesFrom(
        bloc,
        () => bloc.add(SetFolderSortEvent(FolderSort.fullest)),
      );

      // 'Zoo' and 'banking' both hold two; the newer one wins, so a screen of
      // equally empty folders is still in a stable order.
      expect(namesIn(bloc), <String>['Archive', 'Zoo', 'banking']);
    });

    test('a chosen order survives the reload the shell fires', () async {
      repository.folders = unordered;
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);
      await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));
      await statesFrom(
        bloc,
        () => bloc.add(SetFolderSortEvent(FolderSort.name)),
      );

      // Walking to Library and back.
      await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));

      expect((bloc.state as FoldersLoadedState).sort, FolderSort.name);
      expect(namesIn(bloc), <String>['Archive', 'banking', 'Zoo']);
    });

    test('a new folder lands in the order that is in force', () async {
      repository.folders = unordered;
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);
      await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));
      await statesFrom(
        bloc,
        () => bloc.add(SetFolderSortEvent(FolderSort.name)),
      );

      await statesFrom(
        bloc,
        () => bloc.add(CreateFolderEvent('Boarding passes', 0xFF5B8DEF)),
      );

      expect(namesIn(bloc), <String>[
        'Archive',
        'banking',
        'Boarding passes',
        'Zoo',
      ]);
    });

    test('re-ordering never goes back to the database', () async {
      // Deliberately not a reload: it would blank the grid through the loading
      // state on the way, for a change that costs a list sort.
      repository.folders = unordered;
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);
      await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));
      final int readsBefore = repository.reads;

      final List<FoldersState> emitted = await statesFrom(
        bloc,
        () => bloc.add(SetFolderSortEvent(FolderSort.fullest)),
      );

      expect(repository.reads, readsBefore);
      expect(emitted.single, isA<FoldersLoadedState>());
    });

    test('choosing an order before anything has loaded is harmless', () async {
      // The sort sheet cannot be reached from a blank page, but the event can
      // arrive first after a process death mid-navigation. It must not throw,
      // and it must not be forgotten.
      repository.folders = unordered;
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);

      final List<FoldersState> emitted = await statesFrom(
        bloc,
        () => bloc.add(SetFolderSortEvent(FolderSort.name)),
      );
      expect(emitted, isEmpty);

      await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));
      expect(namesIn(bloc), <String>['Archive', 'banking', 'Zoo']);
    });

    test('the list the repository handed over is left alone', () async {
      // `_sorted` copies before sorting. Without the copy it re-orders the
      // caller's own list in place — which, when that list is a cache
      // somewhere below, silently changes what every other reader sees.
      final List<FolderEntity> source = <FolderEntity>[
        folder(1, 'banking'),
        folder(2, 'Archive'),
        folder(3, 'Zoo'),
      ];
      repository.folders = source;
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);
      await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));

      await statesFrom(
        bloc,
        () => bloc.add(SetFolderSortEvent(FolderSort.name)),
      );

      expect(source.map((FolderEntity f) => f.name), <String>[
        'banking',
        'Archive',
        'Zoo',
      ]);
    });
  });

  group('the starter folders', () {
    final List<FolderSeed> seeds = <FolderSeed>[
      const FolderSeed(name: 'Trips', color: 0xFF5B8DEF, iconKey: 'map'),
    ];

    test('a set that was written is loaded straight after', () async {
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);

      await statesFrom(bloc, () => bloc.add(SeedDefaultFoldersEvent(seeds)));

      expect(bloc.state, isA<FoldersLoadedState>());
      expect((bloc.state as FoldersLoadedState).folders.single.name, 'Trips');
    });

    test('a set that was already offered costs nothing', () async {
      // The offer has been made before, so the grid on screen is already
      // right — reloading it would blank the page for no change at all.
      repository.seedWritesNothing = true;
      repository.folders = <FolderEntity>[folder(1, 'Mine')];
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);
      await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));
      final int readsBefore = repository.reads;

      final List<FoldersState> emitted = await statesFrom(
        bloc,
        () => bloc.add(SeedDefaultFoldersEvent(seeds)),
      );

      expect(emitted, isEmpty);
      expect(repository.reads, readsBefore);
    });

    test('a failure is swallowed rather than shown', () async {
      // Seeding is something Shoto offered, not something the user asked for.
      // An error banner here would report a task nobody started — and it would
      // be the first thing on screen on a first launch.
      repository.failSeed = true;
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);

      final List<FoldersState> emitted = await statesFrom(
        bloc,
        () => bloc.add(SeedDefaultFoldersEvent(seeds)),
      );

      expect(emitted, isEmpty);
      expect(bloc.state, isA<FoldersInitialState>());
    });

    test('a failure does not stop the page loading afterwards', () async {
      repository.failSeed = true;
      repository.folders = <FolderEntity>[folder(1, 'Mine')];
      final FoldersBloc bloc = buildBloc();
      addTearDown(bloc.close);

      await statesFrom(bloc, () => bloc.add(SeedDefaultFoldersEvent(seeds)));
      await statesFrom(bloc, () => bloc.add(LoadFoldersEvent()));

      expect((bloc.state as FoldersLoadedState).folders, hasLength(1));
    });
  });
}

/// An in-memory folder store, recording what it was asked to do.
class _FakeFoldersRepository implements FoldersRepository {
  List<FolderEntity> folders = <FolderEntity>[];

  final List<List<Object?>> created = <List<Object?>>[];
  final List<List<Object?>> updated = <List<Object?>>[];
  final List<int> deleted = <int>[];

  /// How many times the grid actually went back to storage. The sort path is
  /// specified as *not* doing this.
  int reads = 0;

  bool failGet = false;
  bool failWrite = false;
  bool failSeed = false;
  bool seedWritesNothing = false;

  int _nextId = 100;

  @override
  Future<List<FolderEntity>> getFolders() async {
    reads++;
    if (failGet) throw Exception('the folder table is unreadable');
    return List<FolderEntity>.of(folders);
  }

  @override
  Future<FolderEntity> createFolder(
    String name,
    int color, {
    bool isPrivate = false,
    String? iconKey,
  }) async {
    created.add(<Object?>[name, color, isPrivate, iconKey]);
    if (failWrite) throw Exception('the folder could not be written');
    final FolderEntity made = FolderEntity(
      id: _nextId++,
      name: name,
      color: color,
      // Newest, so a created folder is at the front of the default order.
      createdAt: DateTime(2026, 6, created.length),
      isPrivate: isPrivate,
      iconKey: iconKey,
    );
    folders = <FolderEntity>[...folders, made];
    return made;
  }

  @override
  Future<void> updateFolder(
    int folderId, {
    required String name,
    required int color,
    String? iconKey,
  }) async {
    updated.add(<Object?>[folderId, name, color, iconKey]);
    if (failWrite) throw Exception('the folder could not be written');
    folders = folders
        .map(
          (FolderEntity f) => f.id == folderId
              ? f.copyWith(name: name, color: color, iconKey: iconKey)
              : f,
        )
        .toList();
  }

  @override
  Future<void> deleteFolder(int folderId) async {
    deleted.add(folderId);
    if (failWrite) throw Exception('the folder could not be removed');
    folders = folders.where((FolderEntity f) => f.id != folderId).toList();
  }

  @override
  Future<bool> seedDefaultFolders(List<FolderSeed> seeds) async {
    if (failSeed) throw Exception('the starter folders could not be written');
    if (seedWritesNothing) return false;
    folders = <FolderEntity>[
      ...folders,
      for (int i = 0; i < seeds.length; i++)
        FolderEntity(
          id: _nextId++,
          name: seeds[i].name,
          color: seeds[i].color,
          createdAt: DateTime(2026).subtract(Duration(milliseconds: i)),
          iconKey: seeds[i].iconKey,
        ),
    ];
    return true;
  }
}
