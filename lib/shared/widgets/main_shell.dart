import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:foodbridge/core/services/auth_service.dart';
import 'package:foodbridge/core/services/user_repository.dart';
import 'package:foodbridge/shared/models/app_user.dart';
import 'package:foodbridge/core/utils/navigation_utils.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return navigationShell;

    return StreamBuilder<AppUser?>(
      stream: ref.watch(userRepositoryProvider).streamUser(user.uid),
      builder: (context, snapshot) {
        final appUser = snapshot.data;
        if (appUser == null) {
          return Scaffold(body: navigationShell);
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (context.canPop()) {
              context.pop();
            } else {
              await handleHomeNavigation(context, ref);
            }
          },
          child: Scaffold(
            body: navigationShell,
            bottomNavigationBar: _AppNavigationBar(
              navigationShell: navigationShell,
              role: appUser.role,
            ),
          ),
        );
      },
    );
  }
}

class _AppNavigationBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final AppRole role;

  const _AppNavigationBar({
    required this.navigationShell,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final items = _getNavItems(role);
    final theme = Theme.of(context);
    final roleColor = _getRoleColor(role);

    return NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => context.go(items[index].path),
      backgroundColor: theme.scaffoldBackgroundColor,
      indicatorColor: roleColor.withOpacity(0.15),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      height: 65,
      destinations: items.map((item) {
        return NavigationDestination(
          icon: Icon(item.icon, color: theme.hintColor),
          selectedIcon: Icon(item.activeIcon, color: roleColor),
          label: item.label,
        );
      }).toList(),
    );
  }

  List<_NavItem> _getNavItems(AppRole role) {
    switch (role) {
      case AppRole.donor:
        return [
          const _NavItem(path: '/home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
          const _NavItem(path: '/donate', icon: Icons.add_circle_outline, activeIcon: Icons.add_circle_rounded, label: 'Donate'),
          const _NavItem(path: '/history', icon: Icons.history_outlined, activeIcon: Icons.history_rounded, label: 'History'),
          const _NavItem(path: '/profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
        ];
      case AppRole.ngo:
        return [
          const _NavItem(path: '/ngo-home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
          const _NavItem(path: '/nearby-donations', icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, label: 'Nearby'),
          const _NavItem(path: '/accepted-donations', icon: Icons.fact_check_outlined, activeIcon: Icons.fact_check_rounded, label: 'Accepted'),
          const _NavItem(path: '/profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
        ];
      case AppRole.volunteer:
        return [
          const _NavItem(path: '/volunteer-home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
          const _NavItem(path: '/volunteer-tasks', icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: 'Tasks'),
          const _NavItem(path: '/active-task', icon: Icons.delivery_dining_outlined, activeIcon: Icons.delivery_dining_rounded, label: 'Active'),
          const _NavItem(path: '/profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
        ];
      case AppRole.admin:
        return [
          const _NavItem(path: '/admin-dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dash'),
          const _NavItem(path: '/admin-users', icon: Icons.people_outline, activeIcon: Icons.people_rounded, label: 'Users'),
          const _NavItem(path: '/admin-donations', icon: Icons.monitor_heart_outlined, activeIcon: Icons.monitor_heart_rounded, label: 'Monitor'),
          const _NavItem(path: '/profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
        ];
    }
  }

  Color _getRoleColor(AppRole role) {
    switch (role) {
      case AppRole.donor: return const Color(0xFFE040A0);
      case AppRole.ngo: return const Color(0xFF3DD68C);
      case AppRole.volunteer: return const Color(0xFFE040A0);
      case AppRole.admin: return const Color(0xFF5B8DEF);
    }
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
