import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// Tweens between values when [value] changes, giving the "counting up" feel
/// the brief asks for on points/stats. Honours tabular figures so digits don't
/// jitter horizontally.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.fractionDigits = 0,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 700),
  });

  final num value;
  final TextStyle? style;
  final int fractionDigits;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        '${v.toStringAsFixed(fractionDigits)}$suffix',
        style: style ?? AppTextStyles.numeric,
      ),
    );
  }
}
