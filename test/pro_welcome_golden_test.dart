import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/features/subscription/presentation/pages/pro_welcome_page.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_fonts.dart';
import 'support/test_theme.dart';

/// The moment a subscription completes, caught part-way through and at rest.
///
/// The mark is a tray with three screenshots filing into it, and the whole
/// argument for this screen is that the gesture lands — so the mid-flight frame
/// matters as much as the finished one, and neither is something an assertion
/// can judge. Generation-only, like the other goldens here.
void main() {
  /// `Haptics.confirm()` fires as the screen appears and reads the user's
  /// preference out of the service locator to decide whether to.
  setUpAll(() {
    if (!sl.isRegistered<AppPreferences>()) {
      sl.registerLazySingleton<AppPreferences>(() => AppPreferences());
    }
  });

  Future<void> render(WidgetTester tester, Brightness brightness) async {
    await loadTestFonts();

    tester.view.physicalSize = const Size(1080, 2100);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: testTheme(brightness),
          home: const ProWelcomePage(),
        ),
      ),
    );
  }

  testWidgets('pro welcome — mid-flight', (WidgetTester tester) async {
    await render(tester, Brightness.dark);
    // Roughly a third of the way through the 440ms file-in: the cards are on
    // their way down and the wordmark has not arrived yet.
    await tester.pump(const Duration(milliseconds: 150));
    await expectLater(
      find.byType(ProWelcomePage),
      matchesGoldenFile('goldens/pro_welcome_midflight.png'),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('pro welcome — dark', (WidgetTester tester) async {
    await render(tester, Brightness.dark);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ProWelcomePage),
      matchesGoldenFile('goldens/pro_welcome_dark.png'),
    );
  });

  testWidgets('pro welcome — light', (WidgetTester tester) async {
    await render(tester, Brightness.light);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ProWelcomePage),
      matchesGoldenFile('goldens/pro_welcome_light.png'),
    );
  });
}
