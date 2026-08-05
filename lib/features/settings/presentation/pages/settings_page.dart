import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/localization/locale_controller.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/grid_density_controller.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/widgets/grid_density_selector.dart';
import 'package:shoto/core/widgets/premium_gate.dart';
import 'package:shoto/core/widgets/privacy_note.dart';
import 'package:shoto/core/widgets/theme_mode_selector.dart';
import 'package:shoto/features/backup/presentation/pages/backup_page.dart';
import 'package:shoto/features/duplicates/presentation/pages/duplicates_page.dart';
import 'package:shoto/features/settings/presentation/widgets/app_version_block.dart';
import 'package:shoto/features/settings/presentation/widgets/contact_support_tile.dart';
import 'package:shoto/features/settings/presentation/widgets/language_sheet.dart';
import 'package:shoto/features/settings/presentation/widgets/owner_name_sheet.dart';
import 'package:shoto/features/settings/presentation/widgets/settings_group.dart';
import 'package:shoto/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:shoto/features/settings/presentation/widgets/subscription_card_widget.dart';
import 'package:shoto/features/subscription/domain/entities/premium_feature.dart';
import 'package:shoto/features/subscription/presentation/pages/whats_included_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
            // SettingsPage is kept alive inside MainShellPage's IndexedStack,
            // so it doesn't automatically rebuild just because the theme
            // toggle lives on this same page — without this, tapping
            // Light/Dark updated the pill selector but left every
            // AppColors.background/surface/border read on this page frozen at
            // whatever brightness it was first built with.
            // Merged rather than nested: both of these repaint the whole page,
            // and two nested builders would rebuild it twice for one change.
            // ProStatus is here because the PRO tags on the paid rows have to
            // come down the moment a subscription lands.
            listenable: Listenable.merge([
              sl<ThemeController>(),
              sl<ProStatus>(),
            ]),
            builder: (context, _) {
              // "This row is a paid feature" is not by itself a reason to show
              // the tag — the tag is a price, and it has nothing left to say once
              // the price is paid.
              final bool showProBadge = !sl<ProStatus>().isPro;

              return Scaffold(
                backgroundColor: AppColors.background,
                body: SafeArea(
                  bottom: false,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 130.h),
                    children: [
                      Text(
                        context.l10n.settingsTitle,
                        style: AppTextStyles.headlineLarge,
                      ),
                      SizedBox(height: 18.h),
                      // A profile card used to sit here: an avatar, a name and
                      // an email. With no account there is no name to put in
                      // it, and a card showing a grey silhouette next to the
                      // word "SHOTO" is a box that says nothing. The
                      // subscription card carries the one fact it was really
                      // for — whether this is Pro.
                      SubscriptionCard(),

                      // Appearance first: it is the setting people come here to
                      // change, and the only one whose effect is visible the
                      // instant they change it.
                      SettingsGroup(
                        title: context.l10n.settingsAppearance,
                        children: [
                          SettingsControlRow(
                            icon: Icons.contrast_rounded,
                            label: context.l10n.settingsTheme,
                            control: ListenableBuilder(
                              listenable: sl<ThemeController>(),
                              builder: (context, _) => ThemeModeSelector(
                                value: sl<ThemeController>().themeMode,
                                onChanged: (mode) =>
                                    sl<ThemeController>().setThemeMode(mode),
                              ),
                            ),
                          ),
                          SettingsControlRow(
                            icon: Icons.grid_view_rounded,
                            label: context.l10n.settingsGridDensity,
                            control: ListenableBuilder(
                              listenable: sl<GridDensityController>(),
                              builder: (context, _) => GridDensitySelector(
                                value: sl<GridDensityController>().columns,
                                onChanged: (columns) =>
                                    sl<GridDensityController>().setColumns(
                                      columns,
                                    ),
                              ),
                            ),
                          ),
                          // Language sits with theme rather than in its own
                          // group: they are the two settings someone changes to
                          // make the app feel like theirs, and separating them
                          // makes the second one hard to find.
                          ListenableBuilder(
                            listenable: sl<LocaleController>(),
                            builder: (context, _) {
                              final LocaleController locales =
                                  sl<LocaleController>();
                              return SettingsNavTile(
                                icon: Icons.translate_rounded,
                                label: context.l10n.settingsLanguage,
                                description:
                                    locales.language?.endonym ??
                                    context.l10n.settingsLanguageSystem,
                                onTap: () => showLanguageSheet(context),
                              );
                            },
                          ),
                        ],
                      ),

                      ListenableBuilder(
                        listenable: sl<AppPreferences>(),
                        builder: (context, _) {
                          final AppPreferences prefs = sl<AppPreferences>();
                          return SettingsGroup(
                            title: context.l10n.settingsBehaviour,
                            children: [
                              SettingsSwitchTile(
                                icon: Icons.vibration_rounded,
                                label: context.l10n.settingsHaptics,
                                description: context.l10n.settingsHapticsHint,
                                value: prefs.haptics,
                                // Fires the buzz on the way *on*, ignoring the
                                // preference it is in the middle of saving. A
                                // toggle whose only effect happens somewhere else,
                                // later, is one people assume is broken — which is
                                // exactly how this setting was reported.
                                onChanged: (bool value) {
                                  if (value) Haptics.demo();
                                  prefs.setHaptics(value);
                                },
                              ),
                              SettingsSwitchTile(
                                icon: Icons.shield_outlined,
                                label: context.l10n.settingsConfirmDelete,
                                description:
                                    context.l10n.settingsConfirmDeleteHint,
                                value: prefs.confirmBeforeDelete,
                                onChanged: prefs.setConfirmBeforeDelete,
                              ),
                              // Reachable here as well as from Home's
                              // invitation, because a one-time card is a fine
                              // way to *offer* something and a terrible way to
                              // let somebody change their mind about it two
                              // months later.
                              SettingsSwitchTile(
                                icon: Icons.inbox_outlined,
                                label: context.l10n.settingsTriage,
                                description: context.l10n.settingsTriageHint,
                                value: prefs.triageEnabled,
                                onChanged: prefs.setTriageEnabled,
                              ),
                              // The app's only personal field, and it sits
                              // with the other two preferences rather than in
                              // a group of its own, because it is the same
                              // kind of thing: something you set once so the
                              // app behaves the way you want later.
                              SettingsNavTile(
                                icon: Icons.badge_outlined,
                                label: context.l10n.settingsYourName,
                                description: prefs.ownerName.isEmpty
                                    ? context.l10n.settingsYourNameHint
                                    : prefs.ownerName,
                                onTap: () => showOwnerNameSheet(context),
                              ),
                            ],
                          );
                        },
                      ),

                      // "Find duplicates" used to sit alone under a heading
                      // called Tools while "Clear cache" sat under Privacy. Both
                      // are really the same job — reclaiming space — so they now
                      // share a group that says so. Backup joined them because
                      // it is the other thing you do *to* the library as a whole,
                      // and a group of one row would have buried it worse.
                      SettingsGroup(
                        title: context.l10n.settingsStorage,
                        children: [
                          // First in the group, and ungated. This is the row that
                          // matters most on the worst day somebody has with this
                          // app, and a paywall in front of "don't lose
                          // everything" is not a price, it is a hostage.
                          SettingsNavTile(
                            icon: Icons.backup_outlined,
                            label: context.l10n.settingsBackup,
                            description: context.l10n.settingsBackupHint,
                            onTap: () => Navigator.of(context).push(
                              FadeSlidePageRoute(builder: (_) => BackupPage()),
                            ),
                          ),
                          SettingsNavTile(
                            icon: Icons.content_copy_rounded,
                            label: context.l10n.settingsFindDuplicates,
                            description: context.l10n.settingsDuplicatesHint,
                            showProBadge: showProBadge,
                            onTap: () async {
                              if (!await ensurePremium(context)) return;
                              if (!context.mounted) return;
                              await Navigator.of(context).push(
                                FadeSlidePageRoute(
                                  builder: (_) => DuplicatesPage(),
                                ),
                              );
                            },
                          ),
                          SettingsClearCacheTile(),
                        ],
                      ),

                      SettingsGroup(
                        title: context.l10n.settingsPremium,
                        children: [
                          SettingsNavTile(
                            icon: Icons.workspace_premium_outlined,
                            label: context.l10n.settingsWhatsIncluded,
                            description: context.l10n.settingsFeatureCount(
                              PremiumFeature.all.length,
                            ),
                            // Not gated. This row answers "what do I get?", and
                            // gating it meant a subscriber's tap did nothing at
                            // all while everyone else got a price instead of an
                            // answer.
                            onTap: () => openWhatsIncludedPage(context),
                          ),
                          SettingsNavTile(
                            icon: Icons.ios_share_rounded,
                            label: context.l10n.settingsShare,
                            description: context.l10n.settingsShareHint,
                            onTap: () => SharePlus.instance.share(
                              ShareParams(text: context.l10n.settingsShareText),
                            ),
                          ),
                        ],
                      ),

                      // Above the privacy note because "something is wrong and
                      // I need a human" is the more urgent errand, and below
                      // the rest because it is not what most visits to
                      // Settings are for.
                      SettingsGroup(
                        title: context.l10n.settingsHelp,
                        children: const [ContactSupportTile()],
                      ),

                      // Not a group: this is the app's central promise, and a
                      // claim that reads like a settings row reads like fine
                      // print. It earns the space it takes.
                      SizedBox(height: 26.h),
                      const PrivacyNote(),

                      // There is no Account group, because there is no
                      // account. Restoring a purchase on a new phone is the
                      // store's job and it lives on the subscription card.
                      SizedBox(height: 34.h),
                      AppVersionBlock(),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
