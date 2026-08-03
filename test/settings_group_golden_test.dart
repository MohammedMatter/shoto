import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/grid_density_selector.dart';
import 'package:shoto/core/widgets/theme_mode_selector.dart';
import 'package:shoto/features/settings/presentation/widgets/settings_group.dart';
import 'package:shoto/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_fonts.dart';

/// Renders the Settings building blocks so the layout can be *looked at*.
///
/// Analyzer and unit tests say nothing about whether a screen reads well,
/// and this whole change is visual. Running with `--update-goldens` writes a
/// real PNG, which is the only honest way to review spacing, dividers and
/// grouping without a device attached.
///
/// It is not a regression gate — no committed baseline to compare against —
/// so it never fails a normal `flutter test` run.
void main() {
  testWidgets('settings groups render', (WidgetTester tester) async {
    await loadTestFonts();
    AppColors.setBrightness(Brightness.dark);

    tester.view.physicalSize = const Size(1080, 2100);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          // ThemeModeSelector reads `context.l10n` for its segment labels, so
          // without these it throws on a null AppLocalizations and this file
          // could not generate anything at all.
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: [
                  Text('Settings', style: AppTextStyles.headlineLarge),
                  SettingsGroup(
                    title: 'Appearance',
                    children: [
                      SettingsControlRow(
                        icon: Icons.contrast_rounded,
                        label: 'Theme',
                        control: ThemeModeSelector(
                          value: ThemeMode.dark,
                          onChanged: (_) {},
                        ),
                      ),
                      SettingsControlRow(
                        icon: Icons.grid_view_rounded,
                        label: 'Grid density',
                        control: GridDensitySelector(
                          value: 3,
                          onChanged: (_) {},
                        ),
                      ),
                    ],
                  ),
                  SettingsGroup(
                    title: 'Behaviour',
                    children: [
                      SettingsSwitchTile(
                        icon: Icons.vibration_rounded,
                        label: 'Haptic feedback',
                        description: 'A small tap when you press things',
                        value: true,
                        onChanged: (_) {},
                      ),
                      SettingsSwitchTile(
                        icon: Icons.shield_outlined,
                        label: 'Ask before deleting',
                        description: 'Deleting cannot be undone',
                        value: true,
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                  SettingsGroup(
                    title: 'Storage',
                    children: [
                      SettingsNavTile(
                        icon: Icons.content_copy_rounded,
                        label: 'Find duplicates',
                        description: 'Spot screenshots you took twice',
                        showProBadge: true,
                        onTap: () {},
                      ),
                      SettingsNavTile(
                        icon: Icons.cleaning_services_rounded,
                        label: 'Clear image cache',
                        description: '12.4 MB of thumbnails',
                        onTap: () {},
                      ),
                    ],
                  ),
                  SettingsGroup(
                    title: 'Account',
                    caption: 'mohammedabomatter@gmail.com',
                    children: [
                      SettingsNavTile(
                        icon: Icons.logout_rounded,
                        label: 'Sign out',
                        description: 'Your screenshots stay on this device',
                        isDestructive: true,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ListView),
      matchesGoldenFile('goldens/settings_groups.png'),
    );
  }, skip: !autoUpdateGoldenFiles);
}
