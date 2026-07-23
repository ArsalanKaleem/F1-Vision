import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_info.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/theme_providers.dart';
import '../../routes/nav_destinations.dart';

/// The slide-out navigation drawer.
///
/// Lists every destination grouped by [NavSection], so nothing is more than
/// two taps away on a phone, and carries a brand header plus a quick theme
/// switch in the footer.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  /// Index into [appDestinations] of the active route.
  final int selected;

  /// Called with the chosen index after the drawer closes.
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const _DrawerHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
                children: [
                  for (final section in NavSection.values)
                    ..._buildSection(context, section),
                ],
              ),
            ),
            const _DrawerFooter(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSection(BuildContext context, NavSection section) {
    final entries = <({int index, NavDestination destination})>[
      for (var i = 0; i < appDestinations.length; i++)
        if (appDestinations[i].section == section)
          (index: i, destination: appDestinations[i]),
    ];
    if (entries.isEmpty) return const [];

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
        child: Text(section.label.toUpperCase(), style: AppTextStyles.overline),
      ),
      for (final entry in entries)
        _DrawerItem(
          destination: entry.destination,
          active: entry.index == selected,
          onTap: () {
            Navigator.of(context).pop();
            onSelect(entry.index);
          },
        ),
    ];
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.16),
            AppColors.accent.withValues(alpha: 0.02),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceStroke),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: const Text(
              'F1',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppInfo.appName, style: AppTextStyles.titleLarge),
                const SizedBox(height: 2),
                Text('v${AppInfo.version}', style: AppTextStyles.overline),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.destination,
    required this.active,
    required this.onTap,
  });

  final NavDestination destination;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: active
              ? AppColors.accent.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.md - 2),
              child: Row(
                children: [
                  // Active marker doubles as a non-colour cue for accessibility.
                  AnimatedContainer(
                    duration: AppDurations.micro,
                    width: 3,
                    height: active ? 20 : 0,
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: active ? AppSpacing.md - 3 : AppSpacing.md),
                  Icon(
                    active ? destination.selectedIcon : destination.icon,
                    size: 20,
                    color:
                        active ? AppColors.accentSoft : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick theme switch and a sign-off, pinned to the bottom of the drawer.
class _DrawerFooter extends ConsumerWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.surfaceStroke)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('APPEARANCE', style: AppTextStyles.overline),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final mode in ThemeMode.values) ...[
                Expanded(
                  child: _ThemeChip(
                    mode: mode,
                    active: theme.mode == mode,
                    onTap: () => controller.setMode(mode),
                  ),
                ),
                if (mode != ThemeMode.values.last)
                  const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '© ${AppInfo.copyrightYear} ${AppInfo.developerName}',
            style: AppTextStyles.overline
                .copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.mode,
    required this.active,
    required this.onTap,
  });

  final ThemeMode mode;
  final bool active;
  final VoidCallback onTap;

  ({IconData icon, String label}) get _meta => switch (mode) {
        ThemeMode.dark => (icon: Icons.dark_mode_rounded, label: 'Dark'),
        ThemeMode.light => (icon: Icons.light_mode_rounded, label: 'Light'),
        ThemeMode.system => (icon: Icons.settings_suggest_rounded, label: 'Auto'),
      };

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    return Semantics(
      button: true,
      selected: active,
      label: '${meta.label} theme',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.micro,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: active
                ? AppColors.accent.withValues(alpha: 0.16)
                : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
            border: Border.all(
              color: active ? AppColors.accent : AppColors.surfaceStroke,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                meta.icon,
                size: 16,
                color: active ? AppColors.accentSoft : AppColors.textSecondary,
              ),
              const SizedBox(height: 3),
              Text(
                meta.label,
                style: AppTextStyles.overline.copyWith(
                  fontSize: 9,
                  color:
                      active ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
