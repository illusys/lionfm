import 'package:flutter/material.dart';

class NavDestination {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const NavDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

const List<NavDestination> navDestinations = [
  NavDestination(
    label: 'Home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    route: '/',
  ),
  NavDestination(
    label: 'Schedule',
    icon: Icons.calendar_today_outlined,
    activeIcon: Icons.calendar_today,
    route: '/schedule',
  ),
  NavDestination(
    label: 'Podcasts',
    icon: Icons.radio_outlined,
    activeIcon: Icons.radio,
    route: '/podcasts',
  ),
  NavDestination(
    label: 'News',
    icon: Icons.article_outlined,
    activeIcon: Icons.article,
    route: '/news',
  ),
  NavDestination(
    label: 'Requests',
    icon: Icons.music_note_outlined,
    activeIcon: Icons.music_note,
    route: '/requests',
  ),
];
