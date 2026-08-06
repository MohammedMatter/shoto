import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/biometric_auth_service.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/features/folders/presentation/widgets/create_folder_sheet.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_fonts.dart';
import 'support/test_theme.dart';

/// The "private folder" switch, in both of its states.
///
/// It shipped with `activeThumbColor: AppPalette.primary` and nothing else,
/// which meant the thumb was set to the *same colour Material was already
/// painting the track* — `colorScheme.primary` is that accent. Switched on, the
/// control was a single uniform slab with no thumb visible in it, so the one
/// decision on this sheet that cannot be checked later by looking at the folder
/// was also the one you could not read.
///
/// Whether the replacement actually reads is not something an assertion can
/// answer, so these are for looking at: off and on, in both modes, with the
/// real typefaces loaded. Generation-only, like the other goldens here — no
/// committed baseline, never fails a normal run.
void main() {
  /// [PressableScale] buzzes on tap, and `Haptics` reads the user's preference
  /// out of the service locator to decide whether to.
  ///
  /// [BiometricAuthService] is here because the sheet asks it, in `initState`,
  /// which biometric this phone actually offers so the switch can name it.
  /// That dependency was added to the sheet without this registration, and
  /// because every test in this file was skipped unless the suite was asked to
  /// update goldens, the resulting GetIt error was invisible on a normal
  /// `flutter test` run. These assert now, so it could not hide again.
  ///
  /// The real service is safe to use under test: it has no platform channel
  /// to talk to, `availableBiometrics` catches that and returns an empty
  /// list, so the switch renders its device-agnostic label.
  setUpAll(() {
    if (!sl.isRegistered<AppPreferences>()) {
      sl.registerLazySingleton<AppPreferences>(() => AppPreferences());
    }
    if (!sl.isRegistered<BiometricAuthService>()) {
      sl.registerLazySingleton<BiometricAuthService>(
        () => BiometricAuthService(),
      );
    }
  });

  Future<void> openSheet(
    WidgetTester tester,
    Brightness brightness, {
    String locale = 'en',
  }) async {
    await loadTestFonts();
    final AppPalette palette = testPalette(brightness);

    tester.view.physicalSize = const Size(1080, 1560);
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
          // The real theme, because the bug being checked for lived in what
          // Material fills in when the app's theme is the only thing telling
          // it what "primary" means.
          theme: testTheme(brightness),
          home: Builder(
            builder: (context) => Scaffold(
              backgroundColor: palette.background,
              body: Center(
                child: ElevatedButton(
                  onPressed: () =>
                      showCreateFolderSheet(context, onCreate: (_, _, _) {}),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// The row is the tap target, so this is also what a user does.
  ///
  /// Found by icon rather than by its label, so the same helper works whatever
  /// language the sheet is speaking.
  Future<void> togglePrivate(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.lock_open_rounded));
    await tester.pumpAndSettle();
  }

  for (final MapEntry<String, Brightness> mode in {
    'dark': Brightness.dark,
    'light': Brightness.light,
  }.entries) {
    testWidgets(
      'create folder sheet — private off — ${mode.key}',
      (WidgetTester tester) async {
        await openSheet(tester, mode.value);
        await expectLater(
          find.byType(BottomSheet),
          matchesGoldenFile(
            'goldens/create_folder_private_off_${mode.key}.png',
          ),
        );
      },
    );

    testWidgets(
      'create folder sheet — private on — ${mode.key}',
      (WidgetTester tester) async {
        await openSheet(tester, mode.value);
        await togglePrivate(tester);
        await expectLater(
          find.byType(BottomSheet),
          matchesGoldenFile('goldens/create_folder_private_on_${mode.key}.png'),
        );
      },
    );
  }

  /// **Arabic, which is the real test of "the whole app follows the
  /// language".**
  ///
  /// Two separate things have to be right and only one of them is translation:
  /// every string comes from the .arb files, *and* the layout mirrors — the
  /// drag handle stays centred, the title moves to the right edge, the switch
  /// moves to the left, and the text field's cursor starts on the right. Any
  /// `EdgeInsets.only(left:)` left in the tree shows up here immediately,
  /// which is why this is a picture rather than an assertion.
  testWidgets('create folder sheet — Arabic, private on', (
    WidgetTester tester,
  ) async {
    await openSheet(tester, Brightness.dark, locale: 'ar');
    await togglePrivate(tester);
    await expectLater(
      find.byType(BottomSheet),
      matchesGoldenFile('goldens/create_folder_arabic.png'),
    );
  });
}
