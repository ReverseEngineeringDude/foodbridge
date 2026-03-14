import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodbridge/core/constants/app_constants.dart';
import 'package:foodbridge/core/services/auth_preferences.dart';
import 'package:foodbridge/core/services/auth_service.dart';
import 'package:foodbridge/core/services/user_repository.dart';
import 'package:foodbridge/shared/models/app_user.dart';
import 'package:foodbridge/shared/widgets/app_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final credential = await ref.read(authServiceProvider).signInWithEmail(email, password);
      
      if (credential.user != null) {
        final userId = credential.user!.uid;
        final prefs = await SharedPreferences.getInstance();
        await AuthPreferences(prefs).saveLoginState(userId);

        final appUser = await ref.read(userRepositoryProvider).getUser(userId);
        if (mounted) {
          if (appUser == null) {
            context.go('/home'); // Fallback if no profile
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first, then tap Forgot Password.')),
      );
      return;
    }
    try {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent! Check your inbox.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
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
             // Create a default donor profile
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDesign.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              FadeInDown(
                child: Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              const SizedBox(height: 8),
              FadeInDown(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Sign in to continue your impact',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
              const SizedBox(height: 40),
              FadeInUp(
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'Email'),
                      Tab(text: 'Phone'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 280,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEmailForm(),
                    _buildPhoneForm(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                text: 'Sign In',
                isLoading: _isLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _handleGoogleLogin,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(FontAwesomeIcons.google, size: 18, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      'Continue with Google',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text(
                      'Register Now',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      children: [
        AppTextField(
          label: 'Email Address',
          hint: 'john@example.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          controller: _emailController,
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Password',
          hint: '••••••••',
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          controller: _passwordController,
        ),
      ],
    );
  }

  Widget _buildPhoneForm() {
    return Column(
      children: const [
        AppTextField(
          label: 'Phone Number',
          hint: '+1 234 567 890',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 20),
        Text(
          'We will send a 6-digit verification code to your phone number.',
          style: TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
