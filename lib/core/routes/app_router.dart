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

  static final AuthRepository _authRepository = sl<AuthRepository>();

  /// Decided once, when the router is built, rather than left to a splash
  /// screen to send itself onward.
  ///
  /// Every load this depends on — the onboarding flag — finishes before
  /// `runApp`, so nothing sits between that data being ready and the real
  /// first screen appearing: the native launch window stays up until this
  /// screen's first frame, instead of handing off to a Flutter copy of itself.
  static String _initialLocation() {
    final AppPreferences preferences = sl<AppPreferences>();
    if (preferences.hasSeenOnboarding) return '/home';

    // Backfill for everyone who was already using SHOTO when signing in was
    // still mandatory. Being signed in is proof the introduction was seen —
    // there was no other way to have got past it — and without this they
    // would be shown it again on the first launch after upgrading.
    if (_authRepository.currentUser != null) {
      preferences.markOnboardingSeen();
      return '/home';
    }

    return '/onboarding';
  }

  /// There is no redirect, and that is the point.
  ///
  /// `/home` used to be gated on a Firebase account: signed out meant bounced
  /// to `/auth`, on the first screen, before the app would show anything at
  /// all. It cost every new user a Google handoff to see an empty library,
  /// and it contradicted the one claim SHOTO is built on — nothing leaves
  /// your phone — for a uid that only ever scoped rows in a local sqlite
  /// file. The library belongs to the device now (see [LocalIdentity]), so
  /// there is nothing left for a gate to protect.
  ///
  /// `/auth` is still here and still works. It is reached deliberately, from
  /// Settings, by somebody who wants to carry a purchase to a second device —
  /// which is the only thing an account has ever actually bought them.
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
