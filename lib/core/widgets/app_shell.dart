import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../app/theme/app_colors.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const _destinations = [
    _NavigationDestination(
      route: AppRoutes.home,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavigationDestination(
      route: AppRoutes.vault,
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_rounded,
      label: 'Vault',
    ),
    _NavigationDestination(
      route: AppRoutes.tools,
      icon: Icons.build_outlined,
      selectedIcon: Icons.build_rounded,
      label: 'Tools',
    ),
    _NavigationDestination(
      route: AppRoutes.collections,
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder_rounded,
      label: 'Collections',
    ),
    _NavigationDestination(
      route: AppRoutes.settings,
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    if (location.startsWith(AppRoutes.vault)) {
      return 1;
    }

    if (location.startsWith(AppRoutes.tools)) {
      return 2;
    }

    if (location.startsWith(AppRoutes.collections)) {
      return 3;
    }

    if (location.startsWith(AppRoutes.settings)) {
      return 4;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      backgroundColor: AppColors.background,

      body: child,

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,

        onDestinationSelected: (index) {
          context.go(_destinations[index].route);
        },

        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

class _NavigationDestination {
  const _NavigationDestination({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
