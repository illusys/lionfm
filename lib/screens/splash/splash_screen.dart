import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _noteCtrl;
  late AnimationController _taglineCtrl;
  late AnimationController _eqCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;
  late Animation<double> _floatY;
  late Animation<double> _glowOpacity;
  late Animation<double> _noteOpacity;
  late Animation<double> _taglineOpacity;

  final List<Animation<double>> _eqHeights = [];

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _noteCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _taglineCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _eqCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..repeat(reverse: true);

    _logoScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 30),
    ]).animate(_logoCtrl);
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.5)));

    _ringScale = Tween(begin: 0.6, end: 2.2).animate(
        CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));
    _ringOpacity = Tween(begin: 0.6, end: 0.0).animate(
        CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));

    _floatY = Tween(begin: 0.0, end: -8.0).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _glowOpacity = Tween(begin: 0.3, end: 0.7).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _noteOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _noteCtrl, curve: const Interval(0, 0.3)));
    _taglineOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut));

    final rng = Random();
    for (int i = 0; i < 9; i++) {
      final min = 0.2 + rng.nextDouble() * 0.3;
      final max = 0.6 + rng.nextDouble() * 0.4;
      _eqHeights.add(Tween(begin: min, end: max).animate(
          CurvedAnimation(parent: _eqCtrl, curve: Interval(i / 9, (i + 1) / 9, curve: Curves.easeInOut))));
    }

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _ringCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _taglineCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    context.go('/');
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _ringCtrl.dispose();
    _floatCtrl.dispose();
    _glowCtrl.dispose();
    _noteCtrl.dispose();
    _taglineCtrl.dispose();
    _eqCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background glow
          AnimatedBuilder(
            animation: _glowOpacity,
            builder: (_, __) => Opacity(
              opacity: _glowOpacity.value,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.lionGreen.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Pulse rings
          AnimatedBuilder(
            animation: _ringCtrl,
            builder: (_, __) => Opacity(
              opacity: _ringOpacity.value,
              child: Container(
                width: 200 * _ringScale.value,
                height: 200 * _ringScale.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.lionGreen.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          // Floating music notes
          ..._buildNotes(),
          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo with float
              AnimatedBuilder(
                animation: Listenable.merge([_logoCtrl, _floatCtrl]),
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _floatY.value),
                  child: Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: _LogoWidget(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Tagline
              AnimatedBuilder(
                animation: _taglineCtrl,
                builder: (_, __) => Opacity(
                  opacity: _taglineOpacity.value,
                  child: Text(
                    '...Your interactive radio',
                    style: AppTextStyles.tagline.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Equalizer bars
              AnimatedBuilder(
                animation: _eqCtrl,
                builder: (_, __) => _buildEqualizer(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNotes() {
    final positions = [
      const Offset(-120, -80),
      const Offset(110, -60),
      const Offset(-90, 100),
      const Offset(130, 90),
    ];
    final icons = [Icons.music_note, Icons.music_note, Icons.queue_music, Icons.music_note];
    return List.generate(4, (i) {
      return AnimatedBuilder(
        animation: _noteCtrl,
        builder: (_, __) {
          final t = (_noteCtrl.value + i * 0.25) % 1.0;
          final opacity = t < 0.3 ? t / 0.3 : t > 0.7 ? (1.0 - t) / 0.3 : 1.0;
          return Positioned(
            left: MediaQuery.of(context).size.width / 2 + positions[i].dx,
            top: MediaQuery.of(context).size.height / 2 + positions[i].dy - t * 30,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0) * 0.6,
              child: Icon(icons[i], color: AppColors.electricTeal, size: 18),
            ),
          );
        },
      );
    });
  }

  Widget _buildEqualizer() {
    final colors = [
      AppColors.lionGreen,
      AppColors.lionGreen,
      AppColors.electricTeal,
      AppColors.electricTeal,
      AppColors.lionGold,
      AppColors.electricTeal,
      AppColors.electricTeal,
      AppColors.lionGreen,
      AppColors.lionGreen,
    ];
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(9, (i) {
          final h = _eqHeights.length > i ? _eqHeights[i].value : 0.5;
          return Container(
            width: 4,
            height: 32 * h,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: colors[i],
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        gradient: AppColors.greenTealGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.lionGreen.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'LION',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.bg0,
              letterSpacing: 3,
              fontSize: 16,
            ),
          ),
          Text(
            'FM',
            style: AppTextStyles.heroTitle.copyWith(
              color: AppColors.bg0,
              fontSize: 40,
              height: 1,
            ),
          ),
          Text(
            '91.1 MHz',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.bg0.withOpacity(0.7),
              letterSpacing: 1,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
