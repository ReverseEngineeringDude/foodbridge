import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:foodbridge/core/utils/navigation_utils.dart';

// ─────────────────────────────────────────────────────────────
// Unified Liquid Glass Palette
// ─────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF141416);
  static const surface = Color(0xFF1E1E22);
  static const border = Color(0xFF2C2C32);

  static const pink = Color(0xFFE040A0);
  static const blue = Color(0xFF5B8DEF);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFAAAAAF);
  static const textMuted = Color(0xFF555560);

  static const gradientPink = LinearGradient(
    colors: [pink, Color(0xFF7B2FBE)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

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
        backgroundColor: _C.bg,
        appBar: _buildAppBar(context, ref),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: const _PolicyHero(),
                ),
                const SizedBox(height: 32),
                _buildSection(
                  delay: 100,
                  title: 'Introduction',
                  content:
                      'Your privacy is important to us. It is FoodBridge\'s policy to respect your '
                      'privacy regarding any information we may collect from you across our application.',
                ),
                _buildSection(
                  delay: 200,
                  title: 'Information We Collect',
                  content:
                      'We only ask for personal information when we truly need it to provide a service '
                      'to you. We collect it by fair and lawful means, with your knowledge and consent.',
                ),
                _buildSection(
                  delay: 300,
                  title: 'Data Security',
                  content:
                      'We don\'t share any personally identifying information publicly or with third-parties, '
                      'except when required to by law. We protect stored data within commercially acceptable '
                      'means to prevent loss and theft.',
                ),
                _buildSection(
                  delay: 400,
                  title: 'Cookie Policy',
                  content:
                      'Our app may use "cookies" to enhance user experience. You have the option to accept '
                      'or refuse these cookies and know when a cookie is being sent to your device.',
                ),
                const SizedBox(height: 20),
                FadeIn(
                  delay: const Duration(milliseconds: 500),
                  child: Center(
                    child: Text(
                      'Last updated: Oct 2023',
                      style: TextStyle(color: _C.textMuted, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: _C.bg,
      elevation: 0,
      centerTitle: true,
      leading: Center(
        child: GestureDetector(
          onTap: () async {
            if (context.canPop()) {
              context.pop();
            } else {
              await handleHomeNavigation(context, ref);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.border),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _C.textPrimary,
              size: 18,
            ),
          ),
        ),
      ),
      title: const Text(
        'Privacy Policy',
        style: TextStyle(
          color: _C.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildSection({
    required int delay,
    required String title,
    required String content,
  }) {
    return FadeInUp(
      delay: Duration(milliseconds: delay),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _C.pink,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: _C.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                color: _C.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyHero extends StatelessWidget {
  const _PolicyHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: _C.gradientPink,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _C.pink.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.security_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your Trust is Our\nPriority',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Learn how we handle and protect your data to ensure a safe experience for everyone.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}
