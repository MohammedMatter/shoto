import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/biometric_auth_service.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_editor_sheet.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_fonts.dart';
import 'support/test_theme.dart';

/// The sheet that names a folder, colours it and gives it a glyph.
///
/// Three things on it are worth looking at rather than asserting about, and
/// two of them are why this file exists at all:
///
/// * **The private switch, in both states.** It shipped with
///   `activeThumbColor: AppPalette.primary`, which is the *same colour Material
///   was already painting the track* — switched on, the control was a single
///   uniform slab with no thumb visible in it, so the one decision on this
///   sheet that cannot be checked later by looking at the folder was also the
///   one you could not read.
/// * **The live preview**, which is the real [FolderCard] at preview size. Its
///   whole job is that what you see here is what lands on the grid, and the way
///   to check that is to look at both.
/// * **German**, because every string comes from the `.arb` files and this
///   sheet is where that gets tight: "Privat (Gesichts- oder
///   Fingerabdrucksperre)" is more than twice the length of its English label,
///   on a row that also has to hold a switch.
void main() {
  /// `PressableScale` buzzes on tap, and `Haptics` reads the user's preference
  /// out of the service locator to decide whether to.
  ///
  /// [BiometricAuthService] is here because the sheet asks it, in `initState`,
  /// which biometric this phone actually offers so the switch can name it.
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

    tester.view.physicalSize = const Size(1080, 1920);
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
                      showFolderEditorSheet(context, onSave: (_, _, _, _) {}),
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
    testWidgets('folder editor sheet — private off — ${mode.key}', (
      WidgetTester tester,
    ) async {
      await openSheet(tester, mode.value);
      await expectLater(
        find.byType(BottomSheet),
        matchesGoldenFile('goldens/create_folder_private_off_${mode.key}.png'),
      );
    });

    testWidgets('folder editor sheet — private on — ${mode.key}', (
      WidgetTester tester,
    ) async {
      await openSheet(tester, mode.value);
      await togglePrivate(tester);
      await expectLater(
        find.byType(BottomSheet),
        matchesGoldenFile('goldens/create_folder_private_on_${mode.key}.png'),
      );
    });
  }

  /// This slot was Arabic until Arabic stopped shipping, and it was doing a
  /// second job then — proving the layout mirrors. That half lives on in the
  /// forced-RTL golden in `home_golden_test.dart`; nothing about mirroring was
  /// deleted from the widgets, only from the shipped language set.
  testWidgets('folder editor sheet — German, private on', (
    WidgetTester tester,
  ) async {
    await openSheet(tester, Brightness.dark, locale: 'de');
    await togglePrivate(tester);
    await expectLater(
      find.byType(BottomSheet),
      matchesGoldenFile('goldens/create_folder_german.png'),
    );
  });
}
