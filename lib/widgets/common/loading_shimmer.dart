import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = AppDimensions.r8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface3,
      highlightColor: AppColors.surface4,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface3,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class EpisodeCardShimmer extends StatelessWidget {
  const EpisodeCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.p16, vertical: AppDimensions.p8),
      child: Row(
        children: [
          LoadingShimmer(
            width: AppDimensions.thumbnailEpisode,
            height: AppDimensions.thumbnailEpisode,
            radius: AppDimensions.r10,
          ),
          const SizedBox(width: AppDimensions.p12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingShimmer(height: 12, width: 100),
                SizedBox(height: 6),
                LoadingShimmer(height: 14),
                SizedBox(height: 4),
                LoadingShimmer(height: 11, width: 140),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
