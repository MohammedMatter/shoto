import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/constants/subscription_constants.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/app_locales.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/funnel_log.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/domain/entities/folder_seed.dart';
import 'package:shoto/features/folders/domain/repositories/folders_repository.dart';
import 'package:shoto/features/folders/domain/use_cases/get_folders_use_case.dart';
import 'package:shoto/features/folders/presentation/widgets/default_folders.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_limit_gate.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:shoto/features/subscription/domain/use_cases/get_subscription_status_use_case.dart';
import 'package:shoto/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:shoto/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:shoto/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:shoto/features/subscription/presentation/pages/paywall_page.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_theme.dart';

/// The free tier's second number: how many folders a free user may hold.
///
/// This cap existed, was removed on purpose, and is back — so the thing worth
/// testing is not that a paywall appears, but *when*: never for a subscriber,
/// never for somebody under the line, and never as a punishment for the
/// folders somebody already had when the cap arrived.
void main() {
  late _FakeFoldersRepository folders;
  late _FakeSubscriptionRepository subscription;

  setUpAll(() {
    if (!sl.isRegistered<AppPreferences>()) {
      sl.registerLazySingleton<AppPreferences>(() => AppPreferences());
    }
    // What the paywall itself needs to draw. It is a real screen and this
    // pushes the real one, because "the paywall appeared" is the whole
    // assertion — a stand-in route would test the test.
    if (!sl.isRegistered<FunnelLog>()) {
      sl.registerLazySingleton<FunnelLog>(() => FunnelLog());
    }
    if (!sl.isRegistered<SubscriptionBloc>()) {
      sl.registerFactory<SubscriptionBloc>(() => _StubSubscriptionBloc());
    }
  });

  setUp(() {
    folders = _FakeFoldersRepository();
    subscription = _FakeSubscriptionRepository();

    if (sl.isRegistered<GetFoldersUseCase>()) {
      sl.unregister<GetFoldersUseCase>();
    }
    sl.registerLazySingleton<GetFoldersUseCase>(
      () => GetFoldersUseCase(folders),
    );
    if (sl.isRegistered<GetSubscriptionStatusUseCase>()) {
      sl.unregister<GetSubscriptionStatusUseCase>();
    }
    sl.registerLazySingleton<GetSubscriptionStatusUseCase>(
      () => GetSubscriptionStatusUseCase(subscription),
    );
  });

  void withFolders(int count) {
    folders.folders = <FolderEntity>[
      for (int i = 1; i <= count; i++)
        FolderEntity(
          id: i,
          name: 'Folder $i',
          color: 0xFF5B8DEF,
          createdAt: DateTime(2026, 1, i),
        ),
    ];
  }

  /// What the gate answered, once it answers.
  ///
  /// Held rather than awaited inside the helper: when the gate decides to show
  /// the paywall it does not return until that screen is closed, so a helper
  /// that awaited it would simply hang on the case this file exists to test.
  Future<bool>? pending;

  /// Taps a button that runs the gate, from a real route so the paywall it may
  /// push has somewhere to go.
  Future<void> tapGate(WidgetTester tester) async {
    pending = null;
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
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => pending = ensureUnderFolderLimit(context),
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    // Bounded rather than settled: the paywall this may push is a live screen
    // with animations of its own.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// Leaves the paywall the way a user who is not buying does.
  Future<void> dismissPaywall(WidgetTester tester) async {
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  group('the cap', () {
    testWidgets('lets a free user make their first folders', (
      WidgetTester tester,
    ) async {
      withFolders(SubscriptionConstants.freeFolderLimit - 1);

      await tapGate(tester);

      expect(await pending, isTrue);
      expect(find.byType(PaywallPage), findsNothing);
    });

    testWidgets('stops the one past the line', (WidgetTester tester) async {
      // Exactly at the cap: the folders they have are fine, the next one is
      // what costs.
      withFolders(SubscriptionConstants.freeFolderLimit);

      await tapGate(tester);
      expect(find.byType(PaywallPage), findsOneWidget);

      // Left without buying: the folder is not made, and nothing else
      // happens either.
      await dismissPaywall(tester);
      expect(await pending, isFalse);
    });

    testWidgets('never asks a subscriber', (WidgetTester tester) async {
      withFolders(40);
      subscription.status = const SubscriptionStatus(isPremium: true);

      await tapGate(tester);

      expect(await pending, isTrue);
      expect(find.byType(PaywallPage), findsNothing);
    });

    testWidgets('leaves somebody already over the line alone', (
      WidgetTester tester,
    ) async {
      // **Every install that existed before this cap is in this state**, and
      // the starter set used to be seven. They keep all seven; what they
      // cannot do is add an eighth. Nothing is deleted and nothing is hidden
      // — the gate is asked before a *new* folder and at no other time.
      withFolders(7);

      await tapGate(tester);

      expect(find.byType(PaywallPage), findsOneWidget);
      expect(folders.folders, hasLength(7));
      await dismissPaywall(tester);
    });

    test('the cap is three', () {
      expect(SubscriptionConstants.freeFolderLimit, 3);
    });
  });

  group('the starter set', () {
    /// The real list, resolved against a real localization delegate — the
    /// names come from the `.arb` files and there is no other way to see them.
    Future<List<FolderSeed>> resolveSeeds(
      WidgetTester tester, {
      AppLanguage language = AppLanguage.english,
    }) async {
      late List<FolderSeed> seeds;
      await tester.pumpWidget(
        MaterialApp(
          locale: language.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (BuildContext context) {
              seeds = defaultFolderSeeds(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return seeds;
    }

    testWidgets('is two folders, and they are the two chosen', (
      WidgetTester tester,
    ) async {
      expect(
        (await resolveSeeds(tester)).map((FolderSeed s) => s.name),
        <String>['AI notes', 'Recipes'],
      );
    });

    testWidgets("leaves a free slot for a folder of the user's own", (
      WidgetTester tester,
    ) async {
      // **The invariant, not the number.** A starter set the size of the
      // allowance means the first folder somebody names themselves is the one
      // that meets the paywall — their own idea, priced the moment they have
      // it. Whatever these two numbers become, the set has to stay smaller
      // than the cap.
      expect(
        (await resolveSeeds(tester)).length,
        lessThan(SubscriptionConstants.freeFolderLimit),
      );
    });

    testWidgets('each keeps a colour and a glyph of its own', (
      WidgetTester tester,
    ) async {
      // Two folders in two shades of one hue would teach that the colour is
      // something the app picked and therefore means nothing.
      final List<FolderSeed> seeds = await resolveSeeds(tester);

      expect(
        seeds.map((FolderSeed s) => s.color).toSet(),
        hasLength(seeds.length),
      );
      expect(
        seeds.map((FolderSeed s) => s.iconKey).toSet(),
        hasLength(seeds.length),
      );
    });

    testWidgets('the names are the device language, in every language', (
      WidgetTester tester,
    ) async {
      // They become plain text in the database from the moment they are
      // written, so the language they are resolved in is the language they
      // keep. A missing translation here is a folder called "Recipes" on a
      // German phone, for ever.
      final int expected = (await resolveSeeds(tester)).length;

      for (final AppLanguage language in AppLanguage.values) {
        final List<FolderSeed> seeds = await resolveSeeds(
          tester,
          language: language,
        );

        expect(seeds, hasLength(expected), reason: language.code);
        for (final FolderSeed seed in seeds) {
          expect(seed.name.trim(), isNotEmpty, reason: language.code);
        }
      }
    });
  });
}

class _FakeFoldersRepository implements FoldersRepository {
  List<FolderEntity> folders = <FolderEntity>[];

  @override
  Future<List<FolderEntity>> getFolders() async => folders;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  SubscriptionStatus status = SubscriptionStatus.free;

  @override
  Future<SubscriptionStatus> getStatus() async => status;

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
