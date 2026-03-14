import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:foodbridge/core/services/auth_service.dart';
import 'package:foodbridge/core/services/user_repository.dart';
import 'package:foodbridge/shared/models/app_user.dart';

/// Helper to navigate to the correct home screen based on the user's role.
/// Useful for intercepting hardware back buttons on root-level bottom nav tabs.
Future<void> handleHomeNavigation(BuildContext context, WidgetRef ref) async {
  final authUser = ref.read(authServiceProvider).currentUser;
  if (authUser == null) {
    if (context.mounted) context.go('/login');
    return;
  }
  
  final appUser = await ref.read(userRepositoryProvider).getUser(authUser.uid);
  if (!context.mounted) return;
  
  if (appUser == null) {
    context.go('/home'); // Fallback to donor home
    return;
  }
  
  switch (appUser.role) {
    case AppRole.donor:
      context.go('/home');
      break;
    case AppRole.ngo:
      context.go('/ngo-home');
      break;
    case AppRole.volunteer:
      context.go('/volunteer-home');
      break;
    case AppRole.admin:
      context.go('/admin-dashboard');
      break;
  }
}
