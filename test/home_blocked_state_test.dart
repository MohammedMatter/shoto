import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_state.dart';
import 'package:shoto/features/home/presentation/pages/home_page.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_theme.dart';

/// Home must never be a blank screen.
///
/// It was one for anybody who had refused photo access. Home chose its
/// headline from "is the state loaded", so a denied permission and a failed
/// read were indistinguishable from the half second before the first read
/// lands, and all three drew nothing at all — no count, no sentence, no
/// import button, on the tab the app opens on. The Library tab explained both
/// cases; the first screen the user sees explained neither.
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

void main() {
  setUp(() {
    if (!sl.isRegistered<AppPreferences>()) {
      sl.registerLazySingleton<AppPreferences>(() => AppPreferences());
    }
    if (!sl.isRegistered<ThemeController>()) {
      sl.registerLazySingleton<ThemeController>(() => ThemeController());
    }
    if (!sl.isRegistered<DevAccess>()) {
      sl.registerLazySingleton<DevAccess>(() => DevAccess());
    }
    if (!sl.isRegistered<ProStatus>()) {
      sl.registerLazySingleton<ProStatus>(
        () => ProStatus(_FakeSubscriptionRepository(), sl<DevAccess>()),
      );
    }
  });

  Future<void> render(WidgetTester tester, ScreenshotsState state) async {
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
          home: MultiBlocProvider(
            providers: [
              BlocProvider<ScreenshotsBloc>(
                create: (_) => _StubScreenshotsBloc(state),
              ),
              BlocProvider<FoldersBloc>(create: (_) => _StubFoldersBloc()),
            ],
            child: HomePage(
              onOpenLibrary: (_) {},
              onOpenLibraryForIntent: (_) {},
              onOpenFolders: () {},
            ),
          ),
        ),
      ),
    );
    // Past the 520ms entrance cascade, so every section has finished arriving.
    await tester.pump(const Duration(milliseconds: 700));
  }

  Future<AppLocalizations> english() =>
      AppLocalizations.delegate.load(const Locale('en'));

  /// **The bug this file exists for, made again by the file's own author.**
  ///
  /// Home's headline switch ended in `_`, so it compiled happily when a sixth
  /// state was added to the bloc — and a fresh install opened on the loading
  /// skeleton: no count, no sentence, no import button, nothing to press. The
  /// same blank first screen this test file was written to prevent, reached
  /// through the wildcard that was left in the switch after it was fixed.
  ///
  /// The wildcard is gone. This asserts the behaviour, because a wildcard is
  /// one character and comes back easily.
  testWidgets('a permission never asked for opens on the question', (
    tester,
  ) async {
    await render(tester, ScreenshotsPermissionUnaskedState());
    final AppLocalizations l10n = await english();

    expect(find.text(l10n.permissionAskTitle), findsOneWidget);
    expect(find.text(l10n.permissionAllow), findsOneWidget);

    // Not the refusal's screen: this user has answered nothing, and system
    // settings is an instruction to repair an app that is not broken.
    expect(find.text(l10n.permissionOpenSettings), findsNothing);
    // And not the skeleton, which is what it actually drew.
    expect(find.text(l10n.homeInboxEmpty), findsNothing);
  });

  testWidgets('a refused photo permission is explained, not left blank', (
    tester,
  ) async {
    await render(tester, ScreenshotsPermissionDeniedState());
    final AppLocalizations l10n = await english();

    expect(find.text(l10n.permissionNeededTitle), findsOneWidget);
    // And a way to act on it — the reason Home was unusable was that there
    // was nothing to press.
    expect(find.text(l10n.permissionOpenSettings), findsOneWidget);
  });

  testWidgets('partial access says so, rather than reusing the plain refusal', (
    tester,
  ) async {
    await render(
      tester,
      ScreenshotsPermissionDeniedState(isPartialAccess: true),
    );
    final AppLocalizations l10n = await english();

    expect(find.text(l10n.permissionPartialTitle), findsOneWidget);
    expect(find.text(l10n.permissionNeededTitle), findsNothing);
  });

  testWidgets('a failed read is explained and can be retried', (tester) async {
    await render(tester, ScreenshotsErrorState(AppMessage.loadScreenshots));
    final AppLocalizations l10n = await english();

    expect(find.text(l10n.commonSomethingWentWrong), findsOneWidget);
    expect(find.text(l10n.commonRetry), findsOneWidget);
  });

  testWidgets('the transient states still draw nothing', (tester) async {
    final AppLocalizations l10n = await english();

    for (final ScreenshotsState state in <ScreenshotsState>[
      ScreenshotsInitialState(),
      ScreenshotsLoadingState(),
    ]) {
      await render(tester, state);
      // No headline is right here: these fix themselves within a frame or
      // two, and a message that flashes past is worse than a quiet gap.
      expect(find.text(l10n.homeInboxEmpty), findsNothing);
      expect(find.text(l10n.permissionNeededTitle), findsNothing);
      expect(find.text(l10n.commonSomethingWentWrong), findsNothing);
    }
  });
}
