import 'package:go_router/go_router.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';
import 'package:shoto/features/auth/presentation/pages/auth_page.dart';
import 'package:shoto/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:shoto/features/shell/presentation/pages/main_shell_page.dart';

abstract class AppRouter {
  static const String onboardingPage = 'onboarding';
  static const String authPage = 'auth';
  static const String homePage = 'home';

  static AuthRepository get _auth => sl<AuthRepository>();

  /// Decided once, when the router is built, rather than left to a splash
  /// screen to send itself onward.
  ///
  /// The order is introduction, then account, then the app. Somebody who has
  /// already signed in skips both and lands on Home, which is every launch
  /// after the first.
  static String _initialLocation() {
    final AppPreferences preferences = sl<AppPreferences>();
    if (_auth.currentUser != null) {
      // Being signed in is proof the introduction was seen — there was no
      // other way past it — so it is not shown again after an upgrade.
      if (!preferences.hasSeenOnboarding) preferences.markOnboardingSeen();
      return '/home';
    }

    return preferences.hasSeenOnboarding ? '/auth' : '/onboarding';
  }

  static final GoRouter router = GoRouter(
    initialLocation: _initialLocation(),
    routes: [
      GoRoute(
        path: '/onboarding',
        name: onboardingPage,
        // These three were deliberately *not* const for most of the app's
        // life: a const page widget is identical on every rebuild, so
        // Flutter's reconciliation skipped its subtree and it stopped picking
        // up theme changes after its first build. That was a symptom of the
        // palette being a mutable global, and it is fixed at the source — the
        // palette is an InheritedWidget now, and a dependent of one is rebuilt
        // whether or not it is const. See app_colors.dart.
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/auth',
        name: authPage,
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/home',
        name: homePage,
        builder: (context, state) => const MainShellPage(),
      ),
    ],
  );
}
