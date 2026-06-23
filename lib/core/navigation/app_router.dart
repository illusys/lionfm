import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/schedule/schedule_screen.dart';
import '../../screens/podcasts/podcasts_screen.dart';
import '../../screens/news/news_screen.dart';
import '../../screens/requests/requests_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/admin/admin_shell.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/admin_login_screen.dart';
import '../../screens/admin/accept_invite_screen.dart';
import '../../screens/admin/first_time_setup_screen.dart';
import '../../screens/admin/user_management_screen.dart';
import '../../screens/admin/admin_settings_screen.dart';
import '../../screens/admin/schedule_manager_screen.dart';
import '../../screens/admin/stream_monitor_screen.dart';
import '../../screens/admin/notification_sender_screen.dart';
import '../../screens/admin/request_queue_screen.dart';
import '../../screens/admin/podcast_manager_screen.dart';
import '../../screens/admin/ad_manager_screen.dart';
import '../../screens/admin/analytics_screen.dart';
import '../../screens/admin/revenue_dashboard_screen.dart';
import '../../screens/admin/events_manager_screen.dart';
import '../../screens/events/events_screen.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/common/mini_player_bar.dart';
import '../../widgets/common/offline_banner.dart';
import '../../providers/admin_auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Listen to auth changes so the router refreshes on sign-in/out
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    // Catch any path that has no matching route — redirect to safe fallback
    // rather than exposing the raw black GoRouter error screen.
    errorBuilder: (context, state) => _GoRouterErrorPage(state: state),
    redirect: (context, state) {
      final adminAsync = ref.read(adminUserProvider);
      final needsSetup = ref.read(needsFirstTimeSetupProvider);
      final loc = state.matchedLocation;

      // While stream is loading, don't redirect — let it settle
      if (adminAsync.isLoading) return null;

      final adminUser = adminAsync.valueOrNull;

      // Only treat paths that are exactly '/admin' or start with '/admin/'
      // as admin routes. This prevents '/admin-login', '/admin-setup',
      // '/admin-accept-invite', and invalid slugs like '/admin-online'
      // from being classified as protected admin routes.
      final isAdminRoute =
          loc == '/admin' || loc.startsWith('/admin/');
      final isLoginRoute = loc == '/admin-login';
      final isSetupRoute = loc == '/admin-setup';
      final isAcceptRoute = loc == '/admin-accept-invite';

      // If signed in but needs first-time setup, send to setup
      if (isAdminRoute && !isSetupRoute && needsSetup) {
        return '/admin-setup';
      }

      // Protect all /admin/* routes (except login, setup, and accept-invite)
      if (isAdminRoute && !isLoginRoute && !isSetupRoute && !isAcceptRoute) {
        if (adminUser == null || !adminUser.isActive) return '/admin-login';

        // Role-gated routes
        if (loc == '/admin/revenue' && !adminUser.canManageRevenue) {
          return '/admin';
        }
        if (loc == '/admin/users' && !adminUser.canManageUsers) {
          return '/admin';
        }
        if (loc == '/admin/settings' && !adminUser.isSuperAdmin) {
          return '/admin';
        }
      }

      // If already signed in as active admin, skip the login screen
      if (isLoginRoute && adminUser != null && adminUser.isActive) {
        return '/admin';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: OnboardingScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginScreen()),
      ),
      // Admin login — outside shells, no guard needed
      GoRoute(
        path: '/admin-login',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AdminLoginScreen()),
      ),
      // First-time superAdmin setup
      GoRoute(
        path: '/admin-setup',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: FirstTimeSetupScreen()),
      ),
      // Accept email invite — no auth guard
      GoRoute(
        path: '/admin-accept-invite',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return NoTransitionPage(child: AcceptInviteScreen(email: email));
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child, state: state);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/schedule',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ScheduleScreen()),
          ),
          GoRoute(
            path: '/podcasts',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PodcastsScreen()),
          ),
          GoRoute(
            path: '/news',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NewsScreen()),
          ),
          GoRoute(
            path: '/requests',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: RequestsScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
          GoRoute(
            path: '/events',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: EventsScreen()),
          ),
        ],
      ),
      // Admin routes — wrapped in AdminShell, protected by redirect above
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AdminDashboardScreen()),
          ),
          GoRoute(
            path: '/admin/schedule',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ScheduleManagerScreen()),
          ),
          GoRoute(
            path: '/admin/stream',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: StreamMonitorScreen()),
          ),
          GoRoute(
            path: '/admin/notifications',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NotificationSenderScreen()),
          ),
          GoRoute(
            path: '/admin/requests',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: RequestQueueScreen()),
          ),
          GoRoute(
            path: '/admin/podcasts',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PodcastManagerScreen()),
          ),
          GoRoute(
            path: '/admin/ads',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AdManagerScreen()),
          ),
          GoRoute(
            path: '/admin/analytics',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AnalyticsScreen()),
          ),
          GoRoute(
            path: '/admin/revenue',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: RevenueDashboardScreen()),
          ),
          GoRoute(
            path: '/admin/users',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: UserManagementScreen()),
          ),
          GoRoute(
            path: '/admin/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AdminSettingsScreen()),
          ),
          GoRoute(
            path: '/admin/events',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: EventsManagerScreen()),
          ),
        ],
      ),
    ],
  );
});

// Notifier that triggers router refresh when admin auth state changes
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<AdminUser?>>(
      adminUserProvider,
      (_, __) => notifyListeners(),
    );
    _ref.listen<bool>(needsFirstTimeSetupProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

// Redirects any unmatched path to a safe fallback instead of showing a
// raw error screen. Admin paths go back to /admin, everything else to /.
class _GoRouterErrorPage extends StatefulWidget {
  final GoRouterState state;
  const _GoRouterErrorPage({required this.state});

  @override
  State<_GoRouterErrorPage> createState() => _GoRouterErrorPageState();
}

class _GoRouterErrorPageState extends State<_GoRouterErrorPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final loc = widget.state.uri.toString();
      context.go(loc.startsWith('/admin') ? '/admin' : '/');
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator()),
      );
}

class AppShell extends ConsumerWidget {
  final Widget child;
  final GoRouterState state;

  const AppShell({super.key, required this.child, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = state.uri.toString();
    final isHome = location == '/';

    return Scaffold(
      body: OfflineBanner(
        child: Column(
          children: [
            Expanded(child: child),
            if (!isHome) const MiniPlayerBar(),
            const AppBottomNavBar(),
          ],
        ),
      ),
    );
  }
}
