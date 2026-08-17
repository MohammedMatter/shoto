import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/funnel_log.dart';
import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/core/theme/folder_appearance_controller.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/features/duplicates/presentation/bloc/duplicates_bloc.dart';
import 'package:shoto/features/duplicates/presentation/bloc/duplicates_state.dart';
import 'package:shoto/features/duplicates/presentation/pages/duplicates_page.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_state.dart';
import 'package:shoto/features/folders/presentation/pages/folders_page.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:shoto/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:shoto/features/subscription/presentation/pages/paywall_page.dart';
import 'package:shoto/features/stitch/domain/entities/stitch_outcome.dart';
import 'package:shoto/features/stitch/presentation/bloc/stitch_bloc.dart';
import 'package:shoto/features/stitch/presentation/bloc/stitch_state.dart';
import 'package:shoto/features/stitch/presentation/pages/stitch_page.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_theme.dart';

/// **The inventory: every state of every screen, drawn.**
///
/// The blank-Home bug was fixed once, then found again on `IntentPage`, then
/// again on Duplicates. Three screens, one mistake — a state nobody wrote a
/// branch for, falling through a `state is! …` guard into `SizedBox.shrink()`.
/// Each fix was correct and none of them stopped the fourth.
///
/// So this file is not a fourth fix. It is the census, and it has two halves
/// that fail in different ways:
///
/// **Compile time.** Every state family is `sealed`, and every screen chooses
/// its body with a `switch` that has no `default`. Add a state and the app
/// stops compiling at each screen that reads it — the branch cannot be
/// forgotten, because forgetting it is not a thing the compiler allows.
///
/// **Run time.** The `_name` switches below are exhaustive too, so adding a
/// state stops *this file* compiling until a sample is added for it. And each
/// sample is drawn and inspected: a screen may not answer a question it was
/// not asked. A refused permission is not an empty library, a scan that has
/// not started is not a clean one, and half a purchase is not a paywall with
/// no prices on it.
///
/// One branch in the app is allowed to draw nothing — Folders while its SQLite
/// read is in flight, where a spinner would be a flash on a screen re-entered
/// dozens of times a session. It is exempt because it is written down, and it
/// is asserted here so the exemption stays deliberate.
class _StubDuplicatesBloc extends Cubit<DuplicatesState>
    implements DuplicatesBloc {
  _StubDuplicatesBloc(super.initialState);

  /// Swallowed rather than forwarded to `super`, which throws. The pages under
  /// test dispatch on build (`ScanForDuplicatesEvent`, `RunStitchEvent`) and
  /// the point here is what they *draw* for a given state, not what they ask
  /// for next.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StubStitchBloc extends Cubit<StitchState> implements StitchBloc {
  _StubStitchBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StubFoldersBloc extends Cubit<FoldersState> implements FoldersBloc {
  _StubFoldersBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StubScreenshotsBloc extends Cubit<ScreenshotsState>
    implements ScreenshotsBloc {
  _StubScreenshotsBloc() : super(ScreenshotsLoadedState(screenshots: const []));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StubSubscriptionBloc extends Cubit<SubscriptionState>
    implements SubscriptionBloc {
  _StubSubscriptionBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Exhaustive on purpose. A new `DuplicatesState` breaks this switch, and the
/// break is the notice that a sample and an expectation are owed below.
String _duplicatesName(DuplicatesState state) => switch (state) {
  DuplicatesInitialState() => 'initial',
  DuplicatesScanningState() => 'scanning',
  DuplicatesLoadedState() => 'loaded',
  DuplicatesErrorState() => 'error',
  DuplicatesDeletedState() => 'deleted',
};

/// Exhaustive on purpose — see [_duplicatesName].
String _foldersName(FoldersState state) => switch (state) {
  FoldersInitialState() => 'initial',
  FoldersLoadingState() => 'loading',
  FoldersLoadedState() => 'loaded',
  FoldersErrorState() => 'error',
};

/// Exhaustive on purpose — see [_duplicatesName].
String _subscriptionName(SubscriptionState state) => switch (state) {
  SubscriptionLoadingState() => 'loading',
  SubscriptionLoadedState() => 'loaded',
  SubscriptionErrorState() => 'error',
  SubscriptionPurchaseSuccessState() => 'purchased',
};

/// Exhaustive on purpose — see [_duplicatesName].
String _stitchName(StitchState state) => switch (state) {
  StitchInitialState() => 'initial',
  StitchWorkingState() => 'working',
  StitchReadyState() => 'ready',
  StitchSavedState() => 'saved',
  StitchFailedState() => 'failed',
};

void main() {
  setUp(() {
    // The paywall counts itself as seen on build, and the count lands in
    // SharedPreferences.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    if (!sl.isRegistered<ThemeController>()) {
      sl.registerLazySingleton<ThemeController>(() => ThemeController());
    }
    // The folders page reads its column count and its two card switches off
    // this, at its defaults here — three across, count on, date off, which is
    // what a fresh install draws.
    if (!sl.isRegistered<FolderAppearanceController>()) {
      sl.registerLazySingleton<FolderAppearanceController>(
        () => FolderAppearanceController(),
      );
    }
    if (!sl.isRegistered<FunnelLog>()) {
      sl.registerLazySingleton<FunnelLog>(() => FunnelLog());
    }
  });

  tearDown(() {
    if (sl.isRegistered<DuplicatesBloc>()) sl.unregister<DuplicatesBloc>();
    if (sl.isRegistered<StitchBloc>()) sl.unregister<StitchBloc>();
    if (sl.isRegistered<SubscriptionBloc>()) sl.unregister<SubscriptionBloc>();
  });

  Future<AppLocalizations> english() =>
      AppLocalizations.delegate.load(const Locale('en'));

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1080, 2200);
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
          home: screen,
        ),
      ),
    );
    // Past the entrance stagger. Screens that animate their contents in leave
    // a pending timer behind if the test stops mid-cascade, which fails as a
    // timer complaint rather than as anything to do with state.
    await tester.pump(const Duration(milliseconds: 700));
  }

  Future<void> showDuplicates(WidgetTester tester, DuplicatesState state) async {
    sl.registerFactory<DuplicatesBloc>(() => _StubDuplicatesBloc(state));
    await pump(tester, const DuplicatesPage());
  }

  Future<void> showStitch(WidgetTester tester, StitchState state) async {
    sl.registerFactory<StitchBloc>(() => _StubStitchBloc(state));
    await pump(tester, const StitchPage(assetIds: <String>['a', 'b']));
  }

  Future<void> showFolders(WidgetTester tester, FoldersState state) async {
    await pump(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<FoldersBloc>(create: (_) => _StubFoldersBloc(state)),
          BlocProvider<ScreenshotsBloc>(create: (_) => _StubScreenshotsBloc()),
        ],
        child: const FoldersPage(),
      ),
    );
  }

  /// The claim a screen is only allowed to make once the work behind it is
  /// actually finished.
  Future<void> expectNoVerdict(WidgetTester tester) async {
    final AppLocalizations l10n = await english();
    expect(find.text(l10n.dupNoneTitle), findsNothing);
    expect(find.byIcon(Icons.verified_rounded), findsNothing);
  }

  group('Duplicates draws every state', () {
    testWidgets('${_duplicatesName(DuplicatesInitialState())}: '
        'a scan that has not started is not a clean library', (tester) async {
      await showDuplicates(tester, DuplicatesInitialState());
      final AppLocalizations l10n = await english();

      // This was `SizedBox.shrink()` — a title bar over an empty page, which
      // on a screen whose whole job is to report a number reads as zero.
      expect(find.text(l10n.dupScanning), findsOneWidget);
      await expectNoVerdict(tester);
    });

    testWidgets('${_duplicatesName(DuplicatesScanningState())}: '
        'progress is reported while it runs', (tester) async {
      await showDuplicates(
        tester,
        DuplicatesScanningState(processed: 3, total: 10),
      );
      final AppLocalizations l10n = await english();

      expect(find.text(l10n.dupScanning), findsOneWidget);
      await expectNoVerdict(tester);
    });

    testWidgets('${_duplicatesName(DuplicatesErrorState(AppMessage.generic))}: '
        'a failed scan offers a retry, not a verdict', (tester) async {
      await showDuplicates(tester, DuplicatesErrorState(AppMessage.generic));
      final AppLocalizations l10n = await english();

      expect(find.text(l10n.commonSomethingWentWrong), findsOneWidget);
      expect(find.text(l10n.commonRetry), findsOneWidget);
      // The half that matters: "we could not look" must not be dressed as
      // "we looked and it is clean".
      await expectNoVerdict(tester);
    });

    testWidgets(
      '${_duplicatesName(DuplicatesDeletedState(deletedCount: 0, freedBytes: 0))}: '
      'the moment after deleting is a re-scan, not an empty page',
      (tester) async {
        await showDuplicates(
          tester,
          DuplicatesDeletedState(deletedCount: 2, freedBytes: 1024),
        );
        final AppLocalizations l10n = await english();

        expect(find.text(l10n.dupScanning), findsOneWidget);
      },
    );

    testWidgets(
      '${_duplicatesName(DuplicatesLoadedState(groups: const [], selectedIds: const {}))}: '
      'the tick is earned by a scan that finished',
      (tester) async {
        await showDuplicates(
          tester,
          DuplicatesLoadedState(groups: const [], selectedIds: const {}),
        );
        final AppLocalizations l10n = await english();

        // The other side of the contract — the verdict must still appear when
        // it is true, or the assertions above could be satisfied by deleting it.
        expect(find.text(l10n.dupNoneTitle), findsOneWidget);
        expect(find.text(l10n.dupScanAgain), findsOneWidget);
      },
    );
  });

  group('Folders draws every state', () {
    /// The one branch in the app allowed to draw nothing, asserted rather than
    /// assumed. Reading the folder table is a millisecond-scale SQLite query on
    /// a screen re-entered dozens of times a session, so a spinner here is a
    /// flash. If somebody later decides silence was a mistake, this test is
    /// where the argument has to be had.
    for (final FoldersState quiet in <FoldersState>[
      FoldersInitialState(),
      FoldersLoadingState(),
    ]) {
      testWidgets('${_foldersName(quiet)}: silent on purpose, and only here', (
        tester,
      ) async {
        await showFolders(tester, quiet);
        final AppLocalizations l10n = await english();

        // Silent is not the same as wrong: it must not claim the user has no
        // folders, and it must not claim anything failed.
        expect(find.text(l10n.foldersEmptyTitle), findsNothing);
        expect(find.text(l10n.commonSomethingWentWrong), findsNothing);
      });
    }

    testWidgets('${_foldersName(FoldersErrorState(AppMessage.loadFolders))}: '
        'a failed read is not an empty shelf', (tester) async {
      await showFolders(tester, FoldersErrorState(AppMessage.loadFolders));
      final AppLocalizations l10n = await english();

      expect(find.text(l10n.commonSomethingWentWrong), findsOneWidget);
      expect(find.text(l10n.foldersEmptyTitle), findsNothing);
    });

    testWidgets('${_foldersName(FoldersLoadedState(const []))}: '
        'an empty shelf says so and offers the way out', (tester) async {
      await showFolders(tester, FoldersLoadedState(const []));
      final AppLocalizations l10n = await english();

      expect(find.text(l10n.foldersEmptyTitle), findsOneWidget);
      expect(find.text(l10n.foldersNew), findsWidgets);
    });

    testWidgets('loaded with folders: the shelf is drawn, not the empty state', (
      tester,
    ) async {
      await showFolders(
        tester,
        FoldersLoadedState(<FolderEntity>[
          FolderEntity(
            id: 1,
            name: 'Receipts',
            color: 0xFFEF6C34,
            createdAt: DateTime(2026, 1, 1),
          ),
        ]),
      );
      final AppLocalizations l10n = await english();

      expect(find.text('Receipts'), findsOneWidget);
      expect(find.text(l10n.foldersEmptyTitle), findsNothing);
    });
  });

  group('Paywall draws every state', () {
    Future<void> showPaywall(WidgetTester tester, SubscriptionState s) async {
      sl.registerFactory<SubscriptionBloc>(() => _StubSubscriptionBloc(s));
      await pump(tester, const PaywallPage());
    }

    testWidgets('${_subscriptionName(SubscriptionLoadingState())}: '
        'the offer is named before its prices arrive', (tester) async {
      await showPaywall(tester, SubscriptionLoadingState());
      final AppLocalizations l10n = await english();

      expect(find.text(l10n.paywallTitle), findsOneWidget);
    });

    testWidgets('${_subscriptionName(SubscriptionErrorState(AppMessage.plans))}: '
        'prices that could not be fetched say so', (tester) async {
      await showPaywall(tester, SubscriptionErrorState(AppMessage.plans));
      final AppLocalizations l10n = await english();

      // Whatever this screen shows, it must not be a buy button with no price
      // attached to it.
      expect(find.text(l10n.paywallContinue), findsNothing);
    });

    testWidgets(
      '${_subscriptionName(SubscriptionLoadedState(packages: const [], status: SubscriptionStatus.free))}: '
      'a store with nothing in it is admitted, not left blank',
      (tester) async {
        await showPaywall(
          tester,
          SubscriptionLoadedState(
            packages: const [],
            status: SubscriptionStatus.free,
          ),
        );
        final AppLocalizations l10n = await english();

        expect(find.text(l10n.paywallTitle), findsOneWidget);
        expect(find.text(l10n.paywallUnavailable), findsOneWidget);
      },
    );

    testWidgets(
      '${_subscriptionName(SubscriptionPurchaseSuccessState(SubscriptionStatus.free))}: '
      'the frame between paying and arriving is still the paywall',
      (tester) async {
        // One frame — the listener pops to the welcome screen. It used to fall
        // into the ternary's "everything else", which is a paywall drawn with
        // no packages: prices gone, mid-purchase.
        await showPaywall(
          tester,
          SubscriptionPurchaseSuccessState(
            const SubscriptionStatus(isPremium: true),
          ),
        );
        final AppLocalizations l10n = await english();

        expect(find.text(l10n.paywallTitle), findsOneWidget);
      },
    );
  });

  group('Merge draws every state', () {
    testWidgets('${_stitchName(StitchInitialState())}: '
        'work that has not begun still says it is working', (tester) async {
      await showStitch(tester, StitchInitialState());
      final AppLocalizations l10n = await english();

      expect(find.text(l10n.stitchWorking), findsOneWidget);
      expect(find.text(l10n.stitchFailed), findsNothing);
    });

    testWidgets('${_stitchName(StitchWorkingState(1, 3))}: '
        'progress is drawn while it runs', (tester) async {
      await showStitch(tester, StitchWorkingState(1, 3));
      final AppLocalizations l10n = await english();

      expect(find.text(l10n.stitchWorking), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('${_stitchName(StitchFailedState(AppMessage.generic))}: '
        'a failed merge explains itself and offers a way out', (tester) async {
      await showStitch(tester, StitchFailedState(AppMessage.generic));
      final AppLocalizations l10n = await english();

      expect(find.text(l10n.stitchFailed), findsOneWidget);
      expect(find.text(l10n.commonBack), findsOneWidget);
      // A failure that still spins is a failure the user waits out forever.
      expect(find.text(l10n.stitchWorking), findsNothing);
    });

    testWidgets('ready: a finished merge is offered, never saved for you', (
      tester,
    ) async {
      final StitchOutcome outcome = _outcome();
      await showStitch(tester, StitchReadyState(outcome));
      final AppLocalizations l10n = await english();

      // Merging can only be judged by eye, so the state that matters most is
      // the one where the work is done and nothing has been written yet.
      expect(find.text(l10n.stitchSave), findsOneWidget);
      expect(find.text(l10n.stitchDiscard), findsOneWidget);
      expect(find.text(l10n.stitchWorking), findsNothing);
    });

    testWidgets('saved: the result is confirmed, not left looking unsaved', (
      tester,
    ) async {
      final StitchOutcome outcome = _outcome();
      await showStitch(tester, StitchSavedState(outcome));
      final AppLocalizations l10n = await english();

      expect(find.text(l10n.commonDone), findsOneWidget);
      expect(find.text(l10n.stitchSave), findsNothing);
    });
  });
}

/// A real merge result, because `_Preview` decodes the bytes it is given.
///
/// Built from a literal rather than rendered on a canvas: `toByteData` is
/// genuinely asynchronous, and awaiting it inside `testWidgets` steps outside
/// the fake-async zone the test runs in — which fails as an unrelated-looking
/// pump error rather than as "your fixture is async".
StitchOutcome _outcome() => StitchOutcome(
  pngBytes: base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAA'
    'DUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  ),
  width: 1,
  height: 1,
  sourceCount: 2,
  trimmedRows: 12,
);
