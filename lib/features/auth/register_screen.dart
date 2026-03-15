import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodbridge/core/services/auth_preferences.dart';
import 'package:foodbridge/core/services/auth_service.dart';
import 'package:foodbridge/core/services/user_repository.dart';
import 'package:foodbridge/shared/models/app_user.dart';
import 'package:foodbridge/shared/widgets/location_selector.dart';

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
  static const amber = Color(0xFFF5A623);
  static const blue = Color(0xFF5B8DEF);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFAAAAAF);
  static const textMuted = Color(0xFF555560);

  static const gradientPink = LinearGradient(
    colors: [pink, purple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

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
  String? _profileBase64;
  bool _obscurePassword = true;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── LOGIC FUNCTIONS (UNCHANGED) ────────────────────────────

  void _nextStep() async {
    if (_currentStep < 3) {
      if (_currentStep == 1) {
        if (_nameController.text.isEmpty ||
            _emailController.text.isEmpty ||
            _passwordController.text.isEmpty) {
          _showSnackBar('Please fill in all basic info.');
          return;
        }
      }
      setState(() => _currentStep++);
    } else {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      setState(() => _isLoading = true);
      try {
        final credential = await ref
            .read(authServiceProvider)
            .registerWithEmail(email, password);

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
            profileImageUrl: _profileBase64,
            createdAt: DateTime.now(),
          );

          await ref.read(userRepositoryProvider).saveUser(newUser);
        }

        if (mounted) context.go('/home');
      } catch (e) {
        if (mounted) _showSnackBar(e.toString().replaceAll('Exception: ', ''));
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

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 400,
      maxHeight: 400,
    );

    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _profileBase64 = base64Encode(bytes);
      });
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _C.surfaceAlt,
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
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _prevStep();
      },
      child: Scaffold(
        backgroundColor: _C.bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressIndicator(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: _buildStepContent(),
                ),
              ),
              _buildBottomAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _prevStep,
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
          Expanded(
            child: Text(
              'Step $_currentStep of 3',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _C.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(3, (index) {
          bool isActive = _currentStep > index;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
              decoration: BoxDecoration(
                gradient: isActive ? _C.gradientPink : null,
                color: isActive ? null : _C.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: _C.bg,
        border: Border(top: BorderSide(color: _C.border, width: 0.5)),
      ),
      child: _GlassButton(
        label: _currentStep == 3 ? 'Complete Setup' : 'Continue',
        isLoading: _isLoading,
        gradient: _C.gradientPink,
        onTap: () {
          if (_currentStep == 2 && _selectedRole == null) {
            _showSnackBar('Please select your role');
            return;
          }
          if (_currentStep == 3 && _selectedLocation.isEmpty) {
            _showSnackBar('Please select your location');
            return;
          }
          _nextStep();
        },
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
      duration: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle(
            title: 'Create Account',
            subtitle: 'Start with your basic information',
          ),
          const SizedBox(height: 40),
          _GlassTextField(
            label: 'Full Name',
            hint: 'John Doe',
            icon: Icons.person_outline_rounded,
            controller: _nameController,
          ),
          const SizedBox(height: 24),
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
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: _C.textMuted,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            controller: _passwordController,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelectionStep() {
    return FadeInRight(
      duration: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle(
            title: 'I am a...',
            subtitle: 'Select the role that best describes you',
          ),
          const SizedBox(height: 32),
          _buildRoleCard(
            'Donor',
            'I want to donate surplus food',
            Icons.restaurant_rounded,
            _C.pink,
          ),
          const SizedBox(height: 16),
          _buildRoleCard(
            'NGO',
            'I want to receive and distribute food',
            Icons.corporate_fare_rounded,
            _C.blue,
            isPending: true,
          ),
          const SizedBox(height: 16),
          _buildRoleCard(
            'Volunteer',
            'I want to help with deliveries',
            Icons.directions_bike_rounded,
            _C.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSetupStep() {
    return FadeInRight(
      duration: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle(
            title: 'Profile Setup',
            subtitle: 'Almost done! Add your location and photo',
          ),
          const SizedBox(height: 32),
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    gradient: _C.gradientPink,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: _C.bg,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: _C.surface,
                      backgroundImage: _profileBase64 != null
                          ? MemoryImage(base64Decode(_profileBase64!))
                          : null,
                      child: _profileBase64 == null
                          ? const Icon(
                              Icons.person_rounded,
                              size: 60,
                              color: _C.textMuted,
                            )
                          : null,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: _C.gradientPink,
                      shape: BoxShape.circle,
                      border: Border.all(color: _C.bg, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: _C.pink.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          LocationSelector(
            onChanged: (district, subDistrict, village) {
              setState(
                () => _selectedLocation =
                    '$village, $subDistrict, $district, Kerala',
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRoleCard(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    bool isPending = false,
  }) {
    bool isSelected = _selectedRole == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : _C.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.4) : _C.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20)]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
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
                          color: _C.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isPending) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _C.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NGO',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: _C.amber,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _C.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Icon(
                      Icons.check_circle_rounded,
                      color: color,
                      key: const ValueKey('checked'),
                    )
                  : Icon(
                      Icons.circle_outlined,
                      color: _C.border,
                      key: const ValueKey('unchecked'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Redesigned Components
// ─────────────────────────────────────────────────────────────

class _StepTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _StepTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _C.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: _C.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;

  const _GlassTextField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: _C.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
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
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(color: _C.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _C.textMuted, fontSize: 14),
              prefixIcon: Icon(icon, color: _C.pink.withOpacity(0.7), size: 20),
              suffixIcon: suffixIcon,
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
  final LinearGradient? gradient;

  const _GlassButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: (gradient?.colors.first ?? _C.pink).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
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
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}
