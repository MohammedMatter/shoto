import 'package:go_router/go_router.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/routes/go_router_refresh_stream.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';
import 'package:shoto/features/auth/presentation/pages/auth_page.dart';
import 'package:shoto/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:shoto/features/shell/presentation/pages/main_shell_page.dart';

abstract class AppRouter {
  static const String onboardingPage = 'onboarding';
  static const String authPage = 'auth';
  static const String homePage = 'home';

  static final AuthRepository _authRepository = sl<AuthRepository>();

  static final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: GoRouterRefreshStream(_authRepository.authStateChanges),
    redirect: (context, state) {
      final bool isLoggedIn = _authRepository.currentUser != null;
      final String location = state.matchedLocation;
      final bool isPreAuthRoute = location == '/onboarding' || location == '/auth';

      if (isLoggedIn && isPreAuthRoute) return '/home';
      if (!isLoggedIn && location == '/home') return '/auth';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        name: onboardingPage,
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
