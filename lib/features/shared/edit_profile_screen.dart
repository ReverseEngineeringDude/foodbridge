import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:foodbridge/core/constants/app_constants.dart';
import 'package:foodbridge/core/services/auth_service.dart';
import 'package:foodbridge/core/services/user_repository.dart';
import 'package:foodbridge/shared/models/app_user.dart';
import 'package:foodbridge/shared/widgets/app_widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final appUser = await ref.read(userRepositoryProvider).getUser(user.uid);
    if (mounted) {
      if (appUser != null) {
        _nameController.text = appUser.name;
        _phoneController.text = appUser.phone ?? '';
        _addressController.text = appUser.address ?? '';
      } else {
        _nameController.text = user.displayName ?? user.email?.split('@').first ?? '';
      }
      setState(() => _isLoaded = true);
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).updateDisplayName(name);

      final appUser = await ref.read(userRepositoryProvider).getUser(user.uid);
      final updatedUser = AppUser(
        id: user.uid,
        name: name,
        email: appUser?.email ?? user.email ?? '',
        role: appUser?.role ?? AppRole.donor,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        profileImageUrl: appUser?.profileImageUrl,
        createdAt: appUser?.createdAt ?? DateTime.now(),
        extraData: appUser?.extraData,
      );
      await ref.read(userRepositoryProvider).saveUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!'), behavior: SnackBarBehavior.floating),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
          ),
        ],
      ),
      body: _isLoaded
          ? SingleChildScrollView(
            padding: const EdgeInsets.all(AppDesign.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Full Name',
                  hint: 'Enter your name',
                  prefixIcon: Icons.person_outline,
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Phone (optional)',
                  hint: '+1 234 567 8900',
                  prefixIcon: Icons.phone_outlined,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Address',
                  hint: 'Enter your full address',
                  prefixIcon: Icons.location_on_outlined,
                  controller: _addressController,
                ),
                const SizedBox(height: 16),
                Text(
                  'Email cannot be changed here. It is linked to your account.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 40),
                AppPrimaryButton(
                  text: 'Save Changes',
                  isLoading: _isLoading,
                  onPressed: _saveProfile,
                ),
              ],
            ),
          )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
