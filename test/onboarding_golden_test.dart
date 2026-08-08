import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/features/onboarding/presentation/pages/onboarding_page.dart';

import 'support/test_fonts.dart';
import 'support/test_theme.dart';

/// Renders every stage of the introduction so the sequence can be *looked at*.
///
/// The whole idea of this screen is spatial — nine cards being rearranged —
/// and no assertion can tell you whether an arrangement reads as a pile, as a
/// filed stack, or as a mess. With no device attached this is the only honest
/// review there is.
///
/// It is also the first screen in the app that can be rendered from nothing:
/// deleting its data source, repository, use case and bloc left a page that
/// needs a locale and a canvas and no service locator at all.
void main() {
  Future<void> open(WidgetTester tester, Brightness brightness) async {
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
          home: const OnboardingPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> step(WidgetTester tester, int index) async {
    await tester.tap(find.byKey(ValueKey<String>('onboarding-step-$index')));
    await tester.pumpAndSettle();
  }

  // Named for what each stage says, not for the drawing on it. The names used
  // to be `pile`, `chosen` and `pro` — from an introduction with five stages
  // in a different order, where `pro` was a price list. A golden called
  // `chosen` showing the Safe Share cover is a filename that has to be opened
  // to be disbelieved.
  for (final (int index, String name) in const <(int, String)>[
    (0, 'inside'),
    (1, 'send'),
    (2, 'yours'),
  ]) {
    testWidgets('onboarding — $name', (WidgetTester tester) async {
      await open(tester, Brightness.light);
      if (index > 0) await step(tester, index);
      await expectLater(
        find.byType(OnboardingPage),
        matchesGoldenFile('goldens/onboarding_$name.png'),
      );
    });
  }

  testWidgets('onboarding — inside, dark', (WidgetTester tester) async {
    await open(tester, Brightness.dark);
    await expectLater(
      find.byType(OnboardingPage),
      matchesGoldenFile('goldens/onboarding_inside_dark.png'),
    );
  });

  testWidgets('onboarding — yours, dark', (WidgetTester tester) async {
    await open(tester, Brightness.dark);
    await step(tester, 2);
    await expectLater(
      find.byType(OnboardingPage),
      matchesGoldenFile('goldens/onboarding_yours_dark.png'),
    );
  });
}
