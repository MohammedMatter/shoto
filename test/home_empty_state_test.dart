import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_state.dart';
import 'package:shoto/features/home/presentation/pages/home_page.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_new_captures_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/import_from_system_picker_use_case.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_intent.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_theme.dart';

/// What Home must do on the day the app is installed.
///
/// Every one of these was broken on a fresh install, and none of them is
/// visible in a golden: a golden shows that a row is *drawn*, not where
/// tapping it goes. The specific failure worth a regression test is Find
/// duplicates, which went straight to the paywall — so the app's answer to
/// "what does this do?", on an empty library, was to ask for money to scan
/// nothing.
class _EmptyScreenshotsBloc extends Cubit<ScreenshotsState>
    implements ScreenshotsBloc {
  _EmptyScreenshotsBloc()
    : super(ScreenshotsLoadedState(screenshots: const []));

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

class _NoCaptures implements ScreenshotRepository {
  @override
  Future<List<AssetEntity>> getNewCaptures({required DateTime since}) async =>
      const [];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Counts invocations instead of opening the operating system's picker.
///
/// `implements` rather than `extends` so none of the real collaborators —
/// an ImagePicker, the screenshot repository — have to exist for this.
class _RecordingImport implements ImportFromSystemPickerUseCase {
  int calls = 0;

  @override
  Future<ImportResult> call() async {
    calls++;
    // "Cancelled", so `importScreenshots` returns without a snackbar or a
    // bloc event and the widget tree is left exactly as it was.
    return const ImportResult(picked: 0, imported: 0);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _RecordingImport import;
  late List<LibraryIntent> intentsOpened;

  setUp(() {
    import = _RecordingImport();
    intentsOpened = <LibraryIntent>[];

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
    if (sl.isRegistered<ImportFromSystemPickerUseCase>()) {
      sl.unregister<ImportFromSystemPickerUseCase>();
    }
    sl.registerSingleton<ImportFromSystemPickerUseCase>(import);

    // Home asks this on mount. The preference it reads is off in a fresh
    // install, so the answer is an empty list without any gallery being
    // touched — but the *lookup* still has to resolve.
    if (!sl.isRegistered<GetNewCapturesUseCase>()) {
      sl.registerLazySingleton<GetNewCapturesUseCase>(
        () => GetNewCapturesUseCase(_NoCaptures(), sl<AppPreferences>()),
      );
    }
  });

  Future<void> render(WidgetTester tester) async {
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
                create: (_) => _EmptyScreenshotsBloc(),
              ),
              BlocProvider<FoldersBloc>(create: (_) => _StubFoldersBloc()),
            ],
            child: HomePage(
              onOpenLibrary: (_) {},
              onOpenLibraryForIntent: intentsOpened.add,
              onOpenFolders: () {},
            ),
          ),
        ),
      ),
    );
    // Past the 520ms entrance cascade, so every section is tappable.
    await tester.pump(const Duration(milliseconds: 700));
  }

  testWidgets('the empty hero offers the picker directly', (tester) async {
    await render(tester);

    final AppLocalizations l10n = await AppLocalizations.delegate.load(
      const Locale('en'),
    );

    // The one action on the screen, in the largest slot.
    final Finder cta = find.text(l10n.homeEmptyImportCta);
    expect(cta, findsOneWidget);

    await tester.tap(cta);
    await tester.pumpAndSettle();
    expect(import.calls, 1);
  });

  testWidgets('the counts are hidden while they would all be zero', (
    tester,
  ) async {
    await render(tester);
    // "Screenshots 0 · Favorites 0 · Folders 0" restated, three times, the
    // claim the headline above had just made.
    expect(find.textContaining('Screenshots'), findsNothing);
  });

  testWidgets('the import row is not offered twice', (tester) async {
    await render(tester);

    final AppLocalizations l10n = await AppLocalizations.delegate.load(
      const Locale('en'),
    );
    // The hero already carries it; a second entry point on the same screen
    // only makes the list longer.
    expect(find.text(l10n.importTitle), findsNothing);
  });

  testWidgets('no tool row dead-ends or paywalls on an empty library', (
    tester,
  ) async {
    await render(tester);

    final AppLocalizations l10n = await AppLocalizations.delegate.load(
      const Locale('en'),
    );

    for (final String label in <String>[
      l10n.homeToolSafeShare,
      l10n.homeToolDuplicates,
      l10n.homeToolStitch,
    ]) {
      final Finder row = find.text(label);
      expect(row, findsOneWidget, reason: '$label should still be visible');
      await tester.tap(row);
      await tester.pumpAndSettle();
    }

    // Each row asked for screenshots instead of opening an empty selection
    // or the paywall.
    expect(import.calls, 3);
    expect(
      intentsOpened,
      isEmpty,
      reason: 'the Library was opened for a job with nothing to do it to',
    );
  });
}
