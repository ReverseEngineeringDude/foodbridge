import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodbridge/core/constants/app_constants.dart';
import 'package:foodbridge/core/services/auth_preferences.dart';
import 'package:foodbridge/core/services/auth_service.dart';
import 'package:foodbridge/core/services/user_repository.dart';
import 'package:foodbridge/shared/models/app_user.dart';
import 'package:foodbridge/shared/widgets/app_widgets.dart';
import 'package:foodbridge/shared/widgets/location_selector.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  int _currentStep = 1;
  String? _selectedRole;
  bool _isLoading = false;
  String _selectedLocation = '';

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _nextStep() async {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      // Step 3: Complete registration with Firebase
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in your email and password.')),
        );
        return;
      }
      setState(() => _isLoading = true);
      try {
        final credential = await ref.read(authServiceProvider).registerWithEmail(email, password);
        
        if (credential.user != null) {
          final userId = credential.user!.uid;
          final prefs = await SharedPreferences.getInstance();
          await AuthPreferences(prefs).saveLoginState(userId);

          final role = AppRole.values.firstWhere(
            (e) => e.name == _selectedRole?.toLowerCase(),
            orElse: () => AppRole.donor,
          );

          final newUser = AppUser(
            id: userId,
            name: _nameController.text.trim(),
            email: email,
            role: role,
            address: _selectedLocation,
            createdAt: DateTime.now(),
          );

          await ref.read(userRepositoryProvider).saveUser(newUser);
        }

        if (mounted) context.go('/home');
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
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prevStep,
        ),
        title: Text('Step $_currentStep of 3'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDesign.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: _currentStep / 3,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildStepContent(),
                ),
              ),
              const SizedBox(height: 16),
              AppPrimaryButton(
                text: _currentStep == 3 ? 'Complete Setup' : 'Continue',
                isLoading: _isLoading,
                onPressed: () {
                  if (_currentStep == 2 && _selectedRole == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a role')),
                    );
                    return;
                  }
                  if (_currentStep == 3 && _selectedLocation.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select your location')),
                    );
                    return;
                  }
                  _nextStep();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildUserInfoStep();
      case 2:
        return _buildRoleSelectionStep();
      case 3:
        return _buildProfileSetupStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildUserInfoStep() {
    return FadeInRight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Account',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          const Text('Let\'s start with your basic information'),
          const SizedBox(height: 32),
          AppTextField(
            label: 'Full Name',
            hint: 'John Doe',
            prefixIcon: Icons.person_outline,
            controller: _nameController,
          ),
          const SizedBox(height: 20),
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
      ),
    );
  }

  Widget _buildRoleSelectionStep() {
    return FadeInRight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'I am a...',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          const Text('Select the role that best describes you'),
          const SizedBox(height: 32),
          _buildRoleCard(
            'Donor',
            'I want to donate surplus food',
            Icons.restaurant,
            AppColors.primary,
          ),
          const SizedBox(height: 16),
          _buildRoleCard(
            'NGO',
            'I want to receive and distribute food',
            Icons.corporate_fare,
            AppColors.secondary,
            isPending: true,
          ),
          const SizedBox(height: 16),
          _buildRoleCard(
            'Volunteer',
            'I want to help with deliveries',
            Icons.directions_bike,
            AppColors.pickedUp,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSetupStep() {
    return FadeInRight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Setup',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          const Text('Almost done! Add your location and photo'),
          const SizedBox(height: 32),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.person, size: 60, color: Colors.grey),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          LocationSelector(
            onChanged: (district, subDistrict, village) {
              setState(() => _selectedLocation = '$village, $subDistrict, $district, Kerala');
            },
          ),
          if (_selectedLocation.isNotEmpty) ...
            [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.secondary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedLocation,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildRoleCard(String title, String subtitle, IconData icon, Color color, {bool isPending = false}) {
    bool isSelected = _selectedRole == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(20) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : Colors.grey[200]!,
            width: 2,
          ),
          boxShadow: isSelected ? AppDesign.softShadow : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isPending) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PENDING APPROVAL',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color)
            else
              const Icon(Icons.circle_outlined, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
