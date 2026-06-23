import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {

  late final AnimationController _logoCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _ringCtrl;
  late final AnimationController _taglineCtrl;
  late final AnimationController _eqCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _floatY;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _eqOpacity;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.2, end: 1.08)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 60),
      TweenSequenceItem(
          tween: Tween(begin: 1.08, end: 0.96)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: 0.96, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 20),
    ]).animate(_logoCtrl);
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _logoCtrl, curve: const Interval(0.0, 0.4)));

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000));
    _floatY = Tween<double>(begin: 0.0, end: -10.0).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400));

    _taglineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut));

    _eqCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _eqOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(_eqCtrl);

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _ringCtrl.repeat();
    _floatCtrl.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _taglineCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _eqCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    context.go('/');
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _floatCtrl.dispose();
    _ringCtrl.dispose();
    _taglineCtrl.dispose();
    _eqCtrl.dispose();
    super.dispose();
  }

  List<Widget> _buildNotes() {
    return [
      _buildNote('♪', left: 40, top: 120, color: AppColors.bg0.withValues(alpha: 0.6), delay: 0.0),
      _buildNote('♫', right: 60, top: 100, color: AppColors.bg0.withValues(alpha: 0.5), delay: 0.3),
      _buildNote('♩', right: 40, bottom: 160, color: AppColors.bg0.withValues(alpha: 0.7), delay: 0.6),
      _buildNote('♬', left: 50, bottom: 140, color: AppColors.bg0.withValues(alpha: 0.5), delay: 0.9),
    ];
  }

  Widget _buildNote(String note, {
    double? left, double? right, double? top, double? bottom,
    required Color color, required double delay,
  }) {
    return Positioned(
      left: left, right: right, top: top, bottom: bottom,
      child: AnimatedBuilder(
        animation: _ringCtrl,
        builder: (_, __) {
          final progress = (_ringCtrl.value + delay) % 1.0;
          final opacity = progress < 0.2
              ? progress / 0.2
              : progress < 0.6
                  ? 1.0
                  : (1.0 - progress) / 0.4;
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -progress * 50),
              child: Text(note,
                  style: TextStyle(fontSize: 20, color: color)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEqualizer() {
    final bars = [
      (AppColors.bg0.withValues(alpha: 0.7), 8.0, 0.0),
      (AppColors.bg0.withValues(alpha: 0.5), 16.0, 0.1),
      (AppColors.bg0.withValues(alpha: 0.7), 12.0, 0.2),
      (AppColors.bg0.withValues(alpha: 0.6), 20.0, 0.3),
      (AppColors.bg0.withValues(alpha: 0.7), 10.0, 0.4),
      (AppColors.bg0.withValues(alpha: 0.5), 18.0, 0.15),
      (AppColors.bg0.withValues(alpha: 0.7), 14.0, 0.25),
      (AppColors.bg0.withValues(alpha: 0.6), 8.0, 0.35),
      (AppColors.bg0.withValues(alpha: 0.5), 20.0, 0.05),
    ];
    return FadeTransition(
      opacity: _eqOpacity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((bar) {
          return AnimatedBuilder(
            animation: _eqCtrl,
            builder: (_, __) {
              final scaleY = 0.3 + ((_eqCtrl.value + bar.$3) % 1.0) * 1.1;
              return Container(
                width: 3,
                height: bar.$2 * scaleY,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: bar.$1,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient amber glow at center
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.7,
                colors: [
                  Color(0x30000000),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Pulse rings
          Center(
            child: AnimatedBuilder(
              animation: _ringCtrl,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  ...[0.0, 0.33, 0.66].asMap().entries.map((e) {
                    final colors = [
                      AppColors.bg0,
                      AppColors.bg1,
                      AppColors.bg0,
                    ];
                    final progress = (_ringCtrl.value + e.key * 0.33) % 1.0;
                    final scale = 1.0 + progress * 2.2;
                    final opacity = (1.0 - progress).clamp(0.0, 0.8);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors[e.key].withValues(alpha: opacity),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          // Music notes
          Stack(children: _buildNotes()),
          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                AnimatedBuilder(
                  animation: Listenable.merge([_logoCtrl, _floatCtrl]),
                  builder: (_, __) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0, _floatCtrl.isAnimating ? _floatY.value : 0),
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Image.asset(
                          'assets/images/lion_fm_logo.webp',
                          width: 300,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Tagline
                FadeTransition(
                  opacity: _taglineOpacity,
                  child: Text(
                    '...Your interactive radio',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      letterSpacing: 2.0,
                      color: AppColors.bg0.withValues(alpha: 0.75),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Equalizer
                _buildEqualizer(),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
