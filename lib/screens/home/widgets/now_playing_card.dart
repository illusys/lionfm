import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/current_station_provider.dart';
import '../../../providers/schedule_provider.dart';
import '../../../providers/station_provider.dart';
import 'live_player_widget.dart';

class NowPlayingCard extends ConsumerWidget {
  const NowPlayingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentShowAsync = ref.watch(currentShowProvider);
    final stationId = ref.watch(currentStationIdProvider) ?? 'lion';
    final stationAsync = ref.watch(stationProvider(stationId));
    final station = stationAsync.valueOrNull;
    final show = currentShowAsync.valueOrNull;

    final stationName = station?.name ?? '';
    final logoUrl = station?.logoUrl ?? '';
    final showTitle =
        show?.title ?? (stationName.isNotEmpty ? stationName : 'On Air');
    final hostLine =
        show?.hostName ?? (station?.tagline ?? '');

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.liveGradient),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: LIVE dot + ON AIR text | LIVE badge
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.liveRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  stationName.isNotEmpty
                      ? 'ON AIR NOW · $stationName'
                      : 'ON AIR NOW',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.liveRed,
                    letterSpacing: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.liveRed,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'LIVE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Show title alongside station logo
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  showTitle,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              _StationLogo(logoUrl: logoUrl, name: stationName),
            ],
          ),
          const SizedBox(height: 6),
          // Host name or station tagline
          if (hostLine.isNotEmpty)
            Text(
              hostLine,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          // Player controls (waveform is rendered inside LivePlayerWidget)
          const LivePlayerWidget(),
        ],
      ),
    );
  }
}

// ── Station logo: network image or initial-letter placeholder ─────────────────

class _StationLogo extends StatelessWidget {
  final String logoUrl;
  final String name;
  const _StationLogo({required this.logoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    if (logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          logoUrl,
          height: 64,
          width: 64,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _LogoPlaceholder(name: name),
        ),
      );
    }
    return _LogoPlaceholder(name: name);
  }
}

class _LogoPlaceholder extends StatelessWidget {
  final String name;
  const _LogoPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'FM';
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF15E0B4).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFF15E0B4).withValues(alpha: 0.4)),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF15E0B4),
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
