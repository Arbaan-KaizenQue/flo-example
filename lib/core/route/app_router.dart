import 'package:go_router/go_router.dart';

import '../../view/screens/cycle_log/cycle_log_form_page.dart';
import '../../view/screens/dashboard/dashboard_page.dart';
import '../../view/screens/onboarding/onboarding_page.dart';
import '../../view/screens/privacy/privacy_page.dart';
import '../../view/screens/profile/profile_page.dart';
import '../../view/screens/settings/settings_page.dart';
import '../../view/screens/shell/main_shell.dart';
import '../../view/screens/splash/splash_page.dart';
import 'routes.dart';

/// [appRouter] — application-wide GoRouter config.
/// Every new screen MUST be paired with a constant in [routes.dart].
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      name: splashRoute,
      path: '/',
      builder: (_, __) => const SplashPage(),
    ),
    GoRoute(
      name: privacyRoute,
      path: '/privacy',
      builder: (_, __) => const PrivacyPage(),
    ),
    GoRoute(
      name: onboardingRoute,
      path: '/onboarding',
      builder: (_, __) => const OnboardingPage(),
    ),
    GoRoute(
      name: cycleLogFormRoute,
      path: '/cycle-log',
      builder: (_, state) {
        final raw = state.uri.queryParameters['date'];
        final seed = raw == null ? null : DateTime.tryParse(raw);
        return CycleLogFormPage(seedDate: seed);
      },
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          name: dashboardRoute,
          path: '/dashboard',
          pageBuilder: (_, state) =>
              const NoTransitionPage(child: DashboardPage()),
        ),
        GoRoute(
          name: settingsRoute,
          path: '/settings',
          pageBuilder: (_, state) =>
              const NoTransitionPage(child: SettingsPage()),
        ),
        GoRoute(
          name: profileRoute,
          path: '/profile',
          pageBuilder: (_, state) =>
              const NoTransitionPage(child: ProfilePage()),
        ),
      ],
    ),
  ],
);
