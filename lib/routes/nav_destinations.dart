import 'package:flutter/material.dart';

/// A single navigation target, shared between the desktop rail and the mobile
/// bottom bar so the two stay in lockstep.
class NavDestination {
  const NavDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.section = NavSection.explore,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Which drawer group this destination belongs to. Purely presentational —
  /// the desktop rail renders the flat list and ignores it.
  final NavSection section;
}

/// Drawer groupings, rendered in declaration order.
enum NavSection {
  race('Race Weekend'),
  analysis('Analysis'),
  explore('Explore'),
  app('App');

  const NavSection(this.label);
  final String label;
}

const appDestinations = <NavDestination>[
  NavDestination(
    path: '/',
    section: NavSection.race,
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
  ),
  NavDestination(
    path: '/live',
    section: NavSection.race,
    label: 'Live Race',
    icon: Icons.sensors_outlined,
    selectedIcon: Icons.sensors_rounded,
  ),
  NavDestination(
    path: '/drivers',
    section: NavSection.explore,
    label: 'Drivers',
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
  ),
  NavDestination(
    path: '/teams',
    section: NavSection.explore,
    label: 'Teams',
    icon: Icons.shield_outlined,
    selectedIcon: Icons.shield_rounded,
  ),
  NavDestination(
    path: '/standings',
    section: NavSection.analysis,
    label: 'Standings',
    icon: Icons.leaderboard_outlined,
    selectedIcon: Icons.leaderboard_rounded,
  ),
  NavDestination(
    path: '/calendar',
    section: NavSection.explore,
    label: 'Calendar',
    icon: Icons.calendar_today_outlined,
    selectedIcon: Icons.calendar_today_rounded,
  ),
  NavDestination(
    path: '/telemetry',
    section: NavSection.race,
    label: 'Telemetry',
    icon: Icons.show_chart_outlined,
    selectedIcon: Icons.show_chart_rounded,
  ),
  NavDestination(
    path: '/analytics',
    section: NavSection.analysis,
    label: 'Analytics',
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights_rounded,
  ),
  NavDestination(
    path: '/replay',
    section: NavSection.analysis,
    label: 'Replay',
    icon: Icons.replay_circle_filled_outlined,
    selectedIcon: Icons.replay_circle_filled_rounded,
  ),
  NavDestination(
    path: '/compare',
    section: NavSection.analysis,
    label: 'Compare',
    icon: Icons.compare_arrows_outlined,
    selectedIcon: Icons.compare_arrows_rounded,
  ),
  NavDestination(
    path: '/about',
    section: NavSection.app,
    label: 'About',
    icon: Icons.info_outline_rounded,
    selectedIcon: Icons.info_rounded,
  ),
  NavDestination(
    path: '/settings',
    section: NavSection.app,
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
  ),
];
