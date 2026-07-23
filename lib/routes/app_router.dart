import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/about/about_screen.dart';
import '../features/analytics/analytics_command_center.dart';
import '../features/auth/login_screen.dart';
import '../features/compare/comparison_studio_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/home_screen.dart';
import '../features/live_race/live_race_screen.dart';
import '../features/replay/replay_studio_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/shell/coming_soon_screen.dart';
import '../features/standings/standings_screen.dart';
import '../features/telemetry/telemetry_screen.dart';
import '../providers/auth_providers.dart';

/// Pokes GoRouter's redirect whenever auth state or guest mode changes.
class _RouterNotifier extends ChangeNotifier {
  void poke() => notifyListeners();
}

/// Central GoRouter, exposed as a provider so redirects can react to auth.
///
/// A [ShellRoute] keeps [AppShell] (the nav chrome) mounted while the inner
/// page swaps; /login and /register live outside the shell. When Firebase is
/// not configured, no redirects fire and the app behaves exactly as before.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier();
  ref.onDispose(notifier.dispose);
  ref.listen(authStateChangesProvider, (_, __) => notifier.poke());
  ref.listen(guestModeProvider, (_, __) => notifier.poke());

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final firebaseReady = ref.read(firebaseReadyProvider);
      final onAuthPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // No Firebase config → auth layer is disabled entirely.
      if (!firebaseReady) return onAuthPage ? '/' : null;

      final auth = ref.read(authStateChangesProvider);
      if (auth.isLoading && !auth.hasValue) return null; // still resolving
      final signedIn = auth.valueOrNull != null;
      final guest = ref.read(guestModeProvider);

      if (!signedIn && !guest && !onAuthPage) return '/login';
      if ((signedIn || guest) && onAuthPage) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (c, s) => _fade(s, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (c, s) => _fade(s, const RegisterScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (c, s) => _fade(s, const HomeScreen()),
          ),
          GoRoute(
            path: '/live',
            pageBuilder: (c, s) => _fade(s, const LiveRaceScreen()),
          ),
          GoRoute(
            path: '/standings',
            pageBuilder: (c, s) => _fade(s, const StandingsScreen()),
          ),
          GoRoute(
            path: '/drivers',
            pageBuilder: (c, s) => _fade(
              s,
              const ComingSoonScreen(
                title: 'Drivers',
                icon: Icons.person_rounded,
                description:
                    'Driver cards with headshot, nationality, number, team, '
                    'points, wins, podiums and fastest laps — with animated '
                    'ranking changes.',
                planned: [
                  'Grid of driver cards sourced from OpenF1 + Jolpica',
                  'Per-driver detail page with season form',
                  'Animated ranking transitions on data refresh',
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/teams',
            pageBuilder: (c, s) => _fade(
              s,
              const ComingSoonScreen(
                title: 'Teams',
                icon: Icons.shield_rounded,
                description:
                    'Constructor cards: logo, points, wins, podiums, poles, '
                    'average pit stop and a performance graph.',
                planned: [
                  'Constructor standings cards',
                  'Average pit-stop analysis from OpenF1 /pit',
                  'Season performance spline chart',
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (c, s) => _fade(
              s,
              const ComingSoonScreen(
                title: 'Calendar',
                icon: Icons.calendar_today_rounded,
                description:
                    'Upcoming races with track image, countdown, country, '
                    'weather and full session schedule, plus circuit details.',
                planned: [
                  'Season schedule from Jolpica /races',
                  'Live countdown to next session',
                  'Circuit detail pages (map, length, DRS zones, lap record)',
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/telemetry',
            pageBuilder: (c, s) => _fade(s, const TelemetryScreen()),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (c, s) => _fade(s, const AnalyticsCommandCenter()),
          ),
          GoRoute(
            path: '/replay',
            pageBuilder: (c, s) => _fade(s, const ReplayStudioScreen()),
          ),
          GoRoute(
            path: '/compare',
            pageBuilder: (c, s) => _fade(s, const ComparisonStudioScreen()),
          ),
          GoRoute(
            path: '/about',
            pageBuilder: (c, s) => _fade(s, const AboutScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (c, s) => _fade(s, const SettingsScreen()),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});

/// Shared fade-through transition for a cinematic feel between pages.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondary, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}
