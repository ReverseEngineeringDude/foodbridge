import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodbridge/core/services/auth_preferences.dart';
import 'package:foodbridge/core/services/auth_service.dart';
import 'package:foodbridge/core/services/user_repository.dart';
import 'package:foodbridge/shared/models/app_user.dart';

// ─────────────────────────────────────────────────────────────
// Unified Liquid Glass Palette
// ─────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF141416);
  static const surface = Color(0xFF1E1E22);
  static const surfaceAlt = Color(0xFF252529);
  static const border = Color(0xFF2C2C32);

  static const pink = Color(0xFFE040A0);
  static const purple = Color(0xFF7B2FBE);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFAAAAAF);
  static const textMuted = Color(0xFF555560);

  static const gradientPink = LinearGradient(
    colors: [pink, purple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── LOGIC FUNCTIONS (UNCHANGED) ────────────────────────────

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter your email and password.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final credential = await ref
          .read(authServiceProvider)
          .signInWithEmail(email, password);

      if (credential.user != null) {
        final userId = credential.user!.uid;
        final prefs = await SharedPreferences.getInstance();
        await AuthPreferences(prefs).saveLoginState(userId);

        final appUser = await ref.read(userRepositoryProvider).getUser(userId);
        if (mounted) {
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
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Enter your email first, then tap Forgot Password.');
      return;
    }
    try {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      if (mounted) {
        _showSnackBar(
          'Password reset email sent! Check your inbox.',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar(e.toString());
    }
  }

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final credential = await ref.read(authServiceProvider).signInWithGoogle();

      if (credential != null && credential.user != null) {
        final userId = credential.user!.uid;
        final prefs = await SharedPreferences.getInstance();
        await AuthPreferences(prefs).saveLoginState(userId);

        final appUser = await ref.read(userRepositoryProvider).getUser(userId);

        if (!mounted) return;

        if (appUser == null) {
          final newUser = AppUser(
            id: credential.user!.uid,
            name: credential.user!.displayName ?? 'New User',
            email: credential.user!.email ?? '',
            role: AppRole.donor,
            address: 'Update profile with your location',
            createdAt: DateTime.now(),
          );
          await ref.read(userRepositoryProvider).saveUser(newUser);
          if (!mounted) return;
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
      }
    } catch (e) {
      if (mounted) _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFFF4D4D) : _C.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── UI REDESIGN ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          color: _C.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue your impact',
                        style: TextStyle(
                          color: _C.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Email Form
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: _buildEmailForm(),
                ),

                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _handleForgotPassword,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: _C.pink,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: _GlassButton(
                    label: 'Sign In',
                    isLoading: _isLoading,
                    onTap: _handleLogin,
                    gradient: _C.gradientPink,
                  ),
                ),
                const SizedBox(height: 32),

                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: Row(
                    children: [
                      Expanded(child: Container(height: 1, color: _C.border)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: _C.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(child: Container(height: 1, color: _C.border)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: _GlassButton(
                    label: 'Continue with Google',
                    onTap: _handleGoogleLogin,
                    icon: FontAwesomeIcons.google,
                    isOutlined: true,
                  ),
                ),

                const SizedBox(height: 48),
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: _C.textSecondary),
                      ),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: const Text(
                          'Register Now',
                          style: TextStyle(
                            color: _C.pink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      children: [
        _GlassTextField(
          label: 'Email Address',
          hint: 'john@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          controller: _emailController,
        ),
        const SizedBox(height: 24),
        _GlassTextField(
          label: 'Password',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          controller: _passwordController,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Redesigned Components
// ─────────────────────────────────────────────────────────────

class _GlassTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;

  const _GlassTextField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<_GlassTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            widget.label.toUpperCase(),
            style: const TextStyle(
              color: _C.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
          ),
          child: TextField(
            controller: widget.controller,
            obscureText: widget.isPassword ? _obscureText : false,
            keyboardType: widget.keyboardType,
            style: const TextStyle(color: _C.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(color: _C.textMuted, fontSize: 14),
              prefixIcon: Icon(
                widget.icon,
                color: _C.pink.withOpacity(0.7),
                size: 20,
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: _C.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isOutlined;
  final LinearGradient? gradient;
  final IconData? icon;

  const _GlassButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.isOutlined = false,
    this.gradient,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isOutlined ? null : gradient,
          color: isOutlined
              ? Colors.transparent
              : (gradient == null ? _C.pink : null),
          borderRadius: BorderRadius.circular(16),
          border: isOutlined ? Border.all(color: _C.border, width: 1.5) : null,
          boxShadow: !isOutlined
              ? [
                  BoxShadow(
                    color: (gradient?.colors.first ?? _C.pink).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        color: isOutlined ? Colors.blue : Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
