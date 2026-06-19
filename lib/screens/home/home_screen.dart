import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../providers/audio_provider.dart';
import '../../widgets/ads/direct_banner_widget.dart';
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
