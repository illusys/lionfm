import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../models/station.dart';
import '../../../providers/current_station_provider.dart';
import '../../../providers/schedule_provider.dart';
import '../../../providers/station_provider.dart';

// ─── Slide models ─────────────────────────────────────────────────────────────

sealed class _Slide {}

class _NewsSlide extends _Slide {
  final String title;
  final String? imageUrl;
  final String id;
  _NewsSlide({required this.title, this.imageUrl, required this.id});
}

class _EventSlide extends _Slide {
  final String title;
  final String? imageUrl;
  final bool isLive;
  _EventSlide({required this.title, this.imageUrl, required this.isLive});
}

class _ShowSlide extends _Slide {
  final String title;
  final String hostName;
  final String? imageUrl;
  _ShowSlide({required this.title, required this.hostName, this.imageUrl});
}

class _WelcomeSlide extends _Slide {}

// ─── FeatureCarousel ──────────────────────────────────────────────────────────

class FeatureCarousel extends ConsumerStatefulWidget {
  const FeatureCarousel({super.key});

  @override
  ConsumerState<FeatureCarousel> createState() => _FeatureCarouselState();
}

class _FeatureCarouselState extends ConsumerState<FeatureCarousel> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;
  List<_Slide> _slides = [_WelcomeSlide()];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSlides();
  }

  Future<void> _loadSlides() async {
    final slides = <_Slide>[];

    // 1. Current show from provider
    try {
      final show = ref.read(currentShowProvider).valueOrNull;
      if (show != null) {
        slides.add(_ShowSlide(
          title: show.title,
          hostName: show.hostName,
          imageUrl: show.imageUrl,
        ));
      }
    } catch (_) {}

    // 2. Latest news from Firestore
    try {
      final stationId = ref.read(currentStationIdProvider) ?? 'lion';
      final snap = await FirebaseFirestore.instance
          .collection('news')
          .where('stationId', isEqualTo: stationId)
          .orderBy('publishedAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        slides.add(_NewsSlide(
          title: doc.data()['title'] as String? ?? 'Campus News',
          imageUrl: doc.data()['imageUrl'] as String?,
          id: doc.id,
        ));
      }
    } catch (_) {}

    // 3. Live event or upcoming event from Firestore
    try {
      final stationId = ref.read(currentStationIdProvider) ?? 'lion';
      QuerySnapshot<Map<String, dynamic>> eventSnap = await FirebaseFirestore
          .instance
          .collection('events')
          .where('stationId', isEqualTo: stationId)
          .where('isLive', isEqualTo: true)
          .limit(1)
          .get();
      bool isLive = true;
      if (eventSnap.docs.isEmpty) {
        eventSnap = await FirebaseFirestore.instance
            .collection('events')
            .where('stationId', isEqualTo: stationId)
            .orderBy('startTime')
            .limit(1)
            .get();
        isLive = false;
      }
      if (eventSnap.docs.isNotEmpty) {
        final doc = eventSnap.docs.first;
        slides.add(_EventSlide(
          title: doc.data()['title'] as String? ?? 'Upcoming Event',
          imageUrl: doc.data()['imageUrl'] as String? ??
              doc.data()['posterUrl'] as String?,
          isLive: isLive,
        ));
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _slides = slides.isEmpty ? [_WelcomeSlide()] : slides;
      _loaded = true;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_slides.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.electricTeal,
            ),
          ),
        ),
      );
    }

    final stationId = ref.watch(currentStationIdProvider);
    final station = stationId != null
        ? ref.watch(stationProvider(stationId)).valueOrNull
        : null;

    return SizedBox(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (ctx, i) => _SlideView(
                slide: _slides[i],
                station: station,
                onTap: () => _handleTap(ctx, _slides[i]),
              ),
            ),
          ),
          if (_slides.length > 1) ...[
            const SizedBox(height: 8),
            _DotIndicator(count: _slides.length, current: _currentPage),
          ],
        ],
      ),
    );
  }

  void _handleTap(BuildContext ctx, _Slide slide) {
    if (slide is _NewsSlide) ctx.go('/news');
    if (slide is _EventSlide) ctx.go('/events');
    if (slide is _ShowSlide) ctx.go('/schedule');
  }
}

// ─── Slide view ───────────────────────────────────────────────────────────────

class _SlideView extends StatelessWidget {
  final _Slide slide;
  final VoidCallback onTap;
  final Station? station;

  const _SlideView({required this.slide, required this.onTap, this.station});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (slide is _WelcomeSlide) return _buildWelcomeSlide();
    if (slide is _NewsSlide) return _buildNewsSlide(slide as _NewsSlide);
    if (slide is _EventSlide) return _buildEventSlide(slide as _EventSlide);
    if (slide is _ShowSlide) return _buildShowSlide(slide as _ShowSlide);
    return _buildWelcomeSlide();
  }

  Widget _buildWelcomeSlide() {
    final name = (station?.name.isNotEmpty == true) ? station!.name : 'Your Station';
    final tagline = (station?.tagline.isNotEmpty == true) ? station!.tagline : 'Live Radio Streaming';
    final logoUrl = station?.logoUrl ?? '';

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (logoUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  logoUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _stationInitial(name),
                ),
              )
            else
              _stationInitial(name),
            const SizedBox(height: 12),
            Text(
              'Welcome to $name',
              style: AppTextStyles.h3.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              tagline,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white70,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stationInitial(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildNewsSlide(_NewsSlide s) {
    return _ImageSlide(
      imageUrl: s.imageUrl,
      badge: '● NEWS',
      badgeColor: AppColors.electricTeal,
      title: s.title,
      subtitle: 'Campus News · Tap to read',
    );
  }

  Widget _buildEventSlide(_EventSlide s) {
    return _ImageSlide(
      imageUrl: s.imageUrl,
      badge: s.isLive ? '● LIVE EVENT' : '● UPCOMING',
      badgeColor: s.isLive ? AppColors.liveRed : AppColors.lionGold,
      title: s.title,
      subtitle:
          s.isLive ? 'Happening now · Tap to join' : 'Coming soon · Tap to see',
    );
  }

  Widget _buildShowSlide(_ShowSlide s) {
    return _ImageSlide(
      imageUrl: s.imageUrl,
      badge: '● ON AIR',
      badgeColor: AppColors.lionGreen,
      title: s.title,
      subtitle: 'Hosted by ${s.hostName} · Tap to view schedule',
    );
  }
}

// ─── Image-based slide ────────────────────────────────────────────────────────

class _ImageSlide extends StatelessWidget {
  final String? imageUrl;
  final String badge;
  final Color badgeColor;
  final String title;
  final String subtitle;

  const _ImageSlide({
    required this.imageUrl,
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        if (imageUrl != null && imageUrl!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              decoration:
                  const BoxDecoration(gradient: AppColors.heroGradient),
            ),
          )
        else
          Container(
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
            child: const Center(
              child: Icon(Icons.radio_rounded, size: 64, color: Colors.white24),
            ),
          ),
        // Dark gradient overlay (bottom 40%)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.4, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
        ),
        // Content overlay
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: AppTextStyles.label.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: AppTextStyles.h3.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Dot indicator ────────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _DotIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: isActive ? 20 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isActive ? AppColors.electricTeal : AppColors.textMuted,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
