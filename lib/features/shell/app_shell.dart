import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../routes/nav_destinations.dart';
import 'app_drawer.dart';

/// The persistent chrome around every page. On desktop/tablet it renders a
/// collapsible navigation rail; on mobile it switches to a bottom bar. The body
/// is supplied by GoRouter's [StatefulShellRoute].
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _railExtended = true;

  int _indexFor(String location) {
    final i = appDestinations.indexWhere(
      (d) => d.path == '/'
          ? location == '/'
          : location.startsWith(d.path),
    );
    return i < 0 ? 0 : i;
  }

  void _go(int index) => context.go(appDestinations[index].path);

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = _indexFor(location);

    if (context.isMobile) {
      return Scaffold(
        // A slim bar purely to host the drawer button — every screen already
        // renders its own title, so this one only carries the wordmark.
        appBar: AppBar(
          toolbarHeight: 52,
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textSecondary),
          title: Text('F1 VISION',
              style: AppTextStyles.overline.copyWith(letterSpacing: 2)),
        ),
        drawer: AppDrawer(selected: selected, onSelect: _go),
        body: SafeArea(top: false, child: widget.child),
        bottomNavigationBar: _MobileNavBar(selected: selected, onTap: _go),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _DesktopRail(
            selected: selected,
            extended: _railExtended && context.isDesktop,
            onTap: _go,
            onToggle: () => setState(() => _railExtended = !_railExtended),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: SafeArea(child: widget.child)),
        ],
      ),
    );
  }
}

class _DesktopRail extends StatelessWidget {
  const _DesktopRail({
    required this.selected,
    required this.extended,
    required this.onTap,
    required this.onToggle,
  });

  final int selected;
  final bool extended;
  final ValueChanged<int> onTap;
  final VoidCallback onToggle;

  // The rail shows the primary destinations; secondary ones live under it.
  static const _primaryCount = 6;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: extended ? 240 : 76,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brand(extended),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (var i = 0; i < appDestinations.length; i++) ...[
                  if (i == _primaryCount)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(12, 16, 12, 8),
                      child: Divider(height: 1),
                    ),
                  _RailItem(
                    destination: appDestinations[i],
                    selected: selected == i,
                    extended: extended,
                    onTap: () => onTap(i),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onToggle,
            icon: Icon(
              extended ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _brand(bool extended) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text(
              'F1',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          if (extended) ...[
            const SizedBox(width: 12),
            Text('VISION', style: AppTextStyles.titleLarge),
          ],
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.accent.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.35)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            selected ? destination.selectedIcon : destination.icon,
            size: 20,
            color: selected ? AppColors.accentSoft : AppColors.textSecondary,
          ),
          if (extended) ...[
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                destination.label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSmall.copyWith(
                  color:
                      selected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: extended
            ? content
            : Tooltip(message: destination.label, child: content),
      ),
    );
  }
}

class _MobileNavBar extends StatelessWidget {
  const _MobileNavBar({required this.selected, required this.onTap});
  final int selected;
  final ValueChanged<int> onTap;

  /// The four most-used destinations get a permanent slot. Everything else is
  /// reachable from the drawer, so this list stays short on purpose.
  /// Indices map into `appDestinations` — update if that list is reordered.
  static const _primaryIndices = [0, 1, 7, 8];

  @override
  Widget build(BuildContext context) {
    final isPrimary = _primaryIndices.contains(selected);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceStroke)),
      ),
      child: NavigationBar(
        backgroundColor: Colors.transparent,
        // Nothing is highlighted while the user is on a drawer-only screen,
        // rather than falsely highlighting the first tab.
        selectedIndex: isPrimary ? _primaryIndices.indexOf(selected) : 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => onTap(_primaryIndices[i]),
        destinations: [
          for (final i in _primaryIndices)
            NavigationDestination(
              icon: Icon(appDestinations[i].icon),
              selectedIcon: Icon(
                appDestinations[i].selectedIcon,
                // Dim the "selected" icon when we're actually elsewhere.
                color: isPrimary ? null : AppColors.textSecondary,
              ),
              label: appDestinations[i].label,
            ),
        ],
      ),
    );
  }
}
