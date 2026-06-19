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
import '../../screens/auth/login_screen.dart';
import '../../screens/admin/admin_shell.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/schedule_manager_screen.dart';
import '../../screens/admin/stream_monitor_screen.dart';
import '../../screens/admin/notification_sender_screen.dart';
import '../../screens/admin/request_queue_screen.dart';
import '../../screens/admin/podcast_manager_screen.dart';
import '../../screens/admin/ad_manager_screen.dart';
import '../../screens/admin/analytics_screen.dart';
import '../../screens/admin/revenue_dashboard_screen.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/common/mini_player_bar.dart';
import '../../widgets/common/offline_banner.dart';
import 'nav_destinations.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => const NoTransitionPage(child: LoginScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child, state: state);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/schedule',
            pageBuilder: (context, state) => const NoTransitionPage(child: ScheduleScreen()),
          ),
          GoRoute(
            path: '/podcasts',
            pageBuilder: (context, state) => const NoTransitionPage(child: PodcastsScreen()),
          ),
          GoRoute(
            path: '/news',
            pageBuilder: (context, state) => const NoTransitionPage(child: NewsScreen()),
          ),
          GoRoute(
            path: '/requests',
            pageBuilder: (context, state) => const NoTransitionPage(child: RequestsScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
      // Admin routes — wrapped in AdminShell
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) => const NoTransitionPage(child: AdminDashboardScreen()),
          ),
          GoRoute(
            path: '/admin/schedule',
            pageBuilder: (context, state) => const NoTransitionPage(child: ScheduleManagerScreen()),
          ),
          GoRoute(
            path: '/admin/stream',
            pageBuilder: (context, state) => const NoTransitionPage(child: StreamMonitorScreen()),
          ),
          GoRoute(
            path: '/admin/notifications',
            pageBuilder: (context, state) => const NoTransitionPage(child: NotificationSenderScreen()),
          ),
          GoRoute(
            path: '/admin/requests',
            pageBuilder: (context, state) => const NoTransitionPage(child: RequestQueueScreen()),
          ),
          GoRoute(
            path: '/admin/podcasts',
            pageBuilder: (context, state) => const NoTransitionPage(child: PodcastManagerScreen()),
          ),
          GoRoute(
            path: '/admin/ads',
            pageBuilder: (context, state) => const NoTransitionPage(child: AdManagerScreen()),
          ),
          GoRoute(
            path: '/admin/analytics',
            pageBuilder: (context, state) => const NoTransitionPage(child: AnalyticsScreen()),
          ),
          GoRoute(
            path: '/admin/revenue',
            pageBuilder: (context, state) => const NoTransitionPage(child: RevenueDashboardScreen()),
          ),
        ],
      ),
    ],
  );
});

class AppShell extends ConsumerWidget {
  final Widget child;
  final GoRouterState state;

  const AppShell({super.key, required this.child, required this.state});

  int _routeIndex(String location) {
    if (location.startsWith('/schedule')) return 1;
    if (location.startsWith('/podcasts')) return 2;
    if (location.startsWith('/news')) return 3;
    if (location.startsWith('/requests')) return 4;
    return 0;
  }

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
