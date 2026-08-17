import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/features/onboarding/presentation/pages/onboarding_page.dart';

import 'support/test_fonts.dart';
import 'support/test_theme.dart';

/// Renders the opening and every stage of the introduction so the sequence can
/// be *looked at*.
///
/// The whole idea of this screen is spatial — twenty-six cards falling into the
/// mark, then nine being rearranged — and no assertion can tell you whether an
/// arrangement reads as a pile, as a filed stack, or as a mess. With no device
/// attached this is the only honest review there is.
///
/// It is also the first screen in the app that can be rendered from nothing:
/// deleting its data source, repository, use case and bloc left a page that
/// needs a locale and a canvas and no service locator at all.
void main() {
  Future<void> open(
    WidgetTester tester,
    Brightness brightness, {
    bool stages = false,
  }) async {
    await loadTestFonts();

    tester.view.physicalSize = const Size(1080, 2100);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          theme: testTheme(brightness),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingPage(startAtStages: stages),
        ),
      ),
    );
  }

  /// The stages, arrived.
  ///
  /// Entered through [OnboardingPage.startAtStages] rather than by tapping the
  /// button at the end of the opening: that button is a [PrimaryButton], which
  /// fires haptics, which reach into a service locator this test does not have.
  Future<void> begin(WidgetTester tester) => tester.pumpAndSettle();

  Future<void> step(WidgetTester tester, int index) async {
    await tester.tap(find.byKey(ValueKey<String>('onboarding-step-$index')));
    await tester.pumpAndSettle();
  }

  // **The fall, caught mid-air.** Pumped to a fixed offset rather than settled,
  // because the one frame worth reviewing here is one nobody can reach with
  // `pumpAndSettle`: cards at four sizes on their way down, and the mark low in
  // the frame catching them. The offset is deliberate — 1.9s of a 5.2s opening
  // is the densest moment of the fall.
  testWidgets('onboarding — the fall', (WidgetTester tester) async {
    await open(tester, Brightness.dark);
    await tester.pump(const Duration(milliseconds: 1900));
    await expectLater(
      find.byType(OnboardingPage),
      matchesGoldenFile('goldens/onboarding_fall.png'),
    );
  });

  testWidgets('onboarding — welcome', (WidgetTester tester) async {
    await open(tester, Brightness.dark);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(OnboardingPage),
      matchesGoldenFile('goldens/onboarding_welcome.png'),
    );
  });

  testWidgets('onboarding — welcome, light', (WidgetTester tester) async {
    await open(tester, Brightness.light);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(OnboardingPage),
      matchesGoldenFile('goldens/onboarding_welcome_light.png'),
    );
  });

  // Named for what each stage says, not for the drawing on it. A golden called
  // `chosen` showing the Safe Share cover is a filename that has to be opened
  // to be disbelieved.
  for (final (int index, String name) in const <(int, String)>[
    (0, 'save'),
    (1, 'file'),
    (2, 'find'),
    (3, 'send'),
    (4, 'yours'),
  ]) {
    testWidgets('onboarding — $name', (WidgetTester tester) async {
      await open(tester, Brightness.light, stages: true);
      await begin(tester);
      if (index > 0) await step(tester, index);
      await expectLater(
        find.byType(OnboardingPage),
        matchesGoldenFile('goldens/onboarding_$name.png'),
      );
    });
  }

  testWidgets('onboarding — save, dark', (WidgetTester tester) async {
    await open(tester, Brightness.dark, stages: true);
    await begin(tester);
    await expectLater(
      find.byType(OnboardingPage),
      matchesGoldenFile('goldens/onboarding_save_dark.png'),
    );
  });

  testWidgets('onboarding — yours, dark', (WidgetTester tester) async {
    await open(tester, Brightness.dark, stages: true);
    await begin(tester);
    await step(tester, 4);
    await expectLater(
      find.byType(OnboardingPage),
      matchesGoldenFile('goldens/onboarding_yours_dark.png'),
    );
  });

  // The stage a translation is most likely to break: three chips wrapping to a
  // second line, under a two-line German headline, on the shortest phone the
  // app supports and with the system type turned up.
  testWidgets('onboarding — save, small screen, German', (
    WidgetTester tester,
  ) async {
    await loadTestFonts();

    tester.view.physicalSize = const Size(1080, 1780);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          theme: testTheme(Brightness.dark),
          debugShowCheckedModeBanner: false,
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 1.3,
            maxScaleFactor: 1.3,
            child: child!,
          ),
          home: const OnboardingPage(startAtStages: true),
        ),
      ),
    );

    await begin(tester);
    await expectLater(
      find.byType(OnboardingPage),
      matchesGoldenFile('goldens/onboarding_save_german.png'),
    );
  });
}
