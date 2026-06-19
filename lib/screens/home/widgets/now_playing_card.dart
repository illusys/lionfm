import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../providers/audio_provider.dart';
import '../../../../providers/schedule_provider.dart';
import 'waveform_widget.dart';

class NowPlayingCard extends ConsumerWidget {
  const NowPlayingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamStatus = ref.watch(streamStatusProvider);
    final currentShow = ref.watch(currentShowProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final player = ref.watch(audioPlayerProvider);

    return streamStatus.when(
      data: (status) => _buildCard(context, ref, status, currentShow, isPlaying, player),
      loading: () => const _CardSkeleton(),
      error: (_, __) => const _CardSkeleton(),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, dynamic status,
      dynamic currentShow, bool isPlaying, dynamic player) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.p16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.r20),
        gradient: AppColors.liveGradient,
        border: Border.all(color: AppColors.borderGreen, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.r20),
        child: Stack(
          children: [
            // Green glow top-right
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  gradient: AppColors.greenGlow,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Teal glow bottom-left
            Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  gradient: AppColors.tealGlow,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.p20),
              child: Column(
                children: [
                  // Top row: LIVE badge + station name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _LiveBadge(),
                      Text(
                        'LION FM 91.1',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.lionGold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.p16),

                  // Show artwork
                  currentShow.when(
                    data: (show) => _ShowArtwork(showTitle: show?.title ?? 'Lion FM'),
                    loading: () => const _ShowArtwork(showTitle: 'Lion FM'),
                    error: (_, __) => const _ShowArtwork(showTitle: 'Lion FM'),
                  ),
                  const SizedBox(height: AppDimensions.p12),

                  // Show title + host
                  currentShow.when(
                    data: (show) => Column(
                      children: [
                        Text(
                          show?.title ?? 'Lion FM 91.1 MHz',
                          style: AppTextStyles.h2,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          show?.hostName ?? 'Live Campus Radio',
                          style: AppTextStyles.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    loading: () => Text('Loading...', style: AppTextStyles.body),
                    error: (_, __) => Text('Lion FM', style: AppTextStyles.h2),
                  ),
                  const SizedBox(height: AppDimensions.p16),

                  // Waveform
                  WaveformWidget(isPlaying: isPlaying),
                  const SizedBox(height: AppDimensions.p16),

                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: AppColors.textMuted),
                        onPressed: () {},
                      ),
                      _PulsingPlayButton(
                        isPlaying: isPlaying,
                        onTap: () => isPlaying ? player.pause() : player.play(),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share_rounded, color: AppColors.textMuted, size: 20),
                            onPressed: () => Share.share('Listening to Lion FM 91.1 MHz — https://lionfm.vercel.app'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textMuted, size: 20),
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Show alerts enabled!')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.p8),

                  // Live indicator bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: const LinearProgressIndicator(
                            value: null,
                            backgroundColor: AppColors.bg3,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.lionGreen),
                            minHeight: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.liveRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('LIVE', style: AppTextStyles.liveLabel),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.liveRed.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppDimensions.rFull),
        border: Border.all(color: AppColors.liveRed.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _opacity,
            builder: (_, __) => Opacity(
              opacity: _opacity.value,
              child: Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(color: AppColors.liveRed, shape: BoxShape.circle),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text('LIVE', style: AppTextStyles.liveLabel),
        ],
      ),
    );
  }
}

class _ShowArtwork extends StatelessWidget {
  final String showTitle;
  const _ShowArtwork({required this.showTitle});

  @override
  Widget build(BuildContext context) {
    final initials = showTitle.split(' ').take(2).map((w) => w.isEmpty ? '' : w[0]).join().toUpperCase();
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.r16),
        gradient: AppColors.greenTealGradient,
        boxShadow: [BoxShadow(color: AppColors.lionGreen.withOpacity(0.35), blurRadius: 20, spreadRadius: 2)],
      ),
      alignment: Alignment.center,
      child: Text(initials, style: AppTextStyles.h1.copyWith(fontSize: 36, color: AppColors.bg0)),
    );
  }
}

class _PulsingPlayButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  const _PulsingPlayButton({required this.isPlaying, required this.onTap});

  @override
  State<_PulsingPlayButton> createState() => _PulsingPlayButtonState();
}

class _PulsingPlayButtonState extends State<_PulsingPlayButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.04).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: widget.isPlaying ? _scale.value : 1.0,
          child: child,
        ),
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            gradient: AppColors.greenTealGradient,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: AppColors.bg0,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.p16),
      height: 320,
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r20),
      ),
    );
  }
}
