import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/route/routes.dart';

/// [MainShell] — bottom-nav container for the three top-level tabs.
/// Used by GoRouter's [ShellRoute].
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const _tabs = <_TabSpec>[
    _TabSpec(
      route: dashboardRoute,
      path: '/dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Home',
    ),
    _TabSpec(
      route: settingsRoute,
      path: '/settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
    _TabSpec(
      route: profileRoute,
      path: '/profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
        onDestinationSelected: (i) {
          if (i == index) return;
          context.goNamed(_tabs[i].route);
        },
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.route,
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final String route;
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
