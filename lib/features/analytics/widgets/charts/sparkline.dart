import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A compact sparkline for trends (e.g. a driver's last-5 finishing positions).
/// No axes or labels — just the shape of the trend, with an optional filled
/// area and an accent dot on the latest point. Animates its draw on build.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    this.color = AppColors.accent,
    this.height = 34,
    this.width = 96,
    this.fill = true,
    this.invert = false,
  });

  final List<double> values;
  final Color color;
  final double height;
  final double width;
  final bool fill;

  /// When true, smaller values plot higher (useful for positions, where P1 is
  /// best and should sit at the top).
  final bool invert;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return SizedBox(width: width, height: height);
    }
    return SizedBox(
      width: width,
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => CustomPaint(
          painter: _SparkPainter(
            values: values,
            color: color,
            fill: fill,
            invert: invert,
            progress: t,
          ),
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.values,
    required this.color,
    required this.fill,
    required this.invert,
    required this.progress,
  });

  final List<double> values;
  final Color color;
  final bool fill;
  final bool invert;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    var min = values.first;
    var max = values.first;
    for (final v in values) {
      if (v < min) min = v;
      if (v > max) max = v;
    }
    final span = (max - min).abs() < 1e-9 ? 1.0 : (max - min);
    final dx = size.width / (values.length - 1);

    Offset pointAt(int i) {
      final norm = (values[i] - min) / span; // 0..1
      final y = invert ? norm * size.height : (1 - norm) * size.height;
      return Offset(i * dx, y.clamp(0.0, size.height).toDouble());
    }

    final count = (values.length * progress).ceil().clamp(2, values.length);
    final path = Path()..moveTo(0, pointAt(0).dy);
    for (var i = 1; i < count; i++) {
      final p = pointAt(i);
      path.lineTo(p.dx, p.dy);
    }

    if (fill) {
      final last = pointAt(count - 1);
      final area = Path.from(path)
        ..lineTo(last.dx, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.0)],
          ).createShader(Offset.zero & size),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    final tip = pointAt(count - 1);
    canvas.drawCircle(tip, 2.6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.values != values;
}
