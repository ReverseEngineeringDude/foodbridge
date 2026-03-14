import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:foodbridge/core/services/auth_service.dart';
import 'package:foodbridge/core/services/donation_repository.dart';
import 'package:foodbridge/shared/models/donation.dart';
import 'package:uuid/uuid.dart';
import 'package:foodbridge/core/utils/navigation_utils.dart';
import 'package:foodbridge/shared/widgets/location_selector.dart';

// ─────────────────────────────────────────────────────────────
// Color Palette
// ─────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF141416);
  static const surface = Color(0xFF1E1E22);
  static const surfaceAlt = Color(0xFF252529);
  static const border = Color(0xFF2C2C32);
  static const pink = Color(0xFFE040A0);
  static const purple = Color(0xFF7B2FBE);
  static const amber = Color(0xFFF5A623);
  static const green = Color(0xFF3DD68C);
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

class AddDonationScreen extends ConsumerStatefulWidget {
  const AddDonationScreen({super.key});
  @override
  ConsumerState<AddDonationScreen> createState() => _AddDonationScreenState();
}

class _AddDonationScreenState extends ConsumerState<AddDonationScreen> {
  int _currentStep = 1;
  String _foodCategory = 'Veg';

  final _foodNameController = TextEditingController();
  final _servingsController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _expiresInController = TextEditingController();
  final _locationController = TextEditingController();

  final List<String> _uploadedImageBase64 = [];
  bool _isUploading = false;

  @override
  void dispose() {
    _foodNameController.dispose();
    _servingsController.dispose();
    _quantityController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _expiresInController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ── LOGIC FUNCTIONS (UNCHANGED) ────────────────────────────
  void _nextStep() async {
    if (_currentStep == 1) {
      if (_foodNameController.text.isEmpty ||
          _servingsController.text.isEmpty ||
          _quantityController.text.isEmpty) {
        _showSnackBar('Please fill out the food details.');
        return;
      }
    } else if (_currentStep == 2) {
      if (_addressController.text.isEmpty ||
          _expiresInController.text.isEmpty) {
        _showSnackBar('Please fill out pickup details.');
        return;
      }
    }
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      await _submitDonation();
    }
  }

  Future<void> _submitDonation() async {
    if (_uploadedImageBase64.isEmpty) {
      _showSnackBar('Please upload at least one photo.');
      return;
    }
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() => _isUploading = true);
    try {
      final now = DateTime.now();
      final expiresInHours = int.tryParse(_expiresInController.text) ?? 4;
      final donation = Donation(
        id: const Uuid().v4(),
        donorId: user.uid,
        donorName: user.displayName ?? user.email?.split('@').first ?? 'Donor',
        foodName: _foodNameController.text.trim(),
        category: _foodCategory,
        servings: int.tryParse(_servingsController.text) ?? 0,
        quantityKg: double.tryParse(_quantityController.text) ?? 0.0,
        description: _descController.text.trim(),
        pickupAddress: _addressController.text.trim(),
        pickupWindowStart: now,
        pickupWindowEnd: now.add(const Duration(hours: 2)),
        imageBase64List: _uploadedImageBase64,
        status: DonationStatus.available,
        createdAt: now,
        expiresAt: now.add(Duration(hours: expiresInHours)),
      );
      await ref.read(donationRepositoryProvider).createDonation(donation);
      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) _showSnackBar('Failed to submit donation: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      if (!_isUploading) setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  Future<void> _pickAndEncodeImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64 = base64Encode(bytes);
        if (mounted) setState(() => _uploadedImageBase64.add(base64));
      } catch (e) {
        if (mounted) _showSnackBar('Failed to add photo: $e');
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: _C.surfaceAlt,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  // ── END LOGIC FUNCTIONS ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // FIX 1 — build() returned a bare Container, not a Scaffold.
    //          Without Scaffold: keyboard avoidance, MediaQuery.padding,
    //          SnackBar context, and SafeArea all break.
    //          Scaffold with resizeToAvoidBottomInset: true ensures the
    //          keyboard pushes content up properly on all fields.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (GoRouter.of(context).canPop()) {
          context.pop();
        } else {
          await handleHomeNavigation(context, ref);
        }
      },
      child: Scaffold(
        backgroundColor: _C.bg,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [_buildHeader(context), _buildProgressHeader()],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: _buildStepContent(),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (GoRouter.of(context).canPop()) {
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
                Icons.close_rounded,
                color: _C.textPrimary,
                size: 20,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'New Donation',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _C.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = _currentStep > index;
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

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: _C.bg,
        border: Border(top: BorderSide(color: _C.border, width: 0.5)),
      ),
      child: Row(
        children: [
          if (_currentStep > 1) ...[
            Expanded(
              child: _GlassButton(
                label: 'Back',
                onTap: _prevStep,
                isOutlined: true,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: _GlassButton(
              label: _currentStep == 3 ? 'Submit Donation' : 'Continue',
              onTap: _nextStep,
              isLoading: _isUploading,
              gradient: _C.gradientPink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildFoodInfoStep();
      case 2:
        return _buildPickupDetailsStep();
      case 3:
        return _buildPhotosStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildFoodInfoStep() {
    return FadeInRight(
      duration: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle(
            title: 'Food Info',
            subtitle: 'What are you sharing today?',
          ),
          const SizedBox(height: 32),
          _GlassTextField(
            controller: _foodNameController,
            label: 'Food Name',
            hint: 'e.g. Vegetable Biryani',
            icon: Icons.restaurant_rounded,
          ),
          const SizedBox(height: 24),
          const Text(
            'Category',
            style: TextStyle(
              color: _C.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          // FIX 2 — chips were in a plain Row with no flex; on narrow screens
          //          long labels overflow. Wrapped in a Row with each chip in
          //          an Expanded so they share space evenly.
          Row(
            children: [
              Expanded(child: _buildCategoryChip('Veg', Icons.eco_rounded)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCategoryChip(
                  'Non-Veg',
                  Icons.kebab_dining_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _GlassTextField(
                  controller: _servingsController,
                  label: 'Servings',
                  hint: '20',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _GlassTextField(
                  controller: _quantityController,
                  label: 'Quantity (kg)',
                  hint: '5',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _GlassTextField(
            controller: _descController,
            label: 'Brief Description',
            hint: 'Any special notes?',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPickupDetailsStep() {
    return FadeInRight(
      duration: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle(
            title: 'Pickup Location',
            subtitle: 'Where can volunteers collect it?',
          ),
          const SizedBox(height: 32),
          _GlassTextField(
            controller: _addressController,
            label: 'Specific Address',
            hint: 'Floor, Landmark, etc.',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.border),
            ),
            child: LocationSelector(
              onChanged: (district, subDistrict, village) {
                final location = '$village, $subDistrict, $district, Kerala';
                _locationController.text = location;
                if (_addressController.text.isEmpty)
                  _addressController.text = location;
              },
            ),
          ),
          const SizedBox(height: 24),
          _GlassTextField(
            controller: _expiresInController,
            label: 'Expires In (hours)',
            hint: '4',
            icon: Icons.timer_outlined,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosStep() {
    return FadeInRight(
      duration: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle(
            title: 'Review & Photos',
            subtitle: 'Add a photo and check details',
          ),
          const SizedBox(height: 32),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              ..._uploadedImageBase64.map((b64) => _buildUploadedImage(b64)),
              if (_uploadedImageBase64.length < 3) _buildAddPhotoCard(),
              ...List.generate(
                (3 - _uploadedImageBase64.length - 1).clamp(0, 3),
                (_) => _buildPhotoPlaceholder(),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _SectionLabel('Summary'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _C.border),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  'Food',
                  _foodNameController.text.isEmpty
                      ? 'Not set'
                      : _foodNameController.text,
                ),
                _buildSummaryDivider(),
                _buildSummaryRow(
                  'Quantity',
                  '${_servingsController.text.isEmpty ? '0' : _servingsController.text} servings',
                ),
                _buildSummaryDivider(),
                _buildSummaryRow(
                  'Address',
                  _addressController.text.isEmpty
                      ? 'Not set'
                      : _addressController.text,
                ),
                _buildSummaryDivider(),
                _buildSummaryRow(
                  'Expiry',
                  '${_expiresInController.text.isEmpty ? '4' : _expiresInController.text} hours',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    final isSelected = _foodCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _foodCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? _C.gradientPink : null,
          color: isSelected ? null : _C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white.withOpacity(0.1) : _C.border,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: _C.pink.withOpacity(0.3), blurRadius: 10)]
              : null,
        ),
        // FIX 3 — chips now inside Expanded (parent), so mainAxisSize.max
        //          fills available width cleanly; center aligns content
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : _C.textMuted,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : _C.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPhotoCard() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndEncodeImage,
      child: Container(
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        // FIX 4 — child was not centered; added explicit alignment
        alignment: Alignment.center,
        child: _isUploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: _C.pink,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.add_a_photo_rounded, color: _C.pink, size: 28),
      ),
    );
  }

  Widget _buildUploadedImage(String b64) {
    try {
      // FIX 5 — same safe base64 decode as _ImagePreview in home_screen:
      //          strip data URI prefix if present before decoding
      final raw = b64.contains(',') ? b64.split(',').last : b64;
      final bytes = base64Decode(raw.replaceAll(RegExp(r'\s+'), ''));
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(bytes, fit: BoxFit.cover),
      );
    } catch (_) {
      return Container(
        decoration: BoxDecoration(
          color: _C.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_rounded, color: _C.textMuted),
      );
    }
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: _C.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _C.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: _C.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryDivider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Divider(color: _C.border, height: 1),
  );

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: _C.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: BorderSide(color: _C.border),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _C.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: _C.green,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Donation Shared!',
                style: TextStyle(
                  color: _C.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Thank you for your kindness. NGOs in your area will be notified.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _C.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _GlassButton(
                label: 'Finish',
                gradient: _C.gradientPink,
                onTap: () {
                  context.pop();
                  context.go('/home');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Form Components
// ─────────────────────────────────────────────────────────────
class _StepTitle extends StatelessWidget {
  final String title, subtitle;
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
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: _C.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData? icon;
  final TextInputType keyboardType;
  final int maxLines;

  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _C.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(color: _C.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _C.textMuted, fontSize: 14),
              prefixIcon: icon != null
                  ? Icon(icon, color: _C.textMuted, size: 20)
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
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
  final bool isLoading, isOutlined;
  final LinearGradient? gradient;

  const _GlassButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.isOutlined = false,
    this.gradient,
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
          color: isOutlined ? _C.surface : (gradient == null ? _C.pink : null),
          borderRadius: BorderRadius.circular(16),
          border: isOutlined ? Border.all(color: _C.border) : null,
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
              : Text(
                  label,
                  style: TextStyle(
                    color: isOutlined ? _C.textPrimary : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            color: _C.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: _C.border)),
      ],
    );
  }
}
