import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/schedule_provider.dart';
import 'waveform_widget.dart';
import 'live_player_widget.dart';

class NowPlayingCard extends ConsumerWidget {
  const NowPlayingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentShowAsync = ref.watch(currentShowProvider);
    final show = currentShowAsync.valueOrNull;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.liveGradient),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.liveRed, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('ON AIR NOW · LION FM 91.1 MHz', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.liveRed, letterSpacing: 1.0)),
              const Spacer(),
              Text('LION FM 91.1', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.lionGold, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 14),
          Text(show?.title ?? 'Lion FM 91.1 MHz', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(show?.hostName ?? 'Your Interactive Radio', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          const WaveformWidget(),
          const SizedBox(height: 4),
          const LivePlayerWidget(),
        ],
      ),
    );
  }
}
