import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/user_provider.dart';

final _admobConfigProvider = StreamProvider<bool>((ref) {
  return FirebaseFirestore.instance
      .collection('admin_config')
      .doc('admob')
      .snapshots()
      .map((s) => s.data()?['isEnabled'] as bool? ?? false);
});

class AdMobBannerWidget extends ConsumerWidget {
  const AdMobBannerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) return const SizedBox.shrink();
    final user = ref.watch(userProvider);
    if (user.isPremium) return const SizedBox.shrink();

    final isEnabled = ref.watch(_admobConfigProvider).valueOrNull ?? false;
    if (!isEnabled) return const SizedBox.shrink();

    return Container(
      height: 52,
      color: AppColors.bg1,
      alignment: Alignment.center,
      child: const Text('Ad', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
    );
  }
}
