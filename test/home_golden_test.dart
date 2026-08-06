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
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_fonts.dart';
import 'support/test_theme.dart';

/// The rebuilt Home, for looking at.
///
/// The two changes it exists to show are both about *reach*: search is a
/// full-width field near the top instead of a 44px circle in the corner a
/// thumb cannot get to, and the counts under the hero are shortcuts rather
/// than trivia. Neither is something an assertion can judge, so this writes a
/// picture — including an Arabic one, because a screen whose whole top half is
/// new is exactly where a non-directional padding would hide.
///
/// The blocs are stubbed at their empty states: a widget test has no photo
/// library, and the parts being reviewed here are the header, the counts and
/// the tool rows, none of which need one.
/// Cubits rather than the real blocs: constructing those pulls in the whole
/// dependency graph — photo_manager, sqflite, Firebase — none of which a
/// golden of the *layout* has any use for. Home only ever reads the state.
class _StubScreenshotsBloc extends Cubit<ScreenshotsState>
    implements ScreenshotsBloc {
  _StubScreenshotsBloc() : super(ScreenshotsLoadedState(screenshots: const []));

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubFoldersBloc extends Cubit<FoldersState> implements FoldersBloc {
  _StubFoldersBloc() : super(FoldersLoadedState(const []));

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The only real dependency Home has that is not a bloc: [ProStatus], which
/// the wordmark's badge watches. Backed by a fake so the test does not need
/// RevenueCat or a signed-in Firebase user to draw a header.
class _FakeSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<SubscriptionStatus> getStatus() async => SubscriptionStatus.free;

  @override
  Stream<SubscriptionStatus> get statusChanges => const Stream.empty();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
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

  Future<void> render(
    WidgetTester tester,
    Brightness brightness, {
    String locale = 'en',
  }) async {
    await loadTestFonts();

    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: testTheme(brightness),
          home: MultiBlocProvider(
            providers: [
              BlocProvider<ScreenshotsBloc>(
                create: (_) => _StubScreenshotsBloc(),
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
    // Past the 520ms entrance cascade, so every section is at rest.
    await tester.pump(const Duration(milliseconds: 700));
  }

  testWidgets('home — dark', (WidgetTester tester) async {
    await render(tester, Brightness.dark);
    await expectLater(
      find.byType(HomePage),
      matchesGoldenFile('goldens/home_dark.png'),
    );
  }, skip: !autoUpdateGoldenFiles);

  testWidgets('home — light', (WidgetTester tester) async {
    await render(tester, Brightness.light);
    await expectLater(
      find.byType(HomePage),
      matchesGoldenFile('goldens/home_light.png'),
    );
  }, skip: !autoUpdateGoldenFiles);

  testWidgets('home — Arabic', (WidgetTester tester) async {
    await render(tester, Brightness.dark, locale: 'ar');
    await expectLater(
      find.byType(HomePage),
      matchesGoldenFile('goldens/home_arabic.png'),
    );
  }, skip: !autoUpdateGoldenFiles);
}
