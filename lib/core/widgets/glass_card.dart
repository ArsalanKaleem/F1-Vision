import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A frosted, softly-shadowed surface — the visual backbone of the app.
///
/// [glow] adds a subtle red ambient glow for hero/accent cards. [onTap] enables
/// hover/press feedback on desktop and mobile alike.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 20,
    this.glow = false,
    this.gradient,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool glow;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
      decoration: BoxDecoration(
        gradient: widget.gradient ?? AppColors.heroGradient,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: _hovered
              ? AppColors.accent.withValues(alpha: 0.35)
              : AppColors.surfaceStroke,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          if (widget.glow)
            BoxShadow(
              color: AppColors.accent.withValues(alpha: _hovered ? 0.30 : 0.18),
              blurRadius: 40,
              spreadRadius: -8,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );

    if (widget.onTap == null) return card;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(onTap: widget.onTap, child: card),
    );
  }
}
