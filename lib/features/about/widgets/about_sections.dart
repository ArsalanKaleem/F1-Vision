import 'package:flutter/material.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';

/// A titled card used for each About section.
class AboutSection extends StatelessWidget {
  const AboutSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm + 2),
                  ),
                  child: Icon(icon, size: 17, color: AppColors.accentSoft),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleLarge),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppTextStyles.overline),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

/// A tappable settings-style row with an icon, label, optional description and
/// a trailing chevron.
class AboutTile extends StatefulWidget {
  const AboutTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.description,
    this.accent,
    this.trailingIcon = Icons.arrow_outward_rounded,
  });

  final IconData icon;
  final String label;
  final String? description;
  final VoidCallback onTap;
  final Color? accent;
  final IconData trailingIcon;

  @override
  State<AboutTile> createState() => _AboutTileState();
}

class _AboutTileState extends State<AboutTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent ?? AppColors.textSecondary;

    return Semantics(
      button: true,
      label: widget.description == null
          ? widget.label
          : '${widget.label}. ${widget.description}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: AppDurations.micro,
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.surfaceHigh.withValues(alpha: 0.8)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: _hovered ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(widget.icon, size: 16, color: accent),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (widget.description != null) ...[
                        const SizedBox(height: 2),
                        Text(widget.description!,
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textTertiary,
                            )),
                      ],
                    ],
                  ),
                ),
                AnimatedSlide(
                  duration: AppDurations.micro,
                  offset: Offset(_hovered ? 0.18 : 0, 0),
                  child: Icon(
                    widget.trailingIcon,
                    size: 16,
                    color: _hovered
                        ? AppColors.textSecondary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A hairline divider used between tiles.
class TileDivider extends StatelessWidget {
  const TileDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.surfaceStroke.withValues(alpha: 0.6),
      ),
    );
  }
}

/// One technology in the stack.
class TechChip extends StatelessWidget {
  const TechChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: AppSpacing.sm - 2),
          ],
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A dependency row: name, what it does, and its licence.
class PackageRow extends StatelessWidget {
  const PackageRow({
    super.key,
    required this.name,
    required this.purpose,
    required this.licence,
    required this.onTap,
  });

  final String name;
  final String purpose;
  final String licence;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$name, $purpose, $licence licence',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.md - 2),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 2),
                    Text(purpose,
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.textTertiary)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm - 2),
                  border: Border.all(color: AppColors.surfaceStroke),
                ),
                child: Text(licence,
                    style: AppTextStyles.overline.copyWith(fontSize: 9)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Made with ❤️" sign-off and copyright.
class AboutFooter extends StatelessWidget {
  const AboutFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.surfaceStroke.withValues(alpha: 0),
                AppColors.surfaceStroke,
                AppColors.surfaceStroke.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        Semantics(
          label: 'Made with love by ${AppInfo.developerName}',
          excludeSemantics: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Made with ', style: AppTextStyles.body),
              const _BeatingHeart(),
              Text(' by ', style: AppTextStyles.body),
              Text(
                AppInfo.developerName,
                style: AppTextStyles.titleSmall.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '© ${AppInfo.copyrightYear} ${AppInfo.developerName} · '
          '${AppInfo.appName} v${AppInfo.version}',
          textAlign: TextAlign.center,
          style: AppTextStyles.overline.copyWith(letterSpacing: 0.4),
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        Text(
          'An unofficial fan project — not associated with Formula 1.',
          textAlign: TextAlign.center,
          style: AppTextStyles.overline
              .copyWith(color: AppColors.textTertiary, letterSpacing: 0.2),
        ),
        const SizedBox(height: AppSpacing.huge),
      ],
    );
  }
}

/// A gently pulsing heart — the one flourish in the footer.
class _BeatingHeart extends StatefulWidget {
  const _BeatingHeart();

  @override
  State<_BeatingHeart> createState() => _BeatingHeartState();
}

class _BeatingHeartState extends State<_BeatingHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect the OS "reduce motion" setting.
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    const heart = Icon(Icons.favorite_rounded,
        size: 15, color: AppColors.accentSoft);
    if (reduceMotion) return heart;

    return ScaleTransition(
      scale: Tween<double>(begin: 0.86, end: 1.1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: heart,
    );
  }
}
