import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/features/settings/presentation/widgets/settings_group.dart';
import 'package:shoto/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_fonts.dart';
import 'support/test_theme.dart';

/// Renders the Settings building blocks so the layout can be *looked at*.
///
/// Analyzer and unit tests say nothing about whether a screen reads well, and
/// this whole area is visual. The two goldens here are the only way to review
/// the row rhythm, the card grouping and the divider inset without a device
/// attached — and both modes matter, because the whole page is now carried by
/// value contrast rather than by colour, which is the one thing that does not
/// survive being checked in a single mode.
///
/// The rows are built by hand rather than by pumping the real page: that page
/// reaches into the service locator for six controllers and an auth session,
/// none of which a golden needs in order to show what a row looks like.
void main() {
  for (final Brightness brightness in <Brightness>[
    Brightness.dark,
    Brightness.light,
  ]) {
    final String name = brightness == Brightness.dark ? 'dark' : 'light';

    testWidgets('settings groups render — $name', (WidgetTester tester) async {
      await loadTestFonts();
      final AppPalette palette = testPalette(brightness);
      final AppTypography type = testTypography(brightness);

      tester.view.physicalSize = const Size(1080, 2250);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          builder: (BuildContext context, _) => MaterialApp(
            theme: testTheme(brightness),
            debugShowCheckedModeBanner: false,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              backgroundColor: palette.background,
              body: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  children: <Widget>[
                    Text('Settings', style: type.headlineLarge),
                    // Deliberately a mix of one-line and two-line rows, which
                    // is what the real page is: the point of the golden is to
                    // show that the two heights sit together without the list
                    // looking ragged.
                    SettingsGroup(
                      title: 'Appearance',
                      children: <Widget>[
                        SettingsNavTile(
                          icon: Icons.contrast_outlined,
                          label: 'Appearance',
                          value: 'Light',
                          onTap: () {},
                        ),
                        SettingsNavTile(
                          icon: Icons.language_outlined,
                          label: 'Language',
                          value: 'English',
                          onTap: () {},
                        ),
                      ],
                    ),
                    SettingsGroup(
                      title: 'Behaviour',
                      children: <Widget>[
                        SettingsSwitchTile(
                          icon: Icons.vibration_outlined,
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
                        SettingsSwitchTile(
                          icon: Icons.inbox_outlined,
                          label: 'Offer new screenshots',
                          description: 'Shows what you capture',
                          value: false,
                          onChanged: (_) {},
                        ),
                      ],
                    ),
                    SettingsGroup(
                      title: 'Storage',
                      children: <Widget>[
                        SettingsNavTile(
                          icon: Icons.backup_outlined,
                          label: 'Backup',
                          onTap: () {},
                        ),
                        SettingsNavTile(
                          icon: Icons.content_copy_outlined,
                          label: 'Find duplicates',
                          showProBadge: true,
                          onTap: () {},
                        ),
                        SettingsNavTile(
                          icon: Icons.cleaning_services_outlined,
                          label: 'Clear image cache',
                          value: '12.4 MB',
                          onTap: () {},
                        ),
                      ],
                    ),
                    SettingsGroup(
                      title: 'Account',
                      caption: 'mohammedabomatter@gmail.com',
                      children: <Widget>[
                        SettingsNavTile(
                          icon: Icons.logout_outlined,
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
        matchesGoldenFile('goldens/settings_groups_$name.png'),
      );
    });
  }
}
