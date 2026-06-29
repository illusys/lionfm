import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/news_provider.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/lion_fm_app_bar.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/ads/direct_banner_widget.dart';
import 'widgets/featured_story_card.dart';
import 'widgets/news_list_tile.dart';

const _newsCategories = [
  ('all', 'All'),
  ('campus', 'Campus'),
  ('academic', 'Academic'),
  ('sports', 'Sports'),
  ('events', 'Events'),
  ('health', 'Health'),
];

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredNewsProvider);
    final filtered = ref.watch(filteredNewsProvider);
    final category = ref.watch(newsCategoryProvider);

    return Scaffold(
      appBar: const LionFmAppBar(title: 'News'),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(newsItemsProvider),
        color: AppColors.amberGold,
        child: CustomScrollView(
          slivers: [
            // Category chips
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.p16, vertical: 8),
                  itemCount: _newsCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final (value, label) = _newsCategories[i];
                    final isSelected = category == value;
                    return GestureDetector(
                      onTap: () =>
                          ref.read(newsCategoryProvider.notifier).state = value,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.unnDeepBlue
                              : AppColors.surface2,
                          borderRadius: BorderRadius.circular(AppDimensions.rFull),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.electricBlue
                                : AppColors.border1,
                          ),
                        ),
                        child: Text(label,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: isSelected
                                  ? AppColors.pureWhite
                                  : AppColors.textSecondary,
                            )),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Featured card
            if (category == 'all')
              SliverToBoxAdapter(
                child: featured.when(
                  data: (item) =>
                      item != null ? FeaturedStoryCard(news: item) : const SizedBox.shrink(),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppDimensions.p16),
                    child: LoadingShimmer(height: 200),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            // Ad between featured and news list
            if (category == 'all')
              const SliverToBoxAdapter(
                child: DirectBannerWidget(placement: 'news_top'),
              ),
            // News list
            SliverToBoxAdapter(
              child: filtered.when(
                data: (items) {
                  final list = category == 'all'
                      ? items.where((n) => !n.isFeatured).toList()
                      : items;
                  return Column(
                    children: [
                      ...list.map((n) => NewsListTile(news: n)),
                      Padding(
                        padding: const EdgeInsets.all(AppDimensions.p16),
                        child: Text(
                          'Last updated · ${DateFormat('h:mm a').format(DateTime.now())}',
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => Column(
                  children: List.generate(
                      5,
                      (_) => const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: AppDimensions.p16,
                                vertical: AppDimensions.p8),
                            child: LoadingShimmer(height: 60),
                          )),
                ),
                error: (e, _) => ErrorStateWidget(
                  message: 'Could not load news',
                  onRetry: () => ref.refresh(newsItemsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
