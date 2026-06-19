import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/user_provider.dart';

class AdMobBannerWidget extends ConsumerWidget {
  const AdMobBannerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) return const SizedBox.shrink();
    final user = ref.watch(userProvider);
    if (user.isPremium) return const SizedBox.shrink();

    return Container(
      height: 52,
      color: AppColors.bg1,
      alignment: Alignment.center,
      child: const Text('Ad', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
    );
  }
}
