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
import 'package:shoto/core/theme/app_tint.dart';
import 'package:shoto/core/theme/app_icon_controller.dart';
import 'package:shoto/core/theme/folder_appearance_controller.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/theme/tint_controller.dart';
import 'package:shoto/features/quick_save/presentation/pages/quick_save_page.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';
import 'firebase_options.dart';

/// The only orientation Shoto is ever drawn in, asked for as early as Dart
/// can ask.
///
/// **This is the Flutter layer of a three-layer lock, and on its own it is
/// not enough.** Nothing here runs until the engine has started, so the
/// window Android paints before that — and the whole of an iOS cold start —
/// is governed by `android:screenOrientation` in AndroidManifest.xml and
/// `UISupportedInterfaceOrientations` in Info.plist instead. All three say
/// `portraitUp` and nothing else; `portraitDown` is absent from all three,
/// because turning the app 180° is a rotation like any other.
///
/// **The result is awaited by [main], and that is the point of it being a
/// future at all.** This used to be a bare statement, and a bare statement is
/// a request rather than a lock: `setPreferredOrientations` posts a message to
/// the platform thread and returns immediately, so the first Flutter frame
/// could go up before Android had been told anything. Cold-start the app while
/// holding the phone sideways and you got a landscape frame that snapped
/// upright a moment later — a rotation flash at the one moment nobody is
/// looking away.
///
/// **A lock that could not be applied must never be a launch that did not
/// happen**, which is what the `catchError` is for. The failure it guards is
/// real and specific: Android 8.0 — and only 8.0 — refuses a fixed orientation
/// on a translucent activity, which the share sheet is. `ShareActivity`
/// swallows that natively so the call reports success, and this is the second
/// line of defence, because an error raised here lands before `runApp` and its
/// symptom is a black screen rather than a rotated one.
///
/// Public, and called by nothing but [main] — `test/orientation_lock_test.dart`
/// asserts what it sends, which a private closure inside `main` could not be
/// asked.
Future<void> lockOrientation() => SystemChrome.setPreferredOrientations(
  const [DeviceOrientation.portraitUp],
).catchError((Object _) {});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Started here and awaited below rather than on a line of its own, so it
  // overlaps the preference loads instead of queueing in front of them — see
  // [lockOrientation] for why it is awaited at all.
  final Future<void> orientationLocked = lockOrientation();

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
      orientationLocked,
      sl<LocalIdentity>().load(),
      sl<LocaleController>().load(),
      sl<ThemeController>().load(),
      // Alongside the theme mode and for the same reason: the sheet is drawn
      // in the app's own colours, and one that opened teal over an app the
      // user had made plum would read as a different product's UI — the exact
      // complaint that made this sheet follow the in-app theme rather than the
      // system's. One more read of an already-warm SharedPreferences.
      sl<TintController>().load(),
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
    orientationLocked,
    sl<LocalIdentity>().load(),
    sl<LocaleController>().load(),
    sl<ThemeController>().load(),
    sl<TintController>().load(),
    sl<GridDensityController>().load(),
    sl<FolderAppearanceController>().load(),
    // Reads the stored id, then asks the package manager what is really on
    // the launcher — see AppIconController, the one preference whose truth
    // lives outside this app.
    sl<AppIconController>().load(),
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
        // **Applied without consulting [ProStatus], on purpose.**
        //
        // This sheet deliberately never brings the subscription stack up — the
        // comment on the loads above explains why — so it cannot ask whether
        // the user still subscribes. It does not need to: the gate is on
        // *changing* the accent, not on having one. Someone who picked plum
        // and later lapsed keeps a plum app, which is the ordinary way a
        // subscription ends. See [TintController.isCustom].
        final AppTint tint = sl<TintController>().tint;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          scrollBehavior: const AppScrollBehavior(),
          locale: sl<LocaleController>().locale,
          supportedLocales: AppLanguage.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(language, tint: tint),
          darkTheme: AppTheme.dark(language, tint: tint),
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
            // The accent repaints the whole app exactly like the mode does, so
            // it belongs in the same merged listener rather than in a builder
            // of its own — see the note above about rebuilding twice for one
            // change.
            sl<TintController>(),
            sl<LocaleController>(),
            // Kept after dark mode stopped being a paid preference: the PRO
            // tags on the paid rows are read off this in more than one place
            // without a listener of their own, and they have to come down the
            // moment a subscription lands.
            sl<ProStatus>(),
          ]),
          builder: (context, _) {
            // **The mode the user chose, applied as chosen.**
            //
            // This used to be filtered through an `_effectiveThemeMode` that
            // downgraded an explicit dark choice to [ThemeMode.system] for
            // anybody without a subscription. The result was a control that
            // looked set to dark while the app rendered light, a share sheet
            // that disagreed with the app it was covering — the sheet never
            // loads [ProStatus], so it read every user as free — and a
            // preference the app quietly declined to honour. Charging for a
            // colour scheme was never worth any of that.
            final ThemeMode themeMode = sl<ThemeController>().themeMode;
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
            final AppTint tint = sl<TintController>().tint;
            // Tinted like the themes below, because the system navigation bar
            // is painted from `palette.background` — which no tint touches —
            // but reading the untinted palette here would be a second source
            // of truth waiting to disagree with the first the day a tint does
            // reach a surface.
            final AppPalette palette = AppPalette.tinted(
              tint,
              isDark: resolvedBrightness == Brightness.dark,
            );

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
                theme: AppTheme.light(language, tint: tint),
                darkTheme: AppTheme.dark(language, tint: tint),
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
