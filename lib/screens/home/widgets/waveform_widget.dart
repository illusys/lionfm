import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

class WaveformWidget extends StatefulWidget {
  final bool isPlaying;

  const WaveformWidget({super.key, this.isPlaying = true});

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _random = Random();
  late List<double> _phases;

  static const int _barCount = 52;

  @override
  void initState() {
    super.initState();
    _phases = List.generate(_barCount, (_) => _random.nextDouble() * 2 * pi);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: AppDimensions.waveformHeight,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            painter: _WaveformPainter(
              progress: _ctrl.value,
              phases: _phases,
              isPlaying: widget.isPlaying,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final List<double> phases;
  final bool isPlaying;

  _WaveformPainter({
    required this.progress,
    required this.phases,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 52;
    final barWidth = (size.width - (barCount - 1) * 2) / barCount;
    final maxH = size.height * 0.85;
    final minH = size.height * 0.06;

    for (int i = 0; i < barCount; i++) {
      double heightFactor;
      if (isPlaying) {
        heightFactor = (sin(progress * 2 * pi + phases[i]) + 1) / 2;
        heightFactor = minH / size.height + heightFactor * (1 - minH / size.height);
      } else {
        heightFactor = minH / size.height +
            (sin(phases[i]) + 1) / 2 * 0.15 * (1 - minH / size.height);
      }

      final barH = maxH * heightFactor;
      final x = i * (barWidth + 2);
      final y = (size.height - barH) / 2;

      final t = i / barCount;
      final color = Color.lerp(AppColors.amberGold, AppColors.electricBlue, t)!
          .withValues(alpha: isPlaying ? 0.85 : 0.35);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barH),
        const Radius.circular(2),
      );
      canvas.drawRRect(rr, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress || old.isPlaying != isPlaying;
}
