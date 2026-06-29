import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Listener screens ─────────────────────────────────────────────────────────
import '../../screens/home/home_screen.dart';
import '../../screens/schedule/schedule_screen.dart';
import '../../screens/podcasts/podcasts_screen.dart';
import '../../screens/news/news_screen.dart';
import '../../screens/requests/requests_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/events/events_screen.dart';

// ── Admin shell ───────────────────────────────────────────────────────────────
import '../../screens/admin/admin_shell.dart';

// ── Platform shell ────────────────────────────────────────────────────────────
import '../../screens/platform/platform_shell.dart';
import '../../screens/platform/platform_dashboard_screen.dart';
import '../../screens/platform/platform_stations_screen.dart';
import '../../screens/platform/platform_ads_screen.dart';
import '../../screens/platform/platform_revenue_screen.dart';
import '../../screens/platform/platform_settings_screen.dart';
import '../../screens/platform/platform_station_detail_screen.dart';
import '../../screens/platform/platform_billing_screen.dart';
import '../../screens/platform/platform_onboarding_screen.dart';
import '../../screens/platform/platform_onboard_detail_screen.dart';
import '../../screens/onboarding/station_onboard_screen.dart';

// ── Admin auth screens ────────────────────────────────────────────────────────
import '../../screens/admin/admin_login_screen.dart';
import '../../screens/admin/first_time_setup_screen.dart';
import '../../screens/admin/accept_invite_screen.dart';

// ── Admin content screens ─────────────────────────────────────────────────────
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/schedule_manager_screen.dart';
import '../../screens/admin/stream_monitor_screen.dart';
import '../../screens/admin/notification_sender_screen.dart';
import '../../screens/admin/request_queue_screen.dart';
import '../../screens/admin/podcast_manager_screen.dart';
import '../../screens/admin/ad_manager_screen.dart';
import '../../screens/admin/events_manager_screen.dart';
import '../../screens/admin/admin_chat_screen.dart';
import '../../screens/admin/analytics_screen.dart';
import '../../screens/admin/news_manager_screen.dart';
import '../../screens/admin/revenue_dashboard_screen.dart';
import '../../screens/admin/user_management_screen.dart';
import '../../screens/admin/admin_settings_screen.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/common/mini_player_bar.dart';
import '../../widgets/common/offline_banner.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/current_station_provider.dart';
import '../../screens/onboarding/get_started_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    errorBuilder: (context, state) => _GoRouterErrorPage(state: state),
    redirect: (context, state) {
      final stationId = ref.read(currentStationIdProvider);
      final adminAsync = ref.read(adminUserProvider);
      final needsSetup = ref.read(needsFirstTimeSetupProvider);
      final loc = state.matchedLocation;

      // Platform level (app.fmstream.online) — only allow specific routes
      if (stationId == null) {
        const allowed = [
          '/get-started',
          '/onboard',
          '/admin-login',
          '/platform',
          '/admin-accept-invite',
        ];
        final isAllowed = allowed.any((r) => loc.startsWith(r));
        if (!isAllowed) return '/get-started';
      }

      if (adminAsync.isLoading) return null;

      final adminUser = adminAsync.valueOrNull;
      final isAdminRoute = loc == '/admin' || loc.startsWith('/admin/');
      final isPlatformRoute = loc == '/platform' || loc.startsWith('/platform/');
      final isLoginRoute = loc == '/admin-login';
      final isSetupRoute = loc == '/admin-setup';
      final isAcceptRoute = loc == '/admin-accept-invite';

      // Platform routes — platform owner only
      if (isPlatformRoute) {
        if (adminUser == null || !adminUser.isActive) return '/admin-login';
        if (!adminUser.isPlatformOwner) return '/admin';
      }

      if (isAdminRoute && !isSetupRoute && needsSetup) return '/admin-setup';

      if (isAdminRoute && !isLoginRoute && !isSetupRoute && !isAcceptRoute) {
        if (adminUser == null || !adminUser.isActive) return '/admin-login';
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

      if (isLoginRoute && adminUser != null && adminUser.isActive) {
        // Platform owners land on the platform dashboard
        return adminUser.isPlatformOwner ? '/platform' : '/admin';
      }

      return null;
    },
    routes: [
      // ── Platform onboarding (app.fmstream.online only) ─────────────────
      GoRoute(
        path: '/get-started',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: GetStartedScreen()),
      ),

      // ── Public / listener routes ────────────────────────────────────────
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

      // ── Public station onboarding form ──────────────────────────────────
      GoRoute(
        path: '/onboard',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: StationOnboardScreen()),
      ),

      // ── Admin auth routes ────────────────────────────────────────────────
      GoRoute(
        path: '/admin-login',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AdminLoginScreen()),
      ),
      GoRoute(
        path: '/admin-setup',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: FirstTimeSetupScreen()),
      ),
      GoRoute(
        path: '/admin-accept-invite',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return NoTransitionPage(
            child: AcceptInviteScreen(email: email),
          );
        },
      ),

      // ── Listener shell (bottom nav) ─────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(child: child, state: state),
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
            path: '/chat',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ChatScreen()),
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

      // ── Admin shell (sidebar nav) ────────────────────────────────────────
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
            path: '/admin/events',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: EventsManagerScreen()),
          ),
          GoRoute(
            path: '/admin/chat',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AdminChatScreen()),
          ),
          GoRoute(
            path: '/admin/news',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NewsManagerScreen()),
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
        ],
      ),

      // ── Platform shell (iLLuSys platform owner) ──────────────────────────
      ShellRoute(
        builder: (context, state, child) => PlatformShell(child: child),
        routes: [
          GoRoute(
            path: '/platform',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PlatformDashboardScreen()),
          ),
          GoRoute(
            path: '/platform/stations',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PlatformStationsScreen()),
          ),
          GoRoute(
            path: '/platform/ads',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PlatformAdsScreen()),
          ),
          GoRoute(
            path: '/platform/revenue',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PlatformRevenueScreen()),
          ),
          GoRoute(
            path: '/platform/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PlatformSettingsScreen()),
          ),
          GoRoute(
            path: '/platform/station/:id',
            pageBuilder: (context, state) => NoTransitionPage(
              child: PlatformStationDetailScreen(
                stationId: state.pathParameters['id']!,
              ),
            ),
          ),
          GoRoute(
            path: '/platform/station/:id/billing',
            pageBuilder: (context, state) => NoTransitionPage(
              child: PlatformBillingScreen(
                stationId: state.pathParameters['id']!,
              ),
            ),
          ),
          GoRoute(
            path: '/platform/onboarding',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PlatformOnboardingScreen()),
          ),
          GoRoute(
            path: '/platform/onboarding/:id',
            pageBuilder: (context, state) => NoTransitionPage(
              child: PlatformOnboardDetailScreen(
                onboardingId: state.pathParameters['id']!,
              ),
            ),
          ),
        ],
      ),
    ],
  );
});

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<AdminUser?>>(
      adminUserProvider,
      (_, __) => notifyListeners(),
    );
    _ref.listen<bool>(
        needsFirstTimeSetupProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

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
