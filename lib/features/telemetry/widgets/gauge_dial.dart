import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// An animated 270° gauge used for speed and RPM. The value arc and needle
/// tween smoothly to each new reading, and an optional redline zone highlights
/// the top of the range (e.g. the rev limiter).
class GaugeDial extends StatelessWidget {
  const GaugeDial({
    super.key,
    required this.value,
    required this.max,
    required this.label,
    this.unit = '',
    this.color = AppColors.accent,
    this.redlineFraction,
    this.fractionDigits = 0,
  });

  final double value;
  final double max;
  final String label;
  final String unit;
  final Color color;

  /// Where the redline zone begins, as a fraction of [max] (0–1). Null hides it.
  final double? redlineFraction;
  final int fractionDigits;

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0, max).toDouble();
    return AspectRatio(
      aspectRatio: 1,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: target),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) {
          return CustomPaint(
            painter: _GaugePainter(
              value: animated,
              max: max,
              color: color,
              redlineFraction: redlineFraction,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    animated.toStringAsFixed(fractionDigits),
                    style: AppTextStyles.numeric.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unit.isEmpty ? label : '$label · $unit',
                    style: AppTextStyles.overline,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.max,
    required this.color,
    this.redlineFraction,
  });

  final double value;
  final double max;
  final Color color;
  final double? redlineFraction;

  // Sweep geometry: start bottom-left, sweep 270° clockwise to bottom-right.
  static const double _startAngle = math.pi * 0.75;
  static const double _sweepAngle = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = size.shortestSide * 0.075;
    final radius = (size.shortestSide - stroke) / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final fraction = (max <= 0 ? 0.0 : value / max).clamp(0.0, 1.0);

    // Track.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.surfaceHigh;
    canvas.drawArc(rect, _startAngle, _sweepAngle, false, track);

    // Redline zone.
    if (redlineFraction != null) {
      final rf = redlineFraction!.clamp(0.0, 1.0);
      final redline = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = AppColors.accent.withValues(alpha: 0.30);
      canvas.drawArc(
        rect,
        _startAngle + _sweepAngle * rf,
        _sweepAngle * (1 - rf),
        false,
        redline,
      );
    }

    // Value arc with a subtle gradient sweep.
    final inRedline =
        redlineFraction != null && fraction >= redlineFraction!.clamp(0.0, 1.0);
    final arcColor = inRedline ? AppColors.accent : color;
    final valuePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: _startAngle,
        endAngle: _startAngle + _sweepAngle,
        colors: [arcColor.withValues(alpha: 0.55), arcColor],
      ).createShader(rect);
    canvas.drawArc(rect, _startAngle, _sweepAngle * fraction, false, valuePaint);

    // Needle.
    final needleAngle = _startAngle + _sweepAngle * fraction;
    final needleLen = radius - stroke * 0.2;
    final needleEnd = Offset(
      center.dx + needleLen * math.cos(needleAngle),
      center.dy + needleLen * math.sin(needleAngle),
    );
    final needle = Paint()
      ..color = arcColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needle);
    canvas.drawCircle(
      center,
      stroke * 0.45,
      Paint()..color = AppColors.surfaceStroke,
    );
    canvas.drawCircle(
      center,
      stroke * 0.22,
      Paint()..color = arcColor,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value ||
      old.max != max ||
      old.color != color ||
      old.redlineFraction != redlineFraction;
}
