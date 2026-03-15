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

  const MainShell({super.key, required this.navigationShell});

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
            // Use Stack in body to float the nav bar
            body: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 100,
                  ), // Increased padding to prevent overlap
                  child: navigationShell,
                ),
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: _LiquidGlassNav(
                    navigationShell: navigationShell,
                    role: appUser.role,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LiquidGlassNav extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final AppRole role;

  const _LiquidGlassNav({required this.navigationShell, required this.role});

  @override
  State<_LiquidGlassNav> createState() => _LiquidGlassNavState();
}

class _LiquidGlassNavState extends State<_LiquidGlassNav> {
  double _dragAccum = 0;
  int _dragStartIndex = 0;

  @override
  Widget build(BuildContext context) {
    final items = _getNavItems(widget.role);
    final currentIndex = widget.navigationShell.currentIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onHorizontalDragStart: (details) {
        _dragStartIndex = currentIndex;
        _dragAccum = 0;
      },
      onHorizontalDragUpdate: (details) {
        _dragAccum += details.delta.dx;
        // every ~56px of drag = 1 tab step
        int step = (_dragAccum / 56).round();
        int target = (_dragStartIndex + step).clamp(0, items.length - 1);
        if (target != currentIndex) {
          _onTabSelected(context, target, items);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              color: isDark
                  ? Colors.white.withOpacity(0.02)
                  : Colors.black.withOpacity(
                      0.04,
                    ), // Subtle overlay for light theme
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.22),
                  Colors.white.withOpacity(0.06),
                  Colors.white.withOpacity(0.12),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.28),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final isSelected = currentIndex == i;
                final item = items[i];

                return GestureDetector(
                  onTap: () => _onTabSelected(context, i, items),
                  behavior: HitTestBehavior.opaque,
                  child: isSelected
                      ? _ActivePill(item: item)
                      : _NavItem(item: item, isSelected: false),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  void _onTabSelected(
    BuildContext context,
    int index,
    List<_NavItemData> items,
  ) {
    // Explicit path-based routing ensures we land on the correct role-specific page
    // (e.g., Donors go to /donate instead of the branch root /nearby-donations)
    context.go(items[index].path);
  }

  List<_NavItemData> _getNavItems(AppRole role) {
    switch (role) {
      case AppRole.donor:
        return [
          const _NavItemData(
            path: '/home',
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          const _NavItemData(
            path: '/donate',
            icon: Icons.add_circle_outline,
            activeIcon: Icons.add_circle_rounded,
            label: 'Donate',
          ),
          const _NavItemData(
            path: '/history',
            icon: Icons.history_outlined,
            activeIcon: Icons.history_rounded,
            label: 'History',
          ),
          const _NavItemData(
            path: '/profile',
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ];
      case AppRole.ngo:
        return [
          const _NavItemData(
            path: '/ngo-home',
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          const _NavItemData(
            path: '/nearby-donations',
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore_rounded,
            label: 'Nearby',
          ),
          const _NavItemData(
            path: '/accepted-donations',
            icon: Icons.fact_check_outlined,
            activeIcon: Icons.fact_check_rounded,
            label: 'Accepted',
          ),
          const _NavItemData(
            path: '/profile',
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ];
      case AppRole.volunteer:
        return [
          const _NavItemData(
            path: '/volunteer-home',
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          const _NavItemData(
            path: '/volunteer-tasks',
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment_rounded,
            label: 'Tasks',
          ),
          const _NavItemData(
            path: '/active-task',
            icon: Icons.delivery_dining_outlined,
            activeIcon: Icons.delivery_dining_rounded,
            label: 'Active',
          ),
          const _NavItemData(
            path: '/profile',
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ];
      case AppRole.admin:
        return [
          const _NavItemData(
            path: '/admin-dashboard',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: 'Dash',
          ),
          const _NavItemData(
            path: '/admin-users',
            icon: Icons.people_outline,
            activeIcon: Icons.people_rounded,
            label: 'Users',
          ),
          const _NavItemData(
            path: '/admin-donations',
            icon: Icons.monitor_heart_outlined,
            activeIcon: Icons.monitor_heart_rounded,
            label: 'Monitor',
          ),
          const _NavItemData(
            path: '/profile',
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ];
    }
  }
}

class _ActivePill extends StatelessWidget {
  final _NavItemData item;
  const _ActivePill({required this.item});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 70, // Increased width slightly for labels
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.30),
            Colors.white.withOpacity(0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      child: _NavItem(item: item, isSelected: true),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavItemData item;
  final bool isSelected;

  const _NavItem({required this.item, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSelected ? item.activeIcon : item.icon,
          color: Colors.white,
          size: 22,
        ),
        const SizedBox(height: 2),
        Text(
          item.label,
          style: TextStyle(
            color: Colors.white.withOpacity(isSelected ? 1.0 : 0.7),
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _NavItemData {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
