import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/audio_provider.dart';
import '../../providers/events_provider.dart';
import '../../widgets/ads/direct_banner_widget.dart';
import 'widgets/latest_podcasts_widget.dart';
import 'widgets/now_playing_card.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/upcoming_shows_list.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.appBackground,
        body: RefreshIndicator(
          onRefresh: () async => ref.refresh(streamStatusProvider),
          color: AppColors.amberGold,
          backgroundColor: AppColors.surface2,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: NowPlayingCard()),
              const SliverToBoxAdapter(child: QuickActionsGrid()),
              const SliverToBoxAdapter(
                child: DirectBannerWidget(placement: 'home_mid'),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.p16,
                    vertical: AppDimensions.p4,
                  ),
                  child: Divider(color: AppColors.border1),
                ),
              ),
              // Live Events section
              const SliverToBoxAdapter(child: _LiveEventsSection()),
              const SliverToBoxAdapter(child: LatestPodcastsWidget()),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.p16,
                    vertical: AppDimensions.p4,
                  ),
                  child: Divider(color: AppColors.border1),
                ),
              ),
              const SliverToBoxAdapter(child: UpcomingShowsList()),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.p32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Live Events section for home screen ──────────────────────────────────────

class _LiveEventsSection extends ConsumerWidget {
  const _LiveEventsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingEventsProvider);

    return upcomingAsync.when(
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.p16, AppDimensions.p16,
                  AppDimensions.p16, AppDimensions.p8),
              child: Row(
                children: [
                  Text('LIVE EVENTS', style: AppTextStyles.label),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.go('/events'),
                    child: Text('See all',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.electricTeal)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.p16),
                itemCount: events.length,
                itemBuilder: (_, i) =>
                    _EventChip(event: events[i]),
              ),
            ),
            const SizedBox(height: AppDimensions.p8),
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.p16,
                vertical: AppDimensions.p4,
              ),
              child: Divider(color: AppColors.border1),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _EventChip extends StatelessWidget {
  final dynamic event;
  const _EventChip({required this.event});

  @override
  Widget build(BuildContext context) {
    final isLive = event.isLive as bool;
    final title = event.title as String;
    final startTime = event.startTime as DateTime;
    final isFree = event.isFree as bool;
    final priceNGN = event.ticketPriceNGN as int;

    return GestureDetector(
      onTap: () => context.go('/events'),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: AppDimensions.p12),
        padding: const EdgeInsets.all(AppDimensions.p12),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(AppDimensions.r12),
          border: Border.all(
            color: isLive
                ? AppColors.liveRed.withValues(alpha: 0.5)
                : AppColors.border1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: AppColors.liveRed,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.rFull),
                ),
                child: const Text('● LIVE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ),
            Text(title,
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const Spacer(),
            Text(
              DateFormat('MMM d · h:mm a').format(startTime),
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 4),
            Text(
              isFree
                  ? 'Free'
                  : '₦${NumberFormat('#,###').format(priceNGN)}',
              style: AppTextStyles.caption.copyWith(
                  color: isFree
                      ? AppColors.successGreen
                      : AppColors.lionGold),
            ),
          ],
        ),
      ),
    );
  }
}
