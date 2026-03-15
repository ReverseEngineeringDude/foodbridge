import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodbridge/core/constants/app_constants.dart';
import 'package:foodbridge/core/services/auth_preferences.dart';
import 'package:foodbridge/core/services/auth_service.dart';
import 'package:foodbridge/core/services/user_repository.dart';
import 'package:foodbridge/shared/models/app_user.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      // User is logged in — skip onboarding and login, go to home
      try {
        final appUser = await ref
            .read(userRepositoryProvider)
            .getUser(user.uid);
        if (!mounted) return;
        if (appUser == null) {
          context.go('/home');
        } else {
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
      } catch (_) {
        if (mounted) context.go('/home');
      }
      return;
    }

    // Not logged in — check if onboarding was seen
    final prefs = await SharedPreferences.getInstance();
    final authPrefs = AuthPreferences(prefs);
    if (!mounted) return;
    if (authPrefs.hasSeenOnboarding) {
      context.go('/login');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset('assets/logo.png', width: 80, height: 80),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: Text(
                'Hope Meals',
                style: Theme.of(
                  context,
                ).textTheme.displayMedium?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
