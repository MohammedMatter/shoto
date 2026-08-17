import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/app_tint.dart';

import 'support/test_fonts.dart';
import 'support/test_theme.dart';

/// Every accent the picker offers, in both modes, laid out as the picker lays
/// them out.
///
/// **`app_tint_test.dart` cannot answer the only question that matters here.**
/// It proves each tint is solved, lands on the shipped luminance and clears AA
/// on every surface — all of which was already true of the palette people
/// complained about, because the complaint was that the colours were *muddy*
/// and muddiness is not a contrast failure. Chroma is invisible to every
/// assertion in that file: a tint at half its available saturation passes each
/// one.
///
/// So this is the counterpart, and it is a picture on purpose. The things it is
/// here to catch are all things you can only see — a hue that has gone grey, two
/// neighbours that have collapsed into one colour, a family that stops looking
/// like a family. Regenerate it after any change to the hues or the saturations
/// and then *look at the PNG*; a golden that passes after being regenerated has
/// proven nothing.
///
/// Each swatch carries its accent above its pressed [AppTint.variant], because
/// the pair is what a filled control actually uses and a variant that has
/// drifted off-hue is the other failure that only shows up side by side.
void main() {
  for (final Brightness brightness in <Brightness>[
    Brightness.light,
    Brightness.dark,
  ]) {
    final String name = brightness == Brightness.dark ? 'dark' : 'light';

    testWidgets('every tint, $name', (WidgetTester tester) async {
      await loadTestFonts();
      final AppPalette palette = testPalette(brightness);
      final AppTypography type = testTypography(brightness);
      final bool isDark = brightness == Brightness.dark;

      tester.view.physicalSize = const Size(1080, 1750);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          builder: (BuildContext context, _) => MaterialApp(
            theme: testTheme(brightness),
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: palette.background,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.92,
                    children: <Widget>[
                      for (final AppTint tint in AppTint.all)
                        Column(
                          children: <Widget>[
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                child: Column(
                                  children: <Widget>[
                                    // The accent, carrying the one foreground
                                    // the whole system relies on.
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        width: double.infinity,
                                        color: tint.accent(isDark: isDark),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: palette.onPrimary,
                                        ),
                                      ),
                                    ),
                                    // The pressed step under it.
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        color: tint.variant(isDark: isDark),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              tint.id,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
        find.byType(GridView),
        matchesGoldenFile('goldens/tint_palette_$name.png'),
      );
    });
  }
}
