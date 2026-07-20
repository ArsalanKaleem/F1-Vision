import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// An animated circular progress ring with a value in the centre. Reusable for
/// "% classified", "points share", win-rate, etc.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.fraction,
    required this.label,
    this.centerText,
    this.color = AppColors.accent,
    this.size = 92,
    this.stroke = 9,
  });

  final double fraction; // 0..1
  final String label;
  final String? centerText;
  final Color color;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final clamped = fraction.clamp(0.0, 1.0).toDouble();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: clamped),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return CustomPaint(
                painter: _RingPainter(value: value, color: color, stroke: stroke),
                child: Center(
                  child: Text(
                    centerText ?? '${(value * 100).round()}%',
                    style: AppTextStyles.numeric.copyWith(fontSize: size * 0.24),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: AppTextStyles.overline,
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.color, required this.stroke});
  final double value;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.surfaceHigh;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, track);

    if (value <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [color.withValues(alpha: 0.5), color],
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color || old.stroke != stroke;
}
