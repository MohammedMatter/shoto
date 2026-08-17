import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
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
import 'package:shoto/core/services/quick_tile.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/widgets/premium_gate.dart';
import 'package:shoto/core/widgets/pro_badge.dart';
import 'package:shoto/core/widgets/privacy_note.dart';
import 'package:shoto/features/settings/presentation/pages/appearance_page.dart';
import 'package:shoto/features/backup/presentation/pages/backup_page.dart';
import 'package:shoto/features/duplicates/presentation/pages/duplicates_page.dart';
import 'package:shoto/features/screenshots/domain/use_cases/request_photo_permission_use_case.dart';
import 'package:shoto/features/settings/presentation/widgets/app_version_block.dart';
import 'package:shoto/features/settings/presentation/widgets/capture_alerts_tile.dart';
import 'package:shoto/features/settings/presentation/widgets/contact_support_tile.dart';
import 'package:shoto/features/settings/presentation/widgets/language_sheet.dart';
import 'package:shoto/features/settings/presentation/widgets/quick_tile_sheet.dart';
import 'package:shoto/features/settings/presentation/widgets/settings_group.dart';
import 'package:shoto/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:shoto/features/settings/presentation/widgets/subscription_card_widget.dart';
import 'package:shoto/features/subscription/domain/entities/premium_feature.dart';
import 'package:shoto/features/subscription/presentation/pages/whats_included_page.dart';

/// **Settings is a page you are trying to leave, and it should be built like
/// one.**
///
/// Nobody comes here to read. They come to change one thing and go, and the
/// only question that matters is how fast they can find that one thing. This
/// page has been rebuilt around that twice now, and the two attempts are worth
/// keeping side by side because the second is a correction of the first.
///
/// **The first attempt marked the rows.** Every row got a hue off the tint
/// wheel on a pale plate — a colour per row, the wheel walked once from top to
/// bottom. It was consistent, it was contrast-safe, and it was decoration:
/// marking every item in a list marks nothing, and it spent the app's colour
/// vocabulary — red means destructive, green means done — on "this is the
/// haptics row". See [SettingsGlyph], where that is written down properly.
///
/// **The second attempt shortens the page instead**, which is what the first
/// one was reaching for. Three changes, none of them a colour:
///
/// 1. **Descriptions have to earn their line.** Seventeen rows each carrying a
///    sentence is seventeen paragraphs; the page was twice as tall as its
///    content and nothing on it led. A second line survives only where it says
///    something the label does not — what a switch will actually do, or a fact
///    like an address. "Watch the opening sequence again" under "Replay the
///    introduction" is the label written twice, and it is gone.
/// 2. **Every row that has an answer shows it.** Language says *English*, the
///    cache says *12.4 MB*, Appearance says *Light*, "What's included" says how
///    many features. A row that can be read without being opened is a tap
///    nobody has to spend.
/// 3. **The groups do the signposting**, with a third more air above each
///    heading and the heading itself set in sentence case at a size that can
///    be read — see [SettingsGroup].
///
/// What is left is one shape repeated: a quiet glyph, a label in medium, and
/// the answer on the trailing edge. The only colour on the page is the accent
/// on a switch that is on, and the red on Sign out.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// Stamped once, so the entrance below plays on the first visit and never
  /// again.
  ///
  /// This page is kept alive inside `MainShellPage`'s stack, so it is built the
  /// first time somebody opens Settings and then simply revealed on every visit
  /// after that. Holding the moment in state rather than computing it in
  /// `build` is what keeps a `ProStatus` change — a subscription landing while
  /// the page is on screen — from replaying the whole entrance. See
  /// [EntranceStagger], which closes its own window 400ms after this instant
  /// regardless.
  final DateTime _openedAt = DateTime.now();

  /// The name of the theme currently in force, for the Appearance row.
  String _themeLabel(BuildContext context) =>
      switch (sl<ThemeController>().themeMode) {
        ThemeMode.light => context.l10n.settingsThemeLight,
        ThemeMode.dark => context.l10n.settingsThemeDark,
        ThemeMode.system => context.l10n.settingsThemeSystem,
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // **[ThemeController] is merged back in, and it is not the reason it was
      // here before.**
      //
      // It used to be listened to because the theme pills lived on this page
      // and read the chosen mode off the controller directly — without a
      // listener they went on showing the old one, since this page is kept
      // alive in `MainShellPage`'s stack and does not rebuild on its own. Those
      // pills moved to the Appearance page, and the listener went with them.
      //
      // What brought it back is the Appearance row now *stating* the mode on
      // its trailing edge. Same failure if it is missing, arrived at from the
      // other direction: come back from switching to Dark and the row would sit
      // there saying "Light" until something else rebuilt the page.
      //
      // ProStatus is here because the PRO tags on the paid rows have to come
      // down the moment a subscription lands.
      listenable: Listenable.merge(<Listenable>[
        sl<ProStatus>(),
        sl<ThemeController>(),
      ]),
      builder: (BuildContext context, _) {
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
              children: <Widget>[
                Text(
                  context.l10n.settingsTitle,
                  style: context.text.headlineLarge,
                ),
                SizedBox(height: 18.h),
                // **The header and its card are one block for the entrance**,
                // because they are one thing being answered: who this is, and
                // what they are on. Staggering the avatar away from the card
                // under it would pull that apart for no reason.
                _Entering(
                  index: 0,
                  since: _openedAt,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Who this is, answered at the top of the screen where
                      // the question gets asked. It was taken out while there
                      // were no accounts — a grey silhouette beside the word
                      // "Shoto" is a box that says nothing — and it is back
                      // because there is a name and an address to put in it
                      // again.
                      _ProfileHeader(user: sl<AuthRepository>().currentUser),
                      SizedBox(height: 16.h),
                      // Carries the library's quota as its own last band — see
                      // [QuotaFooter] for why that is inside the card rather
                      // than loose beneath it.
                      const SubscriptionCard(),
                    ],
                  ),
                ),

                // Appearance first: it is the setting people come here to
                // change, and the only one whose effect is visible the
                // instant they change it.
                _Entering(
                  index: 1,
                  since: _openedAt,
                  child: SettingsGroup(
                    title: context.l10n.settingsAppearance,
                    children: <Widget>[
                      // **Theme, accent and grid density used to be rows here,
                      // each with a compact segmented control on its trailing
                      // edge.** They moved to a page of their own once the
                      // accent picker arrived: sixteen swatches and a preview
                      // cannot be squeezed onto a row's trailing edge, and a
                      // third appearance control appearing in a *third* shape
                      // would have made the top of Settings a museum of ways to
                      // present a choice.
                      //
                      // The row states the theme rather than the contents of
                      // the page behind it. "Theme, accent colour and grid
                      // size" was a table of contents for a screen one tap
                      // away; the mode in force is an answer, and it is the one
                      // most people opened the page to check.
                      SettingsNavTile(
                        icon: Icons.contrast_outlined,
                        label: context.l10n.settingsAppearance,
                        value: _themeLabel(context),
                        onTap: () => openAppearancePage(context),
                      ),
                      // Language sits with appearance rather than in its own
                      // group: they are the two settings someone changes to
                      // make the app feel like theirs, and separating them
                      // makes the second one hard to find.
                      ListenableBuilder(
                        listenable: sl<LocaleController>(),
                        builder: (BuildContext context, _) {
                          final LocaleController locales =
                              sl<LocaleController>();
                          return SettingsNavTile(
                            icon: Icons.language_outlined,
                            label: context.l10n.settingsLanguage,
                            // **Always the language actually being read**,
                            // never "Match my phone". This answers "what
                            // language is this app in", and the honest answer
                            // to that is the name of a language — the mechanism
                            // that chose it is not what was asked. It also
                            // matches the picker, which no longer has a row
                            // standing for the system default.
                            value:
                                (locales.language ?? locales.effectiveLanguage)
                                    .endonym,
                            onTap: () => showLanguageSheet(context),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                ListenableBuilder(
                  listenable: sl<AppPreferences>(),
                  builder: (BuildContext context, _) {
                    final AppPreferences prefs = sl<AppPreferences>();
                    return _Entering(
                      index: 2,
                      since: _openedAt,
                      child: SettingsGroup(
                        title: context.l10n.settingsBehaviour,
                        children: <Widget>[
                          // **The switches keep their second line and the
                          // navigation rows lost theirs.** A chevron promises a
                          // screen that will explain itself; a switch changes
                          // something the moment it is touched, and the sentence
                          // under it is the only warning of what.
                          SettingsSwitchTile(
                            icon: Icons.vibration_outlined,
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
                          // The on/off answer lives here; the queue itself is
                          // offered at the top of the Library, which is the
                          // screen somebody opens to deal with screenshots.
                          //
                          // Turning it on asks the OS for photo access, because
                          // the switch is worthless without it: the use case
                          // behind it returns an empty list forever and the
                          // screen would simply never have anything in it. If
                          // access is refused the switch goes back off rather
                          // than sitting on and doing nothing.
                          SettingsSwitchTile(
                            icon: Icons.inbox_outlined,
                            label: context.l10n.settingsTriage,
                            description: context.l10n.settingsTriageHint,
                            value: prefs.triageEnabled,
                            onChanged: (bool value) async {
                              if (!value) {
                                await prefs.setTriageEnabled(false);
                                return;
                              }
                              final PermissionState permission =
                                  await sl<RequestPhotoPermissionUseCase>()();
                              await prefs.setTriageEnabled(
                                permission.hasAccess,
                              );
                            },
                          ),
                          // Directly under the triage switch: the three rows in
                          // this run are one question asked at three moments —
                          // what has piled up (triage), what you just took
                          // (this), and the shortcut for fetching it yourself
                          // (the tile below).
                          const CaptureAlertsTile(),
                          // **The other way in, and the one that costs nothing
                          // to remember.** Everything Shoto can do is
                          // downstream of being handed a screenshot, and until
                          // now the only route was the share sheet — where the
                          // app's icon moves around a grid of twenty others
                          // that reorders itself by usage, so filing begins
                          // with a search.
                          //
                          // A Quick Settings tile is the one place on Android
                          // that never moves. It sits beside the torch, two
                          // gestures from any app, in the same square every
                          // time.
                          //
                          // It is an action rather than a setting, so the row
                          // does not pretend to hold a state it cannot read
                          // back: Android will not tell an app whether its tile
                          // is in the panel. That is also why it keeps its
                          // second line while the other navigation rows lost
                          // theirs — the label names a thing most people have
                          // never knowingly added to their phone.
                          if (QuickTile.isSupportedPlatform)
                            Builder(
                              builder: (BuildContext context) =>
                                  SettingsNavTile(
                                    icon: Icons.bolt_outlined,
                                    label: context.l10n.settingsQuickTile,
                                    description:
                                        context.l10n.settingsQuickTileHint,
                                    // **Explains before it asks.** This used
                                    // to fire Android's placement dialog on
                                    // the first tap, which spends one of the
                                    // handful of requests the platform will
                                    // honour on somebody who has read a label
                                    // and a hint line. See [showQuickTileSheet]
                                    // — the tile is the one feature in the app
                                    // that lives entirely outside it, and a
                                    // drawing of the panel is worth more than
                                    // any sentence about it.
                                    onTap: () => showQuickTileSheet(context),
                                  ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

                // "Find duplicates" used to sit alone under a heading
                // called Tools while "Clear cache" sat under Privacy. Both
                // are really the same job — reclaiming space — so they now
                // share a group that says so. Backup joined them because
                // it is the other thing you do *to* the library as a whole,
                // and a group of one row would have buried it worse.
                _Entering(
                  index: 3,
                  since: _openedAt,
                  child: SettingsGroup(
                    title: context.l10n.settingsStorage,
                    children: <Widget>[
                      // **The row is free; making a backup is not.**
                      //
                      // Gating the whole row was tried and taken back out,
                      // because it locked *restoring* too — and a user who
                      // backed up while subscribed, then lapsed, would have
                      // been unable to reach their own data. That is not a
                      // price, it is a hostage, and it is the one shape of
                      // paywall that can cost somebody something they already
                      // had.
                      //
                      // So the door stays open and the gate moved inside, onto
                      // the button that writes a new file. See [BackupPage].
                      SettingsNavTile(
                        icon: Icons.backup_outlined,
                        label: context.l10n.settingsBackup,
                        onTap: () => Navigator.of(context).push(
                          FadeSlidePageRoute(
                            builder: (_) => const BackupPage(),
                          ),
                        ),
                      ),
                      SettingsNavTile(
                        icon: Icons.content_copy_outlined,
                        label: context.l10n.settingsFindDuplicates,
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
                ),

                _Entering(
                  index: 4,
                  since: _openedAt,
                  child: SettingsGroup(
                    title: context.l10n.settingsPremium,
                    children: <Widget>[
                      SettingsNavTile(
                        icon: Icons.workspace_premium_outlined,
                        label: context.l10n.settingsWhatsIncluded,
                        // The count is an answer, so it sits where the answers
                        // sit rather than as a sentence under the label.
                        value: context.l10n.settingsFeatureCount(
                          PremiumFeature.all.length,
                        ),
                        // Not gated. This row answers "what do I get?", and
                        // gating it meant a subscriber's tap did nothing at
                        // all while everyone else got a price instead of an
                        // answer.
                        onTap: () => openWhatsIncludedPage(context),
                      ),
                      // Everyone, not just subscribers — see
                      // [RestorePurchasesTile] for the correction this is.
                      const RestorePurchasesTile(),
                      SettingsNavTile(
                        icon: Icons.share_outlined,
                        label: context.l10n.settingsShare,
                        onTap: () => SharePlus.instance.share(
                          ShareParams(text: context.l10n.settingsShareText),
                        ),
                      ),
                    ],
                  ),
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
                  builder: (BuildContext context, _) => _Entering(
                    index: 5,
                    since: _openedAt,
                    child: SettingsGroup(
                      title: context.l10n.settingsHelp,
                      children: <Widget>[
                        const ContactSupportTile(),
                        // Pushed rather than navigated to, so the introduction
                        // can pop back here when it ends. Going to it would
                        // strand a signed-in user on a screen whose only exit
                        // is the sign-in page — see `_finish` in
                        // `onboarding_page.dart`, which chooses between the
                        // two.
                        SettingsNavTile(
                          icon: Icons.slideshow_outlined,
                          label: context.l10n.settingsOnboarding,
                          onTap: () =>
                              context.pushNamed(AppRouter.onboardingPage),
                        ),
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
                ),

                // Not a group: this is the app's central promise, and a
                // claim that reads like a settings row reads like fine
                // print. It earns the space it takes.
                SizedBox(height: 32.h),
                const PrivacyNote(),

                // Signing out leaves the library, the folders and every
                // setting exactly where they are — all of it belongs to
                // the device, not to the account.
                SettingsGroup(
                  title: context.l10n.settingsAccount,
                  caption: sl<AuthRepository>().currentUser?.email,
                  children: <Widget>[
                    Builder(
                      builder: (BuildContext context) => SettingsNavTile(
                        icon: Icons.logout_outlined,
                        label: context.l10n.settingsSignOut,
                        // Kept, and one of the few that is. The line is not a
                        // description of the button, it is the answer to the
                        // question the button raises — "do I lose my
                        // screenshots?" — asked at the only moment it matters.
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

  /// Offers the Quick Settings tile, and says what happened either way.
  ///
  /// **Three answers, three different things to say.** Placed is a
  /// confirmation. Declined says nothing at all — the user has just told the
  /// system no, and the app repeating the offer in its own voice a moment
  /// later is nagging. Unsupported is the only case that owes an explanation,
  /// because there the button genuinely could not do the thing it named, and
  /// the manual route is still open.
}

/// One block of the page arriving on the first visit.
///
/// A thin wrapper over [EntranceStagger] so the page reads as a list of blocks
/// with an index rather than as a list of blocks each wrapped in four lines of
/// animation. Everything that decides whether the animation runs at all lives
/// in that widget: past six blocks, or past 400ms from [since], the child is
/// returned untouched, which is what stops this replaying every time the
/// subscription state changes underneath it.
///
/// **The whole page does not fade in as one piece**, and that is the point. A
/// single fade tells you the screen loaded; a stagger of 40ms between groups
/// tells you the screen has a structure, and it is over — six blocks, 240ms —
/// before anybody could call it an animation they had to wait for.
class _Entering extends StatelessWidget {
  final int index;
  final DateTime since;
  final Widget child;

  const _Entering({
    required this.index,
    required this.since,
    required this.child,
  });

  @override
  Widget build(BuildContext context) =>
      EntranceStagger(index: index, since: since, child: child);
}

/// The top of the page: who this is, and whether they are on Pro.
class _ProfileHeader extends StatelessWidget {
  final UserEntity? user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // The avatar's ring is the quietest of the app's three Pro signals and
      // the one most worth having: this is where somebody looks to answer
      // "what account am I on", and being on Pro is part of that answer.
      listenable: sl<ProStatus>(),
      builder: (BuildContext context, _) {
        final bool isPro = sl<ProStatus>().isPro;

        // **No card, and now for a second reason.**
        //
        // Every group on this page has one again, which makes the bare header
        // the thing that separates *who you are* from *what you can change* —
        // a page whose every block sat on a white slab would have no top to it
        // at all. The avatar is a strong enough shape to anchor the page on its
        // own; it does not need a rectangle drawn around it to be found.
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
          child: Row(
            children: <Widget>[
              // **A mount, not a ring** — and it is the same correction the
              // subscription card just had.
              //
              // This was a 1.5px accent stroke drawn at a distance around the
              // avatar. A hairline of even brightness all the way round is an
              // *outline*: a shape traced onto the page rather than something
              // the object is made of, and at full-strength accent it was also
              // the sharpest edge in the header — a thin bright circle that the
              // eye reads before the face inside it.
              //
              // What it is instead: the avatar is **set into a disc of the
              // accent's own material**, the way a photograph is set into a mat
              // rather than framed in wire. No stroke anywhere, so nothing
              // competes with the picture's own edge; the collar is simply a
              // wider circle in a colour, and a person reads "this one is
              // mounted" without ever locating a line.
              //
              // Opaque rather than translucent for the reason the card's fill
              // is (see `subscription_card_widget.dart`): this sits directly on
              // the canvas, and a see-through wash over near-black reads as
              // haze rather than as colour.
              //
              // The padding is unconditional, so the avatar keeps its size and
              // position whether or not the mount is there — a Pro badge
              // arriving must not shuffle the header.
              Container(
                // **Thickness is what makes it a mount instead of a ring**, and
                // the first attempt proved it: the same colour at the stroke's
                // old 3px was still a thin band of even width tracing a circle,
                // which is an outline whatever it is painted with. At 5 it has
                // an area, and an area reads as a material the avatar is set
                // into.
                padding: EdgeInsets.all(5.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPro
                      ? Color.alphaBlend(
                          context.colors.primary.withValues(alpha: 0.34),
                          context.colors.background,
                        )
                      : Colors.transparent,
                ),
                child: Container(
                  width: 48.w,
                  height: 48.w,
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
                          Icons.person_outline_rounded,
                          color: context.colors.textSecondary,
                          size: 24.sp,
                        )
                      : null,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            (user?.name?.isNotEmpty ?? false)
                                ? user!.name!
                                : 'Shoto',
                            style: context.text.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPro) ...<Widget>[
                          SizedBox(width: 8.w),
                          const ProBadge(),
                        ],
                      ],
                    ),
                    if (user?.email != null) ...<Widget>[
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
