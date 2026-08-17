import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/features/settings/presentation/widgets/subscription_card_widget.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_fonts.dart';
import 'support/test_theme.dart';

/// Both states of the Settings subscription card, for looking at.
///
/// The two are meant to read as one object in two conditions rather than as
/// two unrelated cards: the free card names three features and closes with the
/// total, the Pro card lights every feature icon at once. Whether that
/// actually lands is a question about a picture, so this writes one.
///
/// The private widgets are exercised through [debugSubscriptionCardStates],
/// which exists only so this file can reach them — building the real
/// [SubscriptionCard] would need the service locator, RevenueCat and a
/// resolved [ProStatus], none of which say anything about the layout.
///
/// Generation-only, like the other goldens here: no committed baseline, never
/// fails a normal run.
void main() {
  Future<void> render(WidgetTester tester, Brightness brightness) async {
    await loadTestFonts();
    final AppPalette palette = testPalette(brightness);

    tester.view.physicalSize = const Size(1080, 2300);
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
          home: Scaffold(
            backgroundColor: palette.background,
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final Widget card in debugSubscriptionCardStates) ...[
                    card,
                    const SizedBox(height: 18),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('subscription cards — dark', (WidgetTester tester) async {
    await render(tester, Brightness.dark);
    await expectLater(
      find.byType(SingleChildScrollView),
      matchesGoldenFile('goldens/subscription_cards_dark.png'),
    );
  });

  testWidgets('subscription cards — light', (WidgetTester tester) async {
    await render(tester, Brightness.light);
    await expectLater(
      find.byType(SingleChildScrollView),
      matchesGoldenFile('goldens/subscription_cards_light.png'),
    );
  });

}
