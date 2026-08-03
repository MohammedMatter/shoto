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
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/app_theme.dart';
import 'package:shoto/core/theme/grid_density_controller.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/features/quick_save/presentation/pages/quick_save_page.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Sharing an image into SHOTO starts a different Android activity, which
  // asks Flutter to begin on "/share". Branching here rather than inside the
  // router keeps the share sheet completely outside the app's navigation —
  // it is a self-contained screen, not a page of SHOTO.
  //
  // Decided *first* because it also decides how much has to finish loading
  // before anything can be drawn.
  final bool isShareSheet =
      PlatformDispatcher.instance.defaultRouteName == '/share';

  // Every registration is lazy, so this constructs nothing — safe to run
  // before Firebase is ready, and it lets the work below start in parallel.
  setupServiceLocator();

  // Started, not awaited. Firebase is the single slowest step here and none
  // of the preference loads depend on it, so they overlap instead of queuing
  // behind it.
  final Future<void> firebaseReady = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (isShareSheet) {
    // The share sheet was taking over two seconds to appear from a cold
    // start, and a noticeable part of that was this function loading things
    // the sheet never looks at: grid density (it has no grid), developer
    // access and the subscription repository (quick save is free, so nothing
    // in the sheet is gated).
    //
    // Waiting for them was pure delay in front of the one screen where delay
    // is least acceptable — the user is mid-gesture in another app, and a
    // sheet that arrives late has already lost the point of not opening the
    // app at all.
    //
    // These three are genuinely needed before the first frame: the language
    // and theme decide how it is drawn, and haptics fire on the first tap.
    await Future.wait([
      firebaseReady,
      sl<LocaleController>().load(),
      sl<ThemeController>().load(),
      sl<AppPreferences>().load(),
    ]);
    runApp(QuickSaveApp());
    return;
  }

  await Future.wait([
    firebaseReady,
    sl<LocaleController>().load(),
    sl<ThemeController>().load(),
    sl<GridDensityController>().load(),
    sl<AppPreferences>().load(),
    // Before the subscription repository is asked anything — every premium
    // gate reads its answer from there, and it consults this.
    sl<DevAccess>().load(),
  ]);

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

  runApp(MyApp());
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
        AppTextStyles.setLanguage(sl<LocaleController>().effectiveLanguage);

        // Follows the theme the user picked *inside SHOTO*, not the system's.
        // Reading platform brightness here made the sheet appear dark over a
        // light app whenever the two disagreed, which reads as a different
        // app's UI rather than SHOTO's.
        final ThemeMode themeMode = sl<ThemeController>().themeMode;
        final Brightness resolvedBrightness = switch (themeMode) {
          ThemeMode.light => Brightness.light,
          ThemeMode.dark => Brightness.dark,
          ThemeMode.system => MediaQuery.platformBrightnessOf(context),
        };
        AppColors.setBrightness(resolvedBrightness);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: sl<LocaleController>().locale,
          supportedLocales: AppLanguage.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          themeAnimationDuration: Duration.zero,
          home: QuickSavePage(),
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
          ]),
          builder: (context, _) {
            final ThemeMode themeMode = sl<ThemeController>().themeMode;
            final LocaleController locales = sl<LocaleController>();

            // Same contract as AppColors.setBrightness below — set before
            // the subtree is built, because the type scale is read
            // synchronously during this frame.
            AppTextStyles.setLanguage(locales.effectiveLanguage);
            final Brightness resolvedBrightness = switch (themeMode) {
              ThemeMode.light => Brightness.light,
              ThemeMode.dark => Brightness.dark,
              ThemeMode.system => MediaQuery.platformBrightnessOf(context),
            };
            // Must happen before MaterialApp.router builds its subtree —
            // every custom widget below reads AppColors synchronously
            // during this same frame. See app_colors.dart for why.
            AppColors.setBrightness(resolvedBrightness);

            final bool isDark = resolvedBrightness == Brightness.dark;
            final SystemUiOverlayStyle systemBars = SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: AppColors.background,
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
                // Null means "follow the phone", which Flutter resolves against
                // supportedLocales on its own.
                locale: locales.locale,
                supportedLocales: AppLanguage.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
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
