import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/localization/locale_controller.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:go_router/go_router.dart';
import 'package:shoto/core/routes/app_router.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/crash_reporting.dart';
import 'package:shoto/core/widgets/confirm_dialog.dart';
import 'package:shoto/features/auth/domain/entities/user_entity.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';
import 'package:shoto/features/auth/domain/use_cases/sign_out_use_case.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/grid_density_controller.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/widgets/grid_density_selector.dart';
import 'package:shoto/core/widgets/premium_gate.dart';
import 'package:shoto/core/widgets/pro_badge.dart';
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
      // toggle lives on this same page. The colours no longer need this
      // — they come from the theme, and changing it rebuilds every
      // dependent wherever it sits — but the pill selector does: it
      // reads the chosen mode off the controller directly, and without
      // a listener it would go on showing the old one.
      // Merged rather than nested: both of these repaint the whole page,
      // and two nested builders would rebuild it twice for one change.
      // ProStatus is here because the PRO tags on the paid rows have to
      // come down the moment a subscription lands.
      listenable: Listenable.merge([sl<ThemeController>(), sl<ProStatus>()]),
      builder: (context, _) {
        // "This row is a paid feature" is not by itself a reason to show
        // the tag — the tag is a price, and it has nothing left to say once
        // the price is paid.
        final bool showProBadge = !sl<ProStatus>().isPro;

        return Scaffold(
          backgroundColor: context.colors.background,
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 130.h),
              children: [
                Text(
                  context.l10n.settingsTitle,
                  style: context.text.headlineLarge,
                ),
                SizedBox(height: 18.h),
                // Who this is, answered at the top of the screen where
                // the question gets asked. It was taken out while there
                // were no accounts — a grey silhouette beside the word
                // "SHOTO" is a box that says nothing — and it is back
                // because there is a name and an address to put in it
                // again.
                _ProfileCard(user: sl<AuthRepository>().currentUser),
                SizedBox(height: 16.h),
                const SubscriptionCard(),

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
                              sl<GridDensityController>().setColumns(columns),
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
                        final LocaleController locales = sl<LocaleController>();
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
                          description: context.l10n.settingsConfirmDeleteHint,
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
                        FadeSlidePageRoute(builder: (_) => const BackupPage()),
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
                            builder: (_) => const DuplicatesPage(),
                          ),
                        );
                      },
                    ),
                    const SettingsClearCacheTile(),
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
                // The crash switch sits with support rather than with
                // the other preferences, because it belongs to the same
                // errand: something went wrong and you want it fixed.
                // One of the two rows tells a human; the other tells the
                // code, without you having to write anything.
                ListenableBuilder(
                  listenable: sl<CrashReporting>(),
                  builder: (context, _) => SettingsGroup(
                    title: context.l10n.settingsHelp,
                    children: [
                      const ContactSupportTile(),
                      SettingsSwitchTile(
                        icon: Icons.bug_report_outlined,
                        label: context.l10n.settingsCrashReports,
                        description: context.l10n.settingsCrashReportsHint,
                        value: sl<CrashReporting>().isEnabled,
                        onChanged: (bool value) =>
                            sl<CrashReporting>().setEnabled(value),
                      ),
                    ],
                  ),
                ),

                // Not a group: this is the app's central promise, and a
                // claim that reads like a settings row reads like fine
                // print. It earns the space it takes.
                SizedBox(height: 26.h),
                const PrivacyNote(),

                // Signing out leaves the library, the folders and every
                // setting exactly where they are — all of it belongs to
                // the device, not to the account.
                SettingsGroup(
                  title: context.l10n.settingsAccount,
                  caption: sl<AuthRepository>().currentUser?.email,
                  children: [
                    Builder(
                      builder: (context) => SettingsNavTile(
                        icon: Icons.logout_rounded,
                        label: context.l10n.settingsSignOut,
                        description: context.l10n.settingsSignOutHint,
                        isDestructive: true,
                        onTap: () async {
                          final bool confirmed = await showConfirmDialog(
                            context,
                            title: context.l10n.settingsSignOutTitle,
                            message: context.l10n.settingsSignOutHint,
                            confirmLabel: context.l10n.settingsSignOut,
                            isDestructive: true,
                          );
                          if (!confirmed || !context.mounted) return;

                          await sl<SignOutUseCase>()();
                          if (!context.mounted) return;
                          context.goNamed(AppRouter.authPage);
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 34.h),
                const AppVersionBlock(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserEntity? user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // The avatar's ring is the quietest of the app's three Pro signals and
      // the one most worth having: this card is where somebody looks to answer
      // "what account am I on", and being on Pro is part of that answer.
      listenable: sl<ProStatus>(),
      builder: (context, _) {
        final bool isPro = sl<ProStatus>().isPro;

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: [
              // A ring *around* the avatar rather than a border on it, so a
              // photograph is not cropped by a stroke drawn over its own edge.
              // Padding when there is no ring keeps the avatar the same size
              // and in the same place either way — a Pro badge arriving must
              // not shuffle the card.
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isPro ? context.colors.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Container(
                  width: 46.w,
                  height: 46.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.surfaceVariant,
                    image: user?.photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(user!.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: user?.photoUrl == null
                      ? Icon(
                          Icons.person_rounded,
                          color: context.colors.textSecondary,
                          size: 23.sp,
                        )
                      : null,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            (user?.name?.isNotEmpty ?? false)
                                ? user!.name!
                                : 'SHOTO',
                            style: context.text.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPro) ...[SizedBox(width: 8.w), const ProBadge()],
                      ],
                    ),
                    if (user?.email != null) ...[
                      SizedBox(height: 1.h),
                      Text(
                        user!.email!,
                        style: context.text.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
