import 'package:go_router/go_router.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:shoto/features/shell/presentation/pages/main_shell_page.dart';

abstract class AppRouter {
  static const String onboardingPage = 'onboarding';
  static const String homePage = 'home';

  /// Decided once, when the router is built, rather than left to a splash
  /// screen to send itself onward.
  ///
  /// Every load this depends on — the onboarding flag — finishes before
  /// `runApp`, so nothing sits between that data being ready and the real
  /// first screen appearing: the native launch window stays up until this
  /// screen's first frame, instead of handing off to a Flutter copy of itself.
  static String _initialLocation() =>
      sl<AppPreferences>().hasSeenOnboarding ? '/home' : '/onboarding';

  /// Two routes, no redirect, and no gate — see
  /// `docs/decisions/accounts.md` for the sign-in wall that used to be here.
  static final GoRouter router = GoRouter(
    initialLocation: _initialLocation(),
    routes: [
      GoRoute(
        path: '/onboarding',
        name: onboardingPage,
        // Not const — same reasoning as MainShellPage's IndexedStack: a
        // const page widget can get frozen by Flutter's reconciliation and
        // stop picking up theme (or other) changes after its first build.
        builder: (context, state) => OnboardingPage(),
      ),
      GoRoute(
        path: '/home',
        name: homePage,
        builder: (context, state) => MainShellPage(),
      ),
    ],
  );
}
