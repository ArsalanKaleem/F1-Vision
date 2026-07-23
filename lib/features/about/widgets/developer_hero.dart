import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';

/// The developer card: a themed background photo, a soft scrim so text always
/// clears contrast requirements, an avatar, a short bio, and brand-tinted
/// social buttons.
class DeveloperHero extends StatelessWidget {
  const DeveloperHero({super.key, required this.onOpen});

  /// Opens an external URL (handled by the screen so failures can be reported).
  final void Function(String url, String label) onOpen;

  @override
  Widget build(BuildContext context) {
    final light = AppColors.isLight;
    final compact = context.isMobile;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg + 4),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              light
                  ? 'assets/branding/about_hero_light.png'
                  : 'assets/branding/about_hero_dark.png',
              fit: BoxFit.cover,
              // A missing asset must never break the page.
              errorBuilder: (_, __, ___) => DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.heroGradient),
              ),
            ),
          ),
          // Scrim: keeps body text at an accessible contrast ratio over any
          // part of the artwork, in both themes.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: light
                      ? [
                          Colors.white.withValues(alpha: 0.86),
                          Colors.white.withValues(alpha: 0.70),
                        ]
                      : [
                          Colors.black.withValues(alpha: 0.72),
                          Colors.black.withValues(alpha: 0.58),
                        ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg + 4),
              border: Border.all(color: AppColors.surfaceStroke),
            ),
            padding: EdgeInsets.all(compact ? AppSpacing.xl : AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Avatar(size: 76),
                          const SizedBox(height: AppSpacing.lg),
                          const _Identity(),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          _Avatar(size: 92),
                          SizedBox(width: AppSpacing.xl),
                          Expanded(child: _Identity()),
                        ],
                      ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  AppInfo.developerBio,
                  style: AppTextStyles.body.copyWith(
                    height: 1.6,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _SocialRow(onOpen: onOpen),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 420.ms).slideY(
          begin: 0.04,
          end: 0,
          curve: Curves.easeOutCubic,
        );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    const asset = AppInfo.avatarAsset;

    return Semantics(
      label: 'Portrait of ${AppInfo.developerName}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.accentGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.32),
              blurRadius: 28,
              spreadRadius: -6,
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: ClipOval(
          child: asset == null
              ? Container(
                  color: AppColors.surface,
                  alignment: Alignment.center,
                  child: Text(
                    AppInfo.initials,
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontSize: size * 0.34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Image.asset(
                  asset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surface,
                    alignment: Alignment.center,
                    child: Text(AppInfo.initials,
                        style: AppTextStyles.headlineMedium
                            .copyWith(fontSize: size * 0.34)),
                  ),
                ),
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('DEVELOPER', style: AppTextStyles.overline),
        const SizedBox(height: AppSpacing.xs + 2),
        Text(AppInfo.developerName, style: AppTextStyles.displayLarge),
        const SizedBox(height: AppSpacing.xs + 2),
        Text(
          AppInfo.developerRole,
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.accentSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (AppInfo.developerLocation.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place_outlined,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(AppInfo.developerLocation, style: AppTextStyles.label),
            ],
          ),
        ],
      ],
    );
  }
}

class _SocialRow extends StatelessWidget {
  const _SocialRow({required this.onOpen});
  final void Function(String url, String label) onOpen;

  @override
  Widget build(BuildContext context) {
    final links = socialLinks.where((l) => l.url.trim().isNotEmpty).toList();
    if (links.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (var i = 0; i < links.length; i++)
          SocialButton(link: links[i], onOpen: onOpen)
              .animate()
              .fadeIn(delay: (60 * i).ms, duration: 300.ms)
              .scaleXY(begin: 0.86, end: 1, curve: Curves.easeOutBack),
      ],
    );
  }
}

/// A rounded, brand-tinted social button that lifts and saturates on hover.
class SocialButton extends StatefulWidget {
  const SocialButton({super.key, required this.link, required this.onOpen});
  final SocialLink link;
  final void Function(String url, String label) onOpen;

  @override
  State<SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<SocialButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final link = widget.link;
    final showLabel = !context.isMobile;

    return Semantics(
      button: true,
      label: '${link.label}, ${link.handle}',
      child: Tooltip(
        message: link.handle,
        waitDuration: const Duration(milliseconds: 300),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () => widget.onOpen(link.url, link.label),
            child: AnimatedContainer(
              duration: AppDurations.micro,
              curve: Curves.easeOut,
              transform:
                  Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
              // 44px minimum height keeps the tap target accessible.
              constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
              padding: EdgeInsets.symmetric(
                horizontal: showLabel ? AppSpacing.lg : AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: _hovered
                    ? link.color.withValues(alpha: 0.20)
                    : AppColors.surfaceHigh.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _hovered
                      ? link.color
                      : link.color.withValues(alpha: 0.38),
                ),
                boxShadow: _hovered
                    ? [
                        BoxShadow(
                          color: link.color.withValues(alpha: 0.30),
                          blurRadius: 18,
                          spreadRadius: -4,
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(link.icon, size: 16, color: link.color),
                  if (showLabel) ...[
                    const SizedBox(width: AppSpacing.sm + 2),
                    Text(
                      link.label,
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _hovered
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
