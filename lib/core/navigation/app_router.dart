// ══════════════════════════════════════════════════════════════════════════════
// BUNDLE-SPLIT STRATEGY
// ══════════════════════════════════════════════════════════════════════════════
// Listener screens stay in the main bundle (critical render path).
// Every admin screen is a deferred import so dart2js places its code — and any
// admin-only transitive packages (fl_chart, pdf, csv, file_picker, etc.) — in
// separate JS chunks that browsers only download when a user navigates there.
//
// AdminShell is intentionally non-deferred: GoRouter's ShellRoute.builder is
// synchronous, so the shell layout must be available at compile time. The shell
// itself is lightweight (sidebar icons + navigation only).
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Listener screens (eager — critical render path) ─────────────────────────
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

// ── Admin shell (eager — synchronous ShellRoute.builder requirement) ─────────
import '../../screens/admin/admin_shell.dart';

// ── Admin auth screens (deferred — accessed only when opening admin) ─────────
import '../../screens/admin/admin_login_screen.dart' deferred as adminLogin;
import '../../screens/admin/first_time_setup_screen.dart'
    deferred as adminSetup;
import '../../screens/admin/accept_invite_screen.dart'
    deferred as acceptInvite;

// ── Admin content screens (deferred — these pull in fl_chart, pdf, csv, etc.)─
import '../../screens/admin/admin_dashboard_screen.dart'
    deferred as adminDashboard;
import '../../screens/admin/schedule_manager_screen.dart'
    deferred as scheduleMgr;
import '../../screens/admin/stream_monitor_screen.dart'
    deferred as streamMonitor;
import '../../screens/admin/notification_sender_screen.dart'
    deferred as notifySender;
import '../../screens/admin/request_queue_screen.dart'
    deferred as requestQueue;
import '../../screens/admin/podcast_manager_screen.dart'
    deferred as podcastMgr;
import '../../screens/admin/ad_manager_screen.dart' deferred as adMgr;
import '../../screens/admin/events_manager_screen.dart' deferred as eventsMgr;
import '../../screens/admin/admin_chat_screen.dart' deferred as adminChat;
// fl_chart + pdf/printing only in these two — deferring them removes those
// packages from the main bundle entirely.
import '../../screens/admin/analytics_screen.dart' deferred as analyticsScreen;
import '../../screens/admin/revenue_dashboard_screen.dart'
    deferred as revenueScreen;
// SuperAdmin-only screens
import '../../screens/admin/user_management_screen.dart' deferred as userMgmt;
import '../../screens/admin/admin_settings_screen.dart'
    deferred as adminSettings;

// ── Helpers ──────────────────────────────────────────────────────────────────
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/common/mini_player_bar.dart';
import '../../widgets/common/offline_banner.dart';
import '../../widgets/common/deferred_widget.dart';
import '../../providers/admin_auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    errorBuilder: (context, state) => _GoRouterErrorPage(state: state),
    redirect: (context, state) {
      final adminAsync = ref.read(adminUserProvider);
      final needsSetup = ref.read(needsFirstTimeSetupProvider);
      final loc = state.matchedLocation;

      if (adminAsync.isLoading) return null;

      final adminUser = adminAsync.valueOrNull;
      final isAdminRoute = loc == '/admin' || loc.startsWith('/admin/');
      final isLoginRoute = loc == '/admin-login';
      final isSetupRoute = loc == '/admin-setup';
      final isAcceptRoute = loc == '/admin-accept-invite';

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
        return '/admin';
      }

      return null;
    },
    routes: [
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

      // ── Admin auth routes (deferred chunks) ─────────────────────────────
      GoRoute(
        path: '/admin-login',
        pageBuilder: (context, state) => NoTransitionPage(
          child: DeferredWidget(
            loader: () => adminLogin.loadLibrary(),
            builder: (_) => adminLogin.AdminLoginScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/admin-setup',
        pageBuilder: (context, state) => NoTransitionPage(
          child: DeferredWidget(
            loader: () => adminSetup.loadLibrary(),
            builder: (_) => adminSetup.FirstTimeSetupScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/admin-accept-invite',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return NoTransitionPage(
            child: DeferredWidget(
              loader: () => acceptInvite.loadLibrary(),
              builder: (_) => acceptInvite.AcceptInviteScreen(email: email),
            ),
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

      // ── Admin shell (sidebar nav) — screens are all deferred ────────────
      ShellRoute(
        // AdminShell itself is non-deferred so GoRouter can call this
        // synchronously. The heavy widgets are inside the child routes.
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) => NoTransitionPage(
              child: DeferredWidget(
                loader: () => adminDashboard.loadLibrary(),
                builder: (_) => adminDashboard.AdminDashboardScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/admin/schedule',
            pageBuilder: (context, state) => NoTransitionPage(
              child: DeferredWidget(
                loader: () => scheduleMgr.loadLibrary(),
                builder: (_) => scheduleMgr.ScheduleManagerScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/admin/stream',
            pageBuilder: (context, state) => NoTransitionPage(
              child: DeferredWidget(
                loader: () => streamMonitor.loadLibrary(),
                builder: (_) => streamMonitor.StreamMonitorScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/admin/notifications',
            pageBuilder: (context, state) => NoTransitionPage(
              child: DeferredWidget(
                loader: () => notifySender.loadLibrary(),
                builder: (_) => notifySender.NotificationSenderScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/admin/requests',
            pageBuilder: (context, state) => NoTransitionPage(
              child: DeferredWidget(
                loader: () => requestQueue.loadLibrary(),
                builder: (_) => requestQueue.RequestQueueScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/admin/podcasts',
            pageBuilder: (context, state) => NoTransitionPage(
              child: DeferredWidget(
                loader: () => podcastMgr.loadLibrary(),
                builder: (_) => podcastMgr.PodcastManagerScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/admin/ads',
            pageBuilder: (context, state) => NoTransitionPage(
              child: DeferredWidget(
                loader: () => adMgr.loadLibrary(),
                builder: (_) => adMgr.AdManagerScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/admin/events',
            pageBuilder: (context, state) => NoTransitionPage(
              child: DeferredWidget(
                loader: () => eventsMgr.loadLibrary(),
                builder: (_) => eventsMgr.EventsManagerScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/admin/chat',
            pageBuilder: (context, state) => NoTransitionPage(
              child: DeferredWidget(
                loader: () => adminChat.loadLibrary(),
                builder: (_) => adminChat.AdminChatScreen(),
              ),
            ),
          ),
          // fl_chart and pdf/printing are ONLY reachable through these two
          // routes — deferring them removes those packages from the main bundle.
          GoRoute(
            path: '/admin/analytics',
            pageBuilder: (context, state) => NoTransitionPage(
              child: DeferredWidget(
                loader: () => analyticsScreen.loadLibrary(),
                builder: (_) => analyticsScreen.AnalyticsScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/admin/revenue',
            pageBuilder: (context, state) => NoTransitionPage(
              child: DeferredWidget(
                loader: () => revenueScreen.loadLibrary(),
                builder: (_) => revenueScreen.RevenueDashboardScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/admin/users',
            pageBuilder: (context, state) => NoTransitionPage(
              child: DeferredWidget(
                loader: () => userMgmt.loadLibrary(),
                builder: (_) => userMgmt.UserManagementScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/admin/settings',
            pageBuilder: (context, state) => NoTransitionPage(
              child: DeferredWidget(
                loader: () => adminSettings.loadLibrary(),
                builder: (_) => adminSettings.AdminSettingsScreen(),
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
