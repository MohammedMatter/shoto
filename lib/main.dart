import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/app_locales.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/localization/locale_controller.dart';
import 'package:shoto/core/routes/app_router.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/crash_reporting.dart';
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/core/services/funnel_log.dart';
import 'package:shoto/core/services/local_identity.dart';
import 'package:shoto/core/services/feature_trials.dart';
import 'package:shoto/core/services/library_quota.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_scroll_behavior.dart';
import 'package:shoto/core/theme/app_theme.dart';
import 'package:shoto/core/theme/grid_density_controller.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/features/quick_save/presentation/pages/quick_save_page.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Sharing an image into Shoto starts a different Android activity, which
  // asks Flutter to begin on "/share". Branching here rather than inside the
  // router keeps the share sheet completely outside the app's navigation —
  // it is a self-contained screen, not a page of Shoto.
  //
  // Decided *first* because it also decides how much has to finish loading
  // before anything can be drawn.
  final bool isShareSheet =
      PlatformDispatcher.instance.defaultRouteName == '/share';

  // Every registration is lazy, so this constructs nothing — safe to run
  // before Firebase is ready, and it lets the work below start in parallel.
  setupServiceLocator();

  if (isShareSheet) {
    // The share sheet was taking over two seconds to appear from a cold
    // start, and a noticeable part of that was this function loading things
    // the sheet never looks at: grid density (it has no grid), developer
    // access and the subscription repository.
    //
    // **The sheet is no longer entirely free**, since it now offers covering
    // and Safe Share is paid — but the subscription stack still does not
    // belong here. Most shares are filing, filing is free, and charging every
    // one of them a store round trip to serve the minority that go the other
    // way is the wrong trade in front of the one screen where latency is least
    // affordable. `ensurePremiumServicesReady` brings it up on the tap
    // instead; see premium_bootstrap.dart for the whole argument.
    //
    // Waiting for any of this was pure delay in front of the one screen
    // where delay is least acceptable — the user is mid-gesture in another
    // app, and a sheet that arrives late has already lost the point of not
    // opening the app at all.
    //
    // These four are genuinely needed before the first frame: the identity
    // decides where the image is filed, the language and theme decide how it
    // is drawn, and haptics fire on the first tap.
    await Future.wait([
      sl<LocalIdentity>().load(),
      sl<LocaleController>().load(),
      sl<ThemeController>().load(),
      sl<AppPreferences>().load(),
      // The share sheet is the *primary* way screenshots enter the library,
      // so leaving it out here would mean the activation step was only ever
      // counted on the rarer path through the app's own picker. It is one
      // more read of a SharedPreferences instance the three loads above have
      // already warmed, so it costs nothing on the path that can least
      // afford anything.
      sl<FunnelLog>().load(),
    ]);
    runApp(const QuickSaveApp());
    return;
  }

  // **Firebase must be ready before the router is built**, and that is not a
  // preference — it is a hard ordering constraint. `AppRouter` asks
  // `AuthRepository.currentUser` to decide whether the first screen is the
  // sign-in page or Home, and reading that with no initialized app throws
  // `[core/no-app]` while the router is being constructed, which produces a
  // blank grey screen and no error anywhere the user can see.
  //
  // Started rather than awaited on its own line: none of the preference loads
  // below depend on it, so they overlap with it instead of queueing behind
  // the slowest thing in startup.
  //
  // The share sheet above deliberately never reaches this — it has no
  // navigation and no account, so it does not pay for either.
  final Future<void> firebaseReady = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Future.wait([
    firebaseReady,
    sl<LocalIdentity>().load(),
    sl<LocaleController>().load(),
    sl<ThemeController>().load(),
    sl<GridDensityController>().load(),
    sl<AppPreferences>().load(),
    // Before the subscription repository is asked anything — every premium
    // gate reads its answer from there, and it consults this.
    sl<DevAccess>().load(),
    // Records "installed" on the first launch that reaches this line, which
    // is every first launch: nothing above it can fail without the app
    // failing too. A denominator counted anywhere later would quietly be
    // measuring something narrower than installs.
    sl<FunnelLog>().load(),
  ]);

  // **After Firebase, before the first frame, and before anything that could
  // throw.** Collection is a property of the SDK rather than a check at the
  // moment of a crash, so leaving it at its default until somebody opens
  // Settings would send whatever happened in between — from a user who has
  // not agreed to send anything. Reading the stored answer here is what makes
  // "off unless you turned it on" true rather than approximately true.
  await sl<CrashReporting>().load();
  sl<CrashReporting>().install();

  // Safe to await even with no RevenueCat project configured yet — it
  // no-ops rather than throwing. See RevenueCatDataSource. Sequenced after
  // DevAccess on purpose, per the note above.
  await sl<SubscriptionRepository>().initialize();

  // Resolved before the first frame so anything that paints a Pro badge —
  // Home's wordmark, the settings profile card — is already right rather than
  // lighting up a moment after launch, which reads as the app changing its
  // mind about who you are. Awaited because it is a local read plus one
  // already-warm RevenueCat call, and because `ProStatus` deliberately keeps
  // "not known yet" distinct from "not subscribed": leaving it unresolved
  // would mean a subscriber's first frame has no badge on it.
  await sl<ProStatus>().load();

  // Awaited for the same reason, one step smaller: the tool rows on Home paint
  // a "1 free try" tag straight from this, and a tag that fades in after the
  // first frame reads as the app changing its offer while you look at it. Two
  // integers out of the SharedPreferences instance every load above has
  // already warmed.
  await sl<FeatureTrials>().load();

  // After ProStatus, because the ceiling it reports depends on the answer that
  // call just resolved. Not awaited: this is a local `COUNT(*)` feeding one
  // meter three screens deep in Settings, and nothing on the first frame is
  // waiting on it — unlike a Pro badge, a quota bar that arrives a moment late
  // is a bar nobody was looking at yet.
  unawaited(sl<LibraryQuota>().load());

  runApp(const MyApp());
}

/// The theme actually applied, which is not always the one that was chosen.
///
/// **Dark is a paid preference; darkness is not.** [ThemeMode.system] stays
/// free forever, so a free user whose phone is in dark mode still gets a dark
/// Shoto — anything else would have the app fighting the device every evening
/// and reading as broken rather than as locked. What Pro buys is pinning the
/// app dark *regardless* of the phone.
///
/// Resolved here rather than written back to storage, and that distinction
/// matters in both directions: somebody who chose dark before it was paid for
/// keeps their choice on record and gets it back the instant they subscribe,
/// and nobody's saved setting is silently rewritten by an app update.
///
/// The share sheet deliberately does not do this. It never loads
/// [ProStatus] — see the fast path in `main` — so it would read every user as
/// free and drop a subscriber's dark app back to their phone's setting for the
/// two seconds the sheet is up.
ThemeMode _effectiveThemeMode(ThemeMode chosen) =>
    chosen == ThemeMode.dark && !sl<ProStatus>().isPro
    ? ThemeMode.system
    : chosen;

/// The whole app when launched from another app's share sheet.
class QuickSaveApp extends StatelessWidget {
  const QuickSaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (context, child) {
        final AppLanguage language = sl<LocaleController>().effectiveLanguage;

        // Follows the theme the user picked *inside Shoto*, not the system's.
        // Reading platform brightness here made the sheet appear dark over a
        // light app whenever the two disagreed, which reads as a different
        // app's UI rather than Shoto's.
        final ThemeMode themeMode = sl<ThemeController>().themeMode;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          scrollBehavior: const AppScrollBehavior(),
          locale: sl<LocaleController>().locale,
          supportedLocales: AppLanguage.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(language),
          darkTheme: AppTheme.dark(language),
          themeMode: themeMode,
          themeAnimationDuration: Duration.zero,
          home: const QuickSavePage(),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ListenableBuilder(
          // Merged rather than nested: theme and language both repaint the
          // entire app, and two nested builders would rebuild it twice for
          // one change.
          listenable: Listenable.merge([
            sl<ThemeController>(),
            sl<LocaleController>(),
            // Subscribing or lapsing changes which theme applies without the
            // stored preference moving — see [_effectiveThemeMode].
            sl<ProStatus>(),
          ]),
          builder: (context, _) {
            final ThemeMode themeMode = _effectiveThemeMode(
              sl<ThemeController>().themeMode,
            );
            final LocaleController locales = sl<LocaleController>();

            final AppLanguage language = locales.effectiveLanguage;
            // Resolved here as well as by `MaterialApp.themeMode`, because the
            // system bars are set from *outside* the app's own theme — there
            // is no context below `MaterialApp` at this point to read
            // `context.colors` from, and the very first frame has to already
            // be right.
            final Brightness resolvedBrightness = switch (themeMode) {
              ThemeMode.light => Brightness.light,
              ThemeMode.dark => Brightness.dark,
              ThemeMode.system => MediaQuery.platformBrightnessOf(context),
            };
            final AppPalette palette = AppPalette.of(resolvedBrightness);

            final bool isDark = palette.isDark;
            final SystemUiOverlayStyle systemBars = SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: palette.background,
              systemNavigationBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
            );
            // Applied imperatively so the very first frame is already right,
            // *and* declared as a region below.
            SystemChrome.setSystemUIOverlayStyle(systemBars);

            // The declaration is what lets a screen opt out and hand the bars
            // back. Flutter hit-tests the top and bottom of the layer tree for
            // one of these on every frame, so the full-screen viewer — which
            // is black in both themes and wants light icons over a black nav
            // bar — can put its own region on top and have this one resume the
            // moment it closes. With only the imperative call, the viewer's
            // style would survive it: after looking at one screenshot in light
            // mode the status bar icons stayed white on paper, invisible.
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: systemBars,
              child: MaterialApp.router(
                routerConfig: AppRouter.router,
                debugShowCheckedModeBanner: false,
                // One answer to "what happens at the end of a list", for every
                // list in the app. See [AppScrollBehavior].
                scrollBehavior: const AppScrollBehavior(),
                // Null means "follow the phone", which Flutter resolves against
                // supportedLocales on its own.
                locale: locales.locale,
                supportedLocales: AppLanguage.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: AppTheme.light(language),
                darkTheme: AppTheme.dark(language),
                themeMode: themeMode,
                // The single most important line for how switching themes
                // *feels*. Material cross-fades ThemeData over 200ms by
                // default, but every hand-built widget in this app reads
                // AppColors, which flips instantly. The result was 200ms of
                // half-light, half-dark UI — which is exactly the "tiring"
                // flicker, and it comes from the two halves disagreeing, not
                // from the switch being too fast. Zero makes the whole screen
                // change in one atomic frame.
                themeAnimationDuration: Duration.zero,
              ),
            );
          },
        );
      },
    );
  }
}
