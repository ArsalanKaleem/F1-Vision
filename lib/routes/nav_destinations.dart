import 'package:flutter/material.dart';

/// A single navigation target, shared between the desktop rail and the mobile
/// bottom bar so the two stay in lockstep.
class NavDestination {
  const NavDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const appDestinations = <NavDestination>[
  NavDestination(
    path: '/',
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
  ),
  NavDestination(
    path: '/live',
    label: 'Live Race',
    icon: Icons.sensors_outlined,
    selectedIcon: Icons.sensors_rounded,
  ),
  NavDestination(
    path: '/drivers',
    label: 'Drivers',
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
  ),
  NavDestination(
    path: '/teams',
    label: 'Teams',
    icon: Icons.shield_outlined,
    selectedIcon: Icons.shield_rounded,
  ),
  NavDestination(
    path: '/standings',
    label: 'Standings',
    icon: Icons.leaderboard_outlined,
    selectedIcon: Icons.leaderboard_rounded,
  ),
  NavDestination(
    path: '/calendar',
    label: 'Calendar',
    icon: Icons.calendar_today_outlined,
    selectedIcon: Icons.calendar_today_rounded,
  ),
  NavDestination(
    path: '/telemetry',
    label: 'Telemetry',
    icon: Icons.show_chart_outlined,
    selectedIcon: Icons.show_chart_rounded,
  ),
  NavDestination(
    path: '/analytics',
    label: 'Analytics',
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights_rounded,
  ),
  NavDestination(
    path: '/compare',
    label: 'Compare',
    icon: Icons.compare_arrows_outlined,
    selectedIcon: Icons.compare_arrows_rounded,
  ),
  NavDestination(
    path: '/settings',
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
  ),
];
