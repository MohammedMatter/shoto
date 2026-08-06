import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/grid_density_controller.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_fonts.dart';
import 'support/test_theme.dart';

/// Renders the Library density button in each of its three states.
///
/// The whole complaint was that the icon never changed, so the fix is only a
/// fix if the three icons are *visibly different* — something no assertion
/// can tell me and the analyzer certainly can't. This writes a PNG to look
/// at, with the Material icon font loaded so the glyphs are real rather than
/// the empty boxes `flutter test` draws by default.
///
/// Generation-only, like the settings golden: skipped on a normal run.
void main() {
  testWidgets('density icons are distinguishable', (WidgetTester tester) async {
    await loadTestFonts();
    const Brightness brightness = Brightness.dark;
    final AppPalette palette = testPalette(brightness);
    final AppTypography type = testTypography(brightness);

    tester.view.physicalSize = const Size(900, 460);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          theme: testTheme(brightness),
          debugShowCheckedModeBanner: false,
          // The density names are translated now, so `labelFor` needs a
          // context that can reach AppLocalizations.
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Builder, not the ScreenUtilInit context above: `labelFor` reads
          // AppLocalizations, and the builder's context sits *above*
          // MaterialApp where no Localizations exists yet.
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              backgroundColor: palette.background,
              body: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final int columns in GridDensityController.options)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: palette.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: palette.border),
                            ),
                            child: Icon(
                              GridDensityController.iconFor(columns),
                              color: palette.textPrimary,
                              size: 27,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${GridDensityController.labelFor(context, columns)}\n'
                            '$columns columns',
                            textAlign: TextAlign.center,
                            style: type.caption,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Row).first,
      matchesGoldenFile('goldens/grid_density_icons.png'),
    );
  });
}
