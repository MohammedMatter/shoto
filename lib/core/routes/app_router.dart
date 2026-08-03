import 'package:go_router/go_router.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/routes/go_router_refresh_stream.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';
import 'package:shoto/features/auth/presentation/pages/auth_page.dart';
import 'package:shoto/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:shoto/features/shell/presentation/pages/main_shell_page.dart';

abstract class AppRouter {
  static const String onboardingPage = 'onboarding';
  static const String authPage = 'auth';
  static const String homePage = 'home';

  static final AuthRepository _authRepository = sl<AuthRepository>();

  /// Decided once, when the router is built, rather than left to a splash
  /// screen to send itself onward.
  ///
  /// Every load this depends on — auth state, the onboarding flag — finishes
  /// before `runApp`, same as it always did. The only thing that changed is
  /// that nothing sits between that data being ready and the real first
  /// screen appearing: the native launch window now stays up until this
  /// screen's first frame, instead of handing off to a Flutter copy of itself.
  static String _initialLocation() {
    final bool signedIn = _authRepository.currentUser != null;
    final AppPreferences preferences = sl<AppPreferences>();
    final bool seenIntro = preferences.hasSeenOnboarding;

    // Backfill for everyone who was already using SHOTO before the flag
    // existed. Being signed in is proof the introduction was seen — there is
    // no other way to have got here — and without this they would be shown
    // it again the first time they signed out and reopened the app.
    if (signedIn && !seenIntro) preferences.markOnboardingSeen();

    if (signedIn) return '/home';
    return seenIntro ? '/auth' : '/onboarding';
  }

  static final GoRouter router = GoRouter(
    initialLocation: _initialLocation(),
    refreshListenable: GoRouterRefreshStream(
      stream: _authRepository.authStateChanges,
    ),
    redirect: (context, state) {
      final String location = state.matchedLocation;
      final bool isSignedIn = _authRepository.currentUser != null;

      final bool isPreAuthRoute =
          location == '/onboarding' || location == '/auth';
      if (isPreAuthRoute && isSignedIn) return '/home';

      // Sign-out lands on sign-in, not on the introduction.
      //
      // This used to send you to /onboarding, which was wrong twice over.
      // Someone signing out has plainly already seen what the app is for, so
      // showing them the pitch again is noise in the way of the one thing
      // they were doing. And it *raced*: Settings also pushes /auth when the
      // signed-out state arrives, so the two redirects fired together and you
      // saw a frame of onboarding before landing on sign-in. Both now name
      // the same destination, so there is nothing left to flash.
      if (location == '/home' && !isSignedIn) return '/auth';
      return null;
    },
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
        path: '/auth',
        name: authPage,
        builder: (context, state) => AuthPage(),
      ),
      GoRoute(
        path: '/home',
        name: homePage,
        builder: (context, state) => MainShellPage(),
      ),
    ],
  );
}
