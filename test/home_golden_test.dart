import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_state.dart';
import 'package:shoto/features/home/presentation/pages/home_page.dart';
import 'package:shoto/features/home/presentation/widgets/home_greeting.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/fake_gallery.dart';
import 'support/test_fonts.dart';
import 'support/test_theme.dart';

/// Home, in both of the states it actually ships in.
///
/// The empty one was the only one photographed for a long time, which left
/// the recent strip, the stat line and Waiting on you — half the screen —
/// with no picture anywhere. They are here now, which is what the `filled`
/// flag is for.
///
/// Unlike the rest of the goldens in this folder, these **assert**. Three
/// things had to be true first: the entrance cascade is pumped past its end
/// so nothing is mid-animation, the gallery is faked so thumbnails resolve to
/// fixed bytes instead of failing, and [HomeGreeting.debugClock] is frozen —
/// without it the greeting follows the wall clock and the baseline goes red
/// twice a day.
class _StubScreenshotsBloc extends Cubit<ScreenshotsState>
    implements ScreenshotsBloc {
  _StubScreenshotsBloc(super.state);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubFoldersBloc extends Cubit<FoldersState> implements FoldersBloc {
  _StubFoldersBloc(super.state);

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

/// Twelve, because the strip takes twelve — enough to reach the trailing edge
/// and prove it keeps going.
List<ScreenshotEntity> _library() => List<ScreenshotEntity>.generate(
  12,
  (int i) => ScreenshotEntity(
    asset: FakeGallery.asset(i),
    // Four favourites and three filed, so the hero has something left to
    // count and the stat line has no zero in it.
    isFavorite: i % 3 == 0,
    folderId: i % 4 == 0 ? 1 : null,
    intent: i == 1 || i == 5
        ? const IntentState(ref: BuiltInIntent(ScreenshotIntent.pay))
        : null,
  ),
);

void main() {
  setUpAll(() async {
    await FakeGallery.install();
    HomeGreeting.debugClock = () => DateTime(2026, 8, 6, 14);

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

  tearDownAll(() {
    FakeGallery.uninstall();
    HomeGreeting.debugClock = null;
  });

  Future<void> render(
    WidgetTester tester,
    Brightness brightness, {
    String locale = 'en',
    bool filled = false,
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
                create: (_) => _StubScreenshotsBloc(
                  ScreenshotsLoadedState(
                    screenshots: filled ? _library() : const [],
                  ),
                ),
              ),
              BlocProvider<FoldersBloc>(
                create: (_) => _StubFoldersBloc(
                  FoldersLoadedState(
                    filled
                        ? <FolderEntity>[
                            FolderEntity(
                              id: 1,
                              name: 'Receipts',
                              color: 0xFF5B8DEF,
                              createdAt: DateTime(2026, 1, 1),
                              screenshotCount: 3,
                              isPrivate: false,
                            ),
                            FolderEntity(
                              id: 2,
                              name: 'Recipes',
                              color: 0xFF6EA96E,
                              createdAt: DateTime(2026, 1, 2),
                              screenshotCount: 0,
                              isPrivate: false,
                            ),
                          ]
                        : const [],
                  ),
                ),
              ),
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
    // Past the 520ms entrance cascade, so every section is at rest, then
    // again so the thumbnails that resolved in the meantime have painted.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  }

  testWidgets('home — dark', (WidgetTester tester) async {
    await render(tester, Brightness.dark);
    await expectLater(
      find.byType(HomePage),
      matchesGoldenFile('goldens/home_dark.png'),
    );
  });

  testWidgets('home — light', (WidgetTester tester) async {
    await render(tester, Brightness.light);
    await expectLater(
      find.byType(HomePage),
      matchesGoldenFile('goldens/home_light.png'),
    );
  });

  testWidgets('home — Arabic', (WidgetTester tester) async {
    await render(tester, Brightness.dark, locale: 'ar');
    await expectLater(
      find.byType(HomePage),
      matchesGoldenFile('goldens/home_arabic.png'),
    );
  });

  testWidgets('home — filled, dark', (WidgetTester tester) async {
    await render(tester, Brightness.dark, filled: true);
    await expectLater(
      find.byType(HomePage),
      matchesGoldenFile('goldens/home_filled_dark.png'),
    );
  });

  testWidgets('home — filled, light', (WidgetTester tester) async {
    await render(tester, Brightness.light, filled: true);
    await expectLater(
      find.byType(HomePage),
      matchesGoldenFile('goldens/home_filled_light.png'),
    );
  });

  testWidgets('home — filled, Arabic', (WidgetTester tester) async {
    await render(tester, Brightness.dark, locale: 'ar', filled: true);
    await expectLater(
      find.byType(HomePage),
      matchesGoldenFile('goldens/home_filled_arabic.png'),
    );
  });
}
