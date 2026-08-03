import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/app_bottom_nav_bar.dart';

import 'support/test_fonts.dart';

/// The nav bar is the only frosted surface that is on screen all the time, so
/// its blur is the only one charged to every scroll in the app. It was dropped
/// from sigma 30 to 14 and its fill opacity raised to compensate.
///
/// Whether that compensation actually holds is not something an assertion can
/// answer — it is a question about whether the bar still reads as glass. So
/// this renders it over a deliberately busy, high-contrast background (the
/// worst case: if the blur were doing nothing, the stripes would show through
/// crisply) in both modes, for a person to look at.
///
/// Generation-only, like the other goldens here: no committed baseline, never
/// fails a normal run.
void main() {
  Future<void> renderBar(WidgetTester tester, Brightness brightness) async {
    await loadTestFonts();
    AppColors.setBrightness(brightness);

    tester.view.physicalSize = const Size(1080, 900);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              children: [
                // Something with hard edges to blur, so the frost is visible
                // rather than assumed.
                Positioned.fill(
                  child: Column(
                    children: [
                      for (int i = 0; i < 9; i++)
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: i.isEven
                                ? AppColors.primary
                                : AppColors.surfaceVariant,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              'a screenshot behind the bar $i',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: i.isEven
                                    ? AppColors.onPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AppBottomNavBar(
                    currentIndex: 1,
                    onTap: (_) {},
                    items: const [
                      AppNavItem(
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard_rounded,
                        label: 'Home',
                      ),
                      AppNavItem(
                        icon: Icons.photo_library_outlined,
                        activeIcon: Icons.photo_library_rounded,
                        label: 'Library',
                      ),
                      AppNavItem(
                        icon: Icons.folder_outlined,
                        activeIcon: Icons.folder_rounded,
                        label: 'Folders',
                      ),
                      AppNavItem(
                        icon: Icons.settings_outlined,
                        activeIcon: Icons.settings_rounded,
                        label: 'Settings',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('nav bar glass — light', (WidgetTester tester) async {
    await renderBar(tester, Brightness.light);
    await expectLater(
      find.byType(Stack).first,
      matchesGoldenFile('goldens/nav_bar_light.png'),
    );
  }, skip: !autoUpdateGoldenFiles);

  testWidgets('nav bar glass — dark', (WidgetTester tester) async {
    await renderBar(tester, Brightness.dark);
    await expectLater(
      find.byType(Stack).first,
      matchesGoldenFile('goldens/nav_bar_dark.png'),
    );
  }, skip: !autoUpdateGoldenFiles);
}
