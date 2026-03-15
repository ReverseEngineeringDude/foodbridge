import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:foodbridge/features/auth/splash_screen.dart';
import 'package:foodbridge/features/auth/onboarding_screen.dart';
import 'package:foodbridge/features/auth/login_screen.dart';
import 'package:foodbridge/features/auth/register_screen.dart';
import 'package:foodbridge/features/donor/home_screen.dart';
import 'package:foodbridge/features/donor/add_donation_screen.dart';
import 'package:foodbridge/features/ngo/home_screen.dart';
import 'package:foodbridge/features/ngo/nearby_donations_screen.dart';
import 'package:foodbridge/features/ngo/accepted_donations_screen.dart';
import 'package:foodbridge/features/volunteer/home_screen.dart';
import 'package:foodbridge/features/volunteer/active_task_screen.dart';
import 'package:foodbridge/features/volunteer/volunteer_tasks_screen.dart';
import 'package:foodbridge/features/admin/dashboard_screen.dart';
import 'package:foodbridge/features/admin/admin_manage_users_screen.dart';
import 'package:foodbridge/features/admin/admin_donation_monitor_screen.dart';
import 'package:foodbridge/features/admin/admin_system_reports_screen.dart';
import 'package:foodbridge/features/shared/profile_screen.dart';
import 'package:foodbridge/features/shared/edit_profile_screen.dart';
import 'package:foodbridge/features/shared/notifications_screen.dart';
import 'package:foodbridge/features/shared/activity_screen.dart';
import 'package:foodbridge/features/shared/support_screen.dart';
import 'package:foodbridge/features/shared/privacy_policy_screen.dart';
import 'package:foodbridge/features/shared/donation_detail_screen.dart';
import 'package:foodbridge/features/donor/history_screen.dart';
import 'package:foodbridge/shared/widgets/main_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // Auth Routes
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // Main App Shell
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const DonorHomeScreen(),
            ),
            GoRoute(
              path: '/ngo-home',
              builder: (context, state) => const NGOHomeScreen(),
            ),
            GoRoute(
              path: '/volunteer-home',
              builder: (context, state) => const VolunteerHomeScreen(),
            ),
            GoRoute(
              path: '/admin-dashboard',
              builder: (context, state) => const AdminDashboardScreen(),
            ),
          ],
        ),
        // Branch 1: Action
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/nearby-donations',
              builder: (context, state) => const NearbyDonationsScreen(),
            ),
            GoRoute(
              path: '/volunteer-tasks',
              builder: (context, state) => const VolunteerTasksScreen(),
            ),
            GoRoute(
              path: '/admin-users',
              builder: (context, state) => const AdminManageUsersScreen(),
            ),
            GoRoute(
              path: '/donate',
              builder: (context, state) => const AddDonationScreen(),
            ),
          ],
        ),
        // Branch 2: Status/History
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryScreen(),
            ),
            GoRoute(
              path: '/accepted-donations',
              builder: (context, state) => const AcceptedDonationsScreen(),
            ),
            GoRoute(
              path: '/admin-donations',
              builder: (context, state) => const AdminDonationMonitorScreen(),
            ),
            GoRoute(
              path: '/admin-reports',
              builder: (context, state) => const AdminSystemReportsScreen(),
            ),
            GoRoute(
              path: '/active-task',
              builder: (context, state) => const ActiveTaskScreen(),
            ),
          ],
        ),
        // Branch 3: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),


    // Global sub-pages
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/activity',
      builder: (context, state) => const ActivityScreen(),
    ),
    GoRoute(
      path: '/support',
      builder: (context, state) => const SupportScreen(),
    ),
    GoRoute(
      path: '/privacy-policy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/donation/:id',
      builder: (context, state) {
        final String id = state.pathParameters['id'] ?? '';
        final String heroTag = state.uri.queryParameters['heroTag'] ?? 'hero_$id';
        return DonationDetailScreen(
          donationId: id,
          heroTag: heroTag,
        );
      },
    ),
  ],
);
